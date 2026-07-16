#!/usr/bin/env python3
"""Deterministically export final and validation tables from the fresh database."""

from __future__ import annotations

import argparse
import csv
import hashlib
import sqlite3
from pathlib import Path
from typing import Iterable, Sequence


FEATURE_COLUMNS = [
    "practice_code_standardised",
    "ocs_submissions_per_1000_patient_months",
    "ocs_clinical_share",
    "ocs_administrative_share",
    "gpad_appointments_per_1000_patient_months",
    "gpad_dna_share",
    "gpad_face_to_face_share",
    "gpad_telephone_share",
    "gpad_same_day_share",
    "gpad_1_to_7_days_share",
    "gpad_8_to_14_days_share",
    "gpad_over_14_days_share",
    "ocs_mean_absolute_monthly_rate_change",
    "gpad_mean_absolute_monthly_rate_change",
]


def open_read_only(path: Path) -> sqlite3.Connection:
    connection = sqlite3.connect(path.resolve().as_uri() + "?mode=ro", uri=True)
    connection.execute("PRAGMA query_only = ON")
    return connection


def format_value(value: object) -> object:
    if value is None:
        return ""
    if isinstance(value, float):
        return format(value, ".17g")
    return value


def export_query(
    connection: sqlite3.Connection,
    query: str,
    output_path: Path,
) -> tuple[int, int]:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    cursor = connection.execute(query)
    headers = [column[0] for column in cursor.description]
    row_count = 0
    with output_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(headers)
        while True:
            rows = cursor.fetchmany(10_000)
            if not rows:
                break
            writer.writerows([[format_value(value) for value in row] for row in rows])
            row_count += len(rows)
    return row_count, len(headers)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(16 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def export_all(
    database: Path,
    output_dir: Path,
    validation_dir: Path,
    log_path: Path | None = None,
) -> list[dict[str, object]]:
    connection = open_read_only(database)
    output_dir.mkdir(parents=True, exist_ok=True)
    validation_dir.mkdir(parents=True, exist_ok=True)

    matrix_columns = ",\n    ".join(FEATURE_COLUMNS)
    exports: list[tuple[str, str, Path]] = [
        (
            "primary modelling matrix",
            f"SELECT\n    {matrix_columns}\nFROM primary_practice_access_clustering_matrix_ordered\nORDER BY practice_code_standardised",
            output_dir / "primary_practice_access_clustering_matrix_2025_04_to_2026_03.csv",
        ),
        (
            "detailed annual features",
            "SELECT * FROM eligible_annual_practice_features ORDER BY practice_code_standardised",
            output_dir / "eligible_annual_practice_features_2025_04_to_2026_03.csv",
        ),
        ("validation results", "SELECT * FROM pipeline_validation_results ORDER BY validation_order", validation_dir / "pipeline_validation_results.csv"),
        ("eligibility register", "SELECT * FROM practice_eligibility_register ORDER BY practice_code_standardised", validation_dir / "practice_eligibility_register.csv"),
        ("cohort exclusion audit", "SELECT * FROM analytical_cohort_exclusion_audit ORDER BY practice_code_standardised", validation_dir / "analytical_cohort_exclusion_audit.csv"),
        ("feature ranges", "SELECT * FROM feature_range_summary ORDER BY feature", validation_dir / "feature_range_summary.csv"),
        ("feature missingness", "SELECT * FROM feature_missingness_audit ORDER BY phase, feature", validation_dir / "feature_missingness_audit.csv"),
        ("source reconciliation", "SELECT * FROM source_reconciliation_summary ORDER BY dataset, stage", validation_dir / "source_reconciliation_summary.csv"),
        ("join cardinality", "SELECT * FROM practice_month_join_cardinality_audit", validation_dir / "join_cardinality_audit.csv"),
        ("validation fingerprint", "SELECT * FROM modelling_output_fingerprint ORDER BY practice_code_standardised", validation_dir / "modelling_output_fingerprint.csv"),
        ("output fingerprint", "SELECT * FROM modelling_output_fingerprint ORDER BY practice_code_standardised", output_dir / "modelling_output_fingerprint.csv"),
    ]

    records: list[dict[str, object]] = []
    for label, query, path in exports:
        rows, columns = export_query(connection, query, path)
        records.append(
            {
                "output": label,
                "path": str(path.resolve()),
                "rows": rows,
                "columns": columns,
                "size_bytes": path.stat().st_size,
                "sha256": sha256_file(path),
            }
        )

    checksum_path = output_dir / "output_checksums.csv"
    with checksum_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(records[0]))
        writer.writeheader()
        writer.writerows(records)
    records.append(
        {
            "output": "output checksums",
            "path": str(checksum_path.resolve()),
            "rows": len(records),
            "columns": len(records[0]),
            "size_bytes": checksum_path.stat().st_size,
            "sha256": sha256_file(checksum_path),
        }
    )

    validation_rows = connection.execute(
        "SELECT validation_order, test_name, expected_result, observed_result, result, interpretation "
        "FROM pipeline_validation_results ORDER BY validation_order"
    ).fetchall()
    validation_md = validation_dir / "pipeline_validation_results.md"
    with validation_md.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write("# Pipeline validation results\n\n")
        handle.write("| # | Test | Expected | Observed | Status | Interpretation |\n")
        handle.write("|---:|---|---|---|---|---|\n")
        for order, name, expected, observed, result, interpretation in validation_rows:
            values = [order, name, expected, observed, result, interpretation]
            escaped = [str(value).replace("|", "\\|").replace("\n", " ") for value in values]
            handle.write("| " + " | ".join(escaped) + " |\n")

    if log_path:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("w", encoding="utf-8", newline="\n") as handle:
            handle.write("Deterministic SQLite export completed.\n")
            handle.write("Numeric precision: 17 significant digits.\n")
            for record in records:
                handle.write(
                    f"{record['output']}: rows={record['rows']}, columns={record['columns']}, "
                    f"sha256={record['sha256']}, path={record['path']}\n"
                )

    connection.close()
    return records


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--validation-dir", required=True, type=Path)
    parser.add_argument("--log", type=Path)
    arguments = parser.parse_args()
    records = export_all(arguments.database, arguments.output_dir, arguments.validation_dir, arguments.log)
    for record in records:
        print(record)


if __name__ == "__main__":
    main()

