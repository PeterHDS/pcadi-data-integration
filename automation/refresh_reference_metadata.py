#!/usr/bin/env python3
"""Refresh deterministic period-labelled reference manifests from validated outputs."""

from __future__ import annotations

import csv
import hashlib
import math
import sqlite3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUTS = ROOT / "outputs"

OUTPUT_CONTRACTS = [
    ("online_consultation_led_appointment_alignment.csv", "online_consultation_led_appointment_alignment"),
    ("appointment_led_online_consultation_alignment.csv", "appointment_led_online_consultation_alignment"),
    ("multichannel_practice_month_coverage.csv", "multichannel_practice_month_coverage"),
    ("online_consultation_appointment_complete_cases.csv", "online_consultation_appointment_complete_cases"),
    ("three_source_complete_cases.csv", "three_source_complete_cases"),
    ("telephone_matched_online_consultation_appointment_comparison.csv", "telephone_matched_online_consultation_appointment_comparison"),
    ("telephone_matched_multichannel_comparison.csv", "telephone_matched_multichannel_comparison"),
    ("annual_practice_access_core.csv", "annual_practice_access_core"),
    ("annual_practice_access_with_cbt_inbound_sensitivity.csv", "annual_practice_access_with_cbt_inbound_sensitivity"),
    ("annual_practice_access_with_cbt_outcomes_sensitivity.csv", "annual_practice_access_with_cbt_outcomes_sensitivity"),
    ("practice_temporal_access_sensitivity_features.csv", "practice_temporal_access_sensitivity_features"),
    ("primary_practice_access_clustering_matrix.csv", "primary_practice_access_clustering_matrix"),
    ("cbt_inbound_sensitivity_clustering_matrix_17_features.csv", "cbt_inbound_sensitivity_clustering_matrix"),
    ("cbt_outcomes_sensitivity_clustering_matrix_21_features.csv", "cbt_outcomes_sensitivity_clustering_matrix"),
]

PRIMARY_COLUMNS = [
    "practice_code_standardised",
    "ocs_submissions_per_1000_patient_months",
    "ocs_clinical_share",
    "ocs_administrative_share",
    "gpad_appointments_per_1000_patient_months",
    "gpad_dna_share",
    "gpad_face_to_face_share",
    "gpad_telephone_share",
    "gpad_same_day_share",
    "gpad_1_day_share",
    "gpad_2_to_7_days_share",
    "gpad_8_to_14_days_share",
    "gpad_over_14_days_share",
    "ocs_mean_absolute_monthly_rate_change",
    "gpad_mean_absolute_monthly_rate_change",
]
INBOUND_COLUMNS = PRIMARY_COLUMNS + [
    "cbt_inbound_calls_per_1000_patient_months",
    "cbt_mean_absolute_monthly_call_rate_change",
    "cbt_call_rate_range",
]
OUTCOME_COLUMNS = INBOUND_COLUMNS + [
    "cbt_answered_share_cbt003",
    "cbt_missed_share",
    "cbt_ivr_share",
    "cbt_callback_request_share",
]

