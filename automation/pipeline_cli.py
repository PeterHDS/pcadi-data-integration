#!/usr/bin/env python3
"""Run, audit and demonstrate the portable NHS access-data SQL pipeline."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import re
import shutil
import sqlite3
import subprocess
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MONTH_RE = re.compile(r"^\d{4}-(0[1-9]|1[0-2])$")
SQL_FILES = [
    ROOT / "sql" / "portable" / "01_create_canonical_source_tables.sql",
    ROOT / "sql" / "portable" / "02_build_practice_month_designs.sql",
    ROOT / "sql" / "portable" / "03_build_annual_practice_profiles.sql",
    ROOT / "sql" / "portable" / "04_build_telephony_sensitivity_profiles.sql",
    ROOT / "sql" / "portable" / "05_validate_pipeline.sql",
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def month_range(start: str, end: str) -> list[str]:
    if not MONTH_RE.fullmatch(start) or not MONTH_RE.fullmatch(end):
        raise ValueError("Months must use YYYY-MM")
    sy, sm = map(int, start.split("-"))
    ey, em = map(int, end.split("-"))
    first, last = sy * 12 + sm - 1, ey * 12 + em - 1
    if last < first:
        raise ValueError("analysis_end_month precedes analysis_start_month")
    return [f"{i // 12:04d}-{i % 12 + 1:02d}" for i in range(first, last + 1)]


def positive_integer(value: str) -> int:
    number = int(value)
    if number < 1:
        raise argparse.ArgumentTypeError("value must be a positive integer")
    return number


def add_months(start: str, count: int) -> str:
    if not MONTH_RE.fullmatch(start):
        raise ValueError("Months must use YYYY-MM")
    year, month = map(int, start.split("-"))
    index = year * 12 + month - 1 + count - 1
    return f"{index // 12:04d}-{index % 12 + 1:02d}"


def load_config(path: Path) -> tuple[dict[str, object], list[str]]:
    config = json.loads(path.read_text(encoding="utf-8"))
    months = month_range(str(config["analysis_start_month"]), str(config["analysis_end_month"]))
    if int(config["expected_months"]) != len(months):
        raise ValueError(f"expected_months={config['expected_months']} but date bounds contain {len(months)} months")
    if bool(config.get("annual_features")) and len(months) != 12:
        raise ValueError("annual_features requires exactly twelve configured months")
    return config, months


def write_period_config(
    destination: Path,
    start: str,
    end: str | None,
    months_count: int | None,
    annual_features: bool,
    description: str | None,
) -> dict[str, object]:
    if end is None:
        assert months_count is not None
        end = add_months(start, months_count)
    months = month_range(start, end)
    if annual_features and len(months) != 12:
        raise ValueError("--annual-features can be used only with exactly twelve months")
    config: dict[str, object] = {
        "analysis_start_month": start,
        "analysis_end_month": end,
        "expected_months": len(months),
        "required_sources": ["OCS", "GPAD", "CBT"],
        "annual_features": annual_features,
        "description": description or f"Practice-month integration for {start} to {end}",
    }
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    return config


def load_contracts() -> list[dict[str, object]]:
    contracts = []
    for path in sorted((ROOT / "contracts" / "sources").glob("*.json")):
        contract = json.loads(path.read_text(encoding="utf-8"))
        contract["_path"] = str(path)
        contracts.append(contract)
    return contracts


def convert(value: str, rule: dict[str, object], filename: str, row_number: int, column: str) -> object:
    if value == "":
        if rule["nullable"]:
            return None
        raise ValueError(f"{filename} row {row_number}: {column} is required")
    kind = rule["type"]
    if kind == "text":
        return value.strip()
    if kind == "month":
        if not MONTH_RE.fullmatch(value):
            raise ValueError(f"{filename} row {row_number}: invalid month {value!r}")
        return value
    if kind == "integer":
        number = int(value)
        return number
    if kind == "number":
        number = float(value)
        if not math.isfinite(number):
            raise ValueError(f"{filename} row {row_number}: non-finite {column}")
        return number
    raise ValueError(f"Unsupported contract type: {kind}")


def validate_and_read(path: Path, contract: dict[str, object]) -> tuple[list[str], list[tuple[object, ...]]]:
    columns = list(contract["columns"])
    rules = contract["columns"]
    rows: list[tuple[object, ...]] = []
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != columns:
            raise ValueError(f"{path.name}: header mismatch\nexpected={columns}\nobserved={reader.fieldnames}")
        for number, row in enumerate(reader, start=2):
            rows.append(tuple(convert(row[column], rules[column], path.name, number, column) for column in columns))
    return columns, rows


def validate_provenance(rows: list[tuple[object, ...]], columns: list[str], config: dict[str, object], months: list[str]) -> None:
    records = [dict(zip(columns, row)) for row in rows]
    required = {str(item).upper() for item in config["required_sources"]}
    ownership: dict[tuple[str, str, str], int] = {}
    for row in records:
        dataset = str(row["dataset"]).upper()
        month = str(row["observation_month"])
        if dataset in required and month in months:
            key = (dataset, str(row["component"]), month)
            ownership.setdefault(key, 0)
            if row["selected"] == 1:
                ownership[key] += 1
    conflicts = [key for key, count in ownership.items() if count != 1]
    if conflicts:
        examples = ", ".join("/".join(key) for key in conflicts[:5])
        raise ValueError(f"Source ownership gate failed for {len(conflicts)} component-month group(s): {examples}")
    for dataset in required:
        for month in months:
            selected = [
                row for row in records
                if str(row["dataset"]).upper() == dataset
                and row["observation_month"] == month
                and row["selected"] == 1
            ]
            if not selected:
                raise ValueError(f"Source ownership gate failed for {dataset} {month}: no selected component")
    outside = [row for row in records if row["selected"] == 1 and row["observation_month"] not in months]
    if outside:
        raise ValueError(f"Selected provenance contains {len(outside)} month(s) outside the configured window")


def insert_rows(connection: sqlite3.Connection, table: str, columns: list[str], rows: list[tuple[object, ...]]) -> None:
    placeholders = ",".join("?" for _ in columns)
    quoted = ",".join(f'"{column}"' for column in columns)
    connection.executemany(f'INSERT INTO "{table}" ({quoted}) VALUES ({placeholders})', rows)


def export_table(connection: sqlite3.Connection, table: str, path: Path, order_by: str) -> tuple[int, int]:
    cursor = connection.execute(f'SELECT * FROM "{table}" ORDER BY {order_by}')
    columns = [item[0] for item in cursor.description]
    path.parent.mkdir(parents=True, exist_ok=True)
    rows = 0
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(columns)
        for batch in iter(lambda: cursor.fetchmany(10000), []):
            writer.writerows(batch)
            rows += len(batch)
    return rows, len(columns)


def run_pipeline(config_path: Path, input_dir: Path, output_dir: Path, database: Path, overwrite: bool) -> dict[str, object]:
    config, months = load_config(config_path)
    contracts = load_contracts()
    if database.exists():
        if not overwrite:
            raise FileExistsError(f"Refusing to replace {database}; use --overwrite")
        database.unlink()
    output_dir.mkdir(parents=True, exist_ok=True)
    database.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(database)
    connection.executescript(SQL_FILES[0].read_text(encoding="utf-8"))
    for key, value in config.items():
        stored = json.dumps(value) if isinstance(value, (list, dict, bool)) else str(value)
        connection.execute("INSERT INTO pipeline_config VALUES (?, ?)", (key, stored))

    mapping = {
        "online_consultation_practice_month.csv": "online_consultation_source",
        "appointment_activity_practice_month.csv": "appointment_activity_source",
        "cloud_telephony_practice_month.csv": "cloud_telephony_source",
        "source_provenance.csv": "source_provenance",
    }
    provenance_rows = None
    provenance_columns = None
    input_evidence = []
    for contract in contracts:
        source = input_dir / str(contract["filename"])
        if not source.is_file():
            raise FileNotFoundError(source)
        columns, rows = validate_and_read(source, contract)
        insert_rows(connection, mapping[source.name], columns, rows)
        input_evidence.append({"filename": source.name, "rows": len(rows), "bytes": source.stat().st_size, "sha256": sha256(source)})
        if source.name == "source_provenance.csv":
            provenance_rows, provenance_columns = rows, columns
    assert provenance_rows is not None and provenance_columns is not None
    validate_provenance(provenance_rows, provenance_columns, config, months)
    connection.commit()
    for sql_path in SQL_FILES[1:]:
        connection.executescript(sql_path.read_text(encoding="utf-8"))
        connection.commit()

    validations = [dict(zip([item[0] for item in connection.execute("SELECT * FROM pipeline_validation_results").description], row)) for row in connection.execute("SELECT * FROM pipeline_validation_results ORDER BY test_name")]
    failures = [row for row in validations if row["status"] != "PASS"]
    exports = [
        ("multichannel_practice_month_coverage", "multichannel_practice_month_coverage.csv", "practice_code_standardised, reporting_month"),
        ("online_consultation_cohort_with_appointment_context", "online_consultation_cohort_with_appointment_context.csv", "practice_code_standardised, reporting_month"),
        ("appointment_cohort_with_online_consultation_context", "appointment_cohort_with_online_consultation_context.csv", "practice_code_standardised, reporting_month"),
        ("matched_online_and_scheduled_activity", "matched_online_and_scheduled_activity.csv", "practice_code_standardised, reporting_month"),
        ("matched_multichannel_activity", "matched_multichannel_activity.csv", "practice_code_standardised, reporting_month"),
        ("telephony_observed_comparative_cohort", "telephony_observed_comparative_cohort.csv", "practice_code_standardised, reporting_month"),
        ("annual_practice_access_profiles", "annual_practice_access_profiles.csv", "practice_code_standardised"),
        ("annual_practice_access_modelling_matrix", "annual_practice_access_modelling_matrix.csv", "practice_code_standardised"),
        ("annual_profiles_with_inbound_telephony_sensitivity", "annual_profiles_with_inbound_telephony_sensitivity.csv", "practice_code_standardised"),
        ("inbound_telephony_sensitivity_modelling_matrix", "inbound_telephony_sensitivity_modelling_matrix.csv", "practice_code_standardised"),
        ("annual_profiles_with_telephony_outcome_sensitivity", "annual_profiles_with_telephony_outcome_sensitivity.csv", "practice_code_standardised"),
        ("telephony_outcome_sensitivity_modelling_matrix", "telephony_outcome_sensitivity_modelling_matrix.csv", "practice_code_standardised"),
    ]
    output_evidence = []
    for table, filename, ordering in exports:
        path = output_dir / filename
        rows, columns = export_table(connection, table, path, ordering)
        output_evidence.append({"filename": filename, "rows": rows, "columns": columns, "bytes": path.stat().st_size, "sha256": sha256(path)})
    validation_path = output_dir / "pipeline_validation_results.csv"
    export_table(connection, "pipeline_validation_results", validation_path, "test_name")
    integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
    connection.close()
    report = {
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "config": config,
        "months": months,
        "database_integrity": integrity,
        "validation_passes": len(validations) - len(failures),
        "validation_failures": len(failures),
        "inputs": input_evidence,
        "outputs": output_evidence,
        "clustering_run": False,
    }
    (output_dir / "run_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    if integrity != "ok" or failures:
        raise RuntimeError(f"Pipeline validation failed: integrity={integrity}, failed gates={len(failures)}")
    return report


def write_checklist(config_path: Path, destination: Path) -> None:
    config, months = load_config(config_path)
    with (ROOT / "pipeline" / "source_registry" / "official_sources.csv").open("r", encoding="utf-8", newline="") as handle:
        registry = {row["dataset"]: row for row in csv.DictReader(handle)}
    components = {
        "OCS": [("practice-level CSV/ZIP", "required"), ("metadata and supporting information", "required"), ("day-and-time CSV/ZIP", "optional-temporal")],
        "GPAD": [("practice-level crosstab CSV", "required"), ("mapping/metadata", "required"), ("category, role and duration files", "optional-question-dependent")],
        "CBT": [("day-and-time ZIP", "required-for-practice-activity"), ("participation/mapping workbook", "required"), ("duration ZIP", "optional-outcomes"), ("metadata and supporting information", "required")],
    }
    rows = []
    for month in months:
        for dataset in config["required_sources"]:
            item = registry[str(dataset)]
            for component, requirement in components[str(dataset)]:
                rows.append({
                    "observation_month": month,
                    "dataset": dataset,
                    "component_to_obtain": component,
                    "requirement": requirement,
                    "official_series_page": item["series_page_url"],
                    "supporting_information": item["supporting_information_url"],
                    "selection_instruction": item["important_note"],
                    "publication_release_month": "TO_BE_CONFIRMED",
                    "publication_page_url": item["series_page_url"],
                    "direct_download_url": "TO_BE_CONFIRMED_FROM_PUBLICATION_PAGE",
                    "local_relative_path": "TO_BE_CONFIRMED",
                    "expected_bytes": "",
                    "expected_sha256": "",
                    "expected_archive_members": "",
                    "expected_header": "",
                    "selected": "",
                    "local_status": "TO_BE_CONFIRMED",
                })
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def validate_downloads(config_path: Path, manifest_path: Path, download_dir: Path, destination: Path, allow_synthetic: bool) -> dict[str, object]:
    config, months = load_config(config_path)
    required_columns = [
        "dataset", "component", "observation_month", "publication_release_month",
        "publication_page_url", "direct_download_url", "local_relative_path",
        "expected_bytes", "expected_sha256", "expected_archive_members",
        "expected_header", "required", "selected", "notes",
    ]
    with manifest_path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != required_columns:
            raise ValueError(f"Download manifest header mismatch: expected {required_columns}, observed {reader.fieldnames}")
        rows = list(reader)
    required_sources = {str(item).upper() for item in config["required_sources"]}
    ownership: dict[tuple[str, str, str], int] = {}
    audit = []
    for row in rows:
        dataset = row["dataset"].upper()
        month = row["observation_month"]
        selected = row["selected"] == "1"
        required = row["required"] == "1"
        if selected:
            ownership[(dataset, row["component"], month)] = ownership.get((dataset, row["component"], month), 0) + 1
        status = "PASS"
        findings = []
        if month not in months:
            status, findings = "FAIL", ["observation month outside configured period"]
        publication_url = row["publication_page_url"]
        direct_url = row["direct_download_url"]
        official = publication_url.startswith("https://digital.nhs.uk/") and direct_url.startswith(("https://digital.nhs.uk/", "https://files.digital.nhs.uk/"))
        if not official and not (allow_synthetic and publication_url == "SYNTHETIC_FIXTURE" and direct_url == "SYNTHETIC_FIXTURE"):
            status = "FAIL"
            findings.append("URL is not an accepted official NHS England domain")
        relative = Path(row["local_relative_path"])
        local = (download_dir / relative).resolve()
        if download_dir.resolve() not in local.parents and local != download_dir.resolve():
            status = "FAIL"
            findings.append("local path escapes download directory")
        elif selected or required:
            if not local.is_file():
                status = "FAIL"
                findings.append("required local file is missing")
            else:
                observed_bytes = local.stat().st_size
                observed_hash = sha256(local)
                if row["expected_bytes"] and observed_bytes != int(row["expected_bytes"]):
                    status = "FAIL"
                    findings.append("file size mismatch")
                if row["expected_sha256"] and observed_hash != row["expected_sha256"].upper():
                    status = "FAIL"
                    findings.append("SHA-256 mismatch")
                if local.suffix.lower() == ".zip":
                    try:
                        with zipfile.ZipFile(local) as archive:
                            bad = archive.testzip()
                            members = set(archive.namelist())
                        if bad:
                            status = "FAIL"
                            findings.append(f"corrupted ZIP member: {bad}")
                        expected_members = {item for item in row["expected_archive_members"].split("|") if item}
                        missing_members = expected_members - members
                        if missing_members:
                            status = "FAIL"
                            findings.append("missing archive members: " + ";".join(sorted(missing_members)))
                    except zipfile.BadZipFile:
                        status = "FAIL"
                        findings.append("invalid ZIP archive")
                elif local.suffix.lower() == ".csv" and row["expected_header"]:
                    with local.open("r", encoding="utf-8-sig", newline="") as source:
                        header = next(csv.reader(source))
                    expected_header = row["expected_header"].split("|")
                    if header != expected_header:
                        status = "FAIL"
                        findings.append("CSV header mismatch")
        audit.append({
            "dataset": dataset,
            "component": row["component"],
            "observation_month": month,
            "publication_release_month": row["publication_release_month"],
            "local_relative_path": row["local_relative_path"],
            "required": int(required),
            "selected": int(selected),
            "status": status,
            "findings": "; ".join(findings) if findings else "file identity and integrity confirmed",
        })
    for key, count in ownership.items():
        if count != 1:
            audit.append({"dataset": key[0], "component": key[1], "observation_month": key[2], "publication_release_month": "", "local_relative_path": "", "required": 1, "selected": count, "status": "FAIL", "findings": f"selected source owners={count}; expected exactly one"})
    for dataset in required_sources:
        for month in months:
            if not any(row["dataset"] == dataset and row["observation_month"] == month and row["required"] == 1 and row["selected"] == 1 for row in audit):
                audit.append({"dataset": dataset, "component": "ALL_REQUIRED", "observation_month": month, "publication_release_month": "", "local_relative_path": "", "required": 1, "selected": 0, "status": "FAIL", "findings": "no selected required component for dataset-month"})
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(audit[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(audit)
    failures = sum(row["status"] == "FAIL" for row in audit)
    return {"manifest_rows": len(rows), "audit_rows": len(audit), "failures": failures, "status": "PASS" if failures == 0 else "FAIL"}


def validate_reference(destination: Path) -> dict[str, object]:
    manifest_path = ROOT / "validation" / "output_register_and_checksums.csv"
    with manifest_path.open("r", encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle))
    checks = []
    for row in rows:
        path = ROOT / "outputs" / row["filename"]
        observed = sha256(path) if path.is_file() else "MISSING"
        checks.append({"filename": row["filename"], "expected_sha256": row["sha256"], "observed_sha256": observed, "status": "PASS" if observed == row["sha256"] else "FAIL"})
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(checks[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(checks)
    failures = sum(row["status"] == "FAIL" for row in checks)
    return {"files_checked": len(checks), "failures": failures, "status": "PASS" if failures == 0 else "FAIL"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    run = sub.add_parser("run")
    run.add_argument("--config", required=True, type=Path)
    run.add_argument("--input-dir", required=True, type=Path)
    run.add_argument("--output-dir", required=True, type=Path)
    run.add_argument("--database", required=True, type=Path)
    run.add_argument("--overwrite", action="store_true")
    demo = sub.add_parser("demo")
    demo.add_argument("--months", default=3, type=positive_integer)
    demo.add_argument("--start-month", help="Optional first synthetic month in YYYY-MM format")
    config = sub.add_parser("make-config", help="Create a validated configuration for any contiguous month range")
    config.add_argument("--start", required=True, help="First observation month in YYYY-MM format")
    period = config.add_mutually_exclusive_group(required=True)
    period.add_argument("--end", help="Last observation month in YYYY-MM format, inclusive")
    period.add_argument("--months", type=positive_integer, help="Number of consecutive observation months")
    config.add_argument("--annual-features", action="store_true", help="Also build annual profiles; requires exactly 12 months")
    config.add_argument("--description")
    config.add_argument("--output", required=True, type=Path)
    checklist = sub.add_parser("data-checklist")
    checklist.add_argument("--config", required=True, type=Path)
    checklist.add_argument("--output", required=True, type=Path)
    downloads = sub.add_parser("validate-downloads")
    downloads.add_argument("--config", required=True, type=Path)
    downloads.add_argument("--manifest", required=True, type=Path)
    downloads.add_argument("--download-dir", required=True, type=Path)
    downloads.add_argument("--output", required=True, type=Path)
    downloads.add_argument("--allow-synthetic", action="store_true")
    reference = sub.add_parser("validate-reference")
    reference.add_argument("--output", default=ROOT / "work" / "reference_validation.csv", type=Path)
    args = parser.parse_args()
    if args.command == "run":
        print(json.dumps(run_pipeline(args.config.resolve(), args.input_dir.resolve(), args.output_dir.resolve(), args.database.resolve(), args.overwrite), indent=2))
    elif args.command == "demo":
        demo_root = ROOT / "work" / f"demo_{args.months}_months"
        if demo_root.exists():
            shutil.rmtree(demo_root)
        input_dir = demo_root / "inputs"
        generator = ROOT / "automation" / "create_synthetic_data.py"
        command = [sys.executable, str(generator), "--output", str(input_dir), "--months", str(args.months)]
        if args.start_month:
            command.extend(["--start-month", args.start_month])
        subprocess.run(command, check=True)
        report = run_pipeline(input_dir / "synthetic_config.json", input_dir, demo_root / "outputs", demo_root / "pipeline.sqlite", True)
        print(json.dumps(report, indent=2))
    elif args.command == "make-config":
        result = write_period_config(
            args.output.resolve(), args.start, args.end, args.months,
            args.annual_features, args.description,
        )
        print(json.dumps(result, indent=2))
    elif args.command == "data-checklist":
        write_checklist(args.config.resolve(), args.output.resolve())
        print(args.output.resolve())
    elif args.command == "validate-downloads":
        result = validate_downloads(args.config.resolve(), args.manifest.resolve(), args.download_dir.resolve(), args.output.resolve(), args.allow_synthetic)
        print(json.dumps(result, indent=2))
        return 0 if result["failures"] == 0 else 1
    else:
        result = validate_reference(args.output.resolve())
        print(json.dumps(result, indent=2))
        return 0 if result["failures"] == 0 else 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