MATRIX_CONTRACTS = [
    (
        "primary_practice_access_clustering_matrix.csv",
        "PRIMARY",
        6067,
        PRIMARY_COLUMNS,
        "C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF",
    ),
    (
        "cbt_inbound_sensitivity_clustering_matrix_17_features.csv",
        "CBT_INBOUND_RESTRICTED",
        3020,
        INBOUND_COLUMNS,
        "CCC179B870BBD3EC46DD1B75868DB38156FE23A44BBC5A8FF698505FC9B63ED5",
    ),
    (
        "cbt_outcomes_sensitivity_clustering_matrix_21_features.csv",
        "CBT_OUTCOME_COMPLETE_RESTRICTED",
        1456,
        OUTCOME_COLUMNS,
        "D3D2E70C1A718260DD332B59F835EB6316826677A1DF5CEB928ED563C0FC1021",
    ),
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def inspect_csv(path: Path) -> tuple[list[str], int]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.reader(handle)
        header = next(reader)
        rows = sum(1 for _ in reader)
    return header, rows


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def validate_matrix(
    filename: str,
    role: str,
    expected_rows: int,
    expected_columns: list[str],
    expected_hash: str,
) -> tuple[dict[str, object], dict[str, dict[str, str]]]:
    path = OUTPUTS / filename
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != expected_columns:
            raise ValueError(f"{filename}: unexpected header")
        records: dict[str, dict[str, str]] = {}
        missing = non_numeric = non_finite = 0
        for row in reader:
            identifier = row["practice_code_standardised"]
            if not identifier or identifier in records:
                raise ValueError(f"{filename}: blank or duplicate identifier {identifier!r}")
            records[identifier] = row
            for name in expected_columns[1:]:
                value = row[name]
                if value == "":
                    missing += 1
                    continue
                try:
                    number = float(value)
                except ValueError:
                    non_numeric += 1
                    continue
                if not math.isfinite(number):
                    non_finite += 1
                if ("share" in name and not 0 <= number <= 1) or (
                    ("rate" in name or "per_1000" in name) and number < 0
                ):
                    raise ValueError(f"{filename}: invalid value for {name}")
    observed_hash = sha256(path)
    status = (
        "PASS"
        if len(records) == expected_rows
        and observed_hash == expected_hash
        and missing == non_numeric == non_finite == 0
        else "FAIL"
    )
    result = {
        "file": filename,
        "role": role,
        "expected_rows": expected_rows,
        "observed_rows": len(records),
        "distinct_identifiers": len(records),
        "duplicate_identifiers": 0,
        "expected_features": len(expected_columns) - 1,
        "observed_features": len(expected_columns) - 1,
        "missing_values": missing,
        "non_numeric_values": non_numeric,
        "non_finite_values": non_finite,
        "status": status,
    }
    if status != "PASS":
        raise ValueError(f"{filename}: matrix contract or checksum failed")
    return result, records


def assert_inheritance(
    parent: dict[str, dict[str, str]],
    child: dict[str, dict[str, str]],
) -> None:
    shared = [name for name in next(iter(child.values())) if name in next(iter(parent.values()))]
    for identifier, row in child.items():
        if identifier not in parent:
            raise ValueError(f"Child identifier {identifier} is absent from parent")
        for name in shared:
            if row[name] != parent[identifier][name]:
                raise ValueError(f"Inheritance mismatch for {identifier}, {name}")


def main() -> None:
    output_rows = []
    for filename, table in OUTPUT_CONTRACTS:
        path = OUTPUTS / filename
        if not path.is_file():
            raise FileNotFoundError(path)
        header, rows = inspect_csv(path)
        output_rows.append(
            {
                "filename": filename,
                "table": table,
                "rows": rows,
                "columns": len(header),
                "bytes": path.stat().st_size,
                "sha256": sha256(path),
            }
        )

    fields = ["filename", "table", "rows", "columns", "bytes", "sha256"]
    write_csv(ROOT / "validation" / "output_register_and_checksums.csv", fields, output_rows)
    write_csv(
        ROOT / "reference-release" / "validation" / "reference_output_manifest.csv",
        fields,
        output_rows,
    )
    write_csv(
        ROOT / "validation" / "authoritative_output_manifest.csv",
        fields,
        output_rows,
    )

    matrix_rows = []
    matrices = []
    for contract in MATRIX_CONTRACTS:
        result, records = validate_matrix(*contract)
        matrix_rows.append(result)
        matrices.append(records)
    assert_inheritance(matrices[0], matrices[1])
    assert_inheritance(matrices[1], matrices[2])
    write_csv(
        ROOT / "validation" / "matrix_numeric_validation.csv",
        list(matrix_rows[0]),
        matrix_rows,
    )

    formatter = sqlite3.connect(":memory:")
    fingerprint_rows = []
    for identifier in sorted(matrices[0]):
        row = matrices[0][identifier]
        formatted = [
            formatter.execute("SELECT printf('%.17g', CAST(? AS REAL))", (row[name],)).fetchone()[0]
            for name in PRIMARY_COLUMNS[1:]
        ]
        fingerprint_rows.append(
            {
                "practice_code_standardised": identifier,
                "canonical_line": identifier + "|" + "|".join(formatted),
            }
        )
    formatter.close()
    write_csv(
        ROOT / "reference-release" / "validation" / "expected_modelling_output_fingerprint.csv",
        ["practice_code_standardised", "canonical_line"],
        fingerprint_rows,
    )

    print(f"Refreshed {len(output_rows)} output records and {len(matrix_rows)} matrix gates.")


if __name__ == "__main__":
    main()
