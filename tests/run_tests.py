#!/usr/bin/env python3
"""Deterministic repository tests using no NHS source data."""

from __future__ import annotations

import csv
import hashlib
import json
import math
import re
import shutil
import sqlite3
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PYTHON = sys.executable


def run(*arguments: str) -> None:
    subprocess.run([PYTHON, str(ROOT / "automation" / "pipeline_cli.py"), *arguments], cwd=ROOT, check=True)


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def assert_matrix(path: Path, expected_rows: int, expected_features: int) -> None:
    rows = read_rows(path)
    assert len(rows) == expected_rows, (path, len(rows))
    assert len(rows[0]) - 1 == expected_features
    identifiers = [row["practice_code_standardised"] for row in rows]
    assert len(set(identifiers)) == len(identifiers)
    for row in rows:
        for name, value in row.items():
            if name == "practice_code_standardised":
                continue
            assert value != ""
            assert math.isfinite(float(value))


def main() -> None:
    test_root = ROOT / "work" / "pre_git_tests"
    if test_root.exists():
        shutil.rmtree(test_root)
    test_root.mkdir(parents=True)

    one_config = test_root / "one_month.json"
    run("make-config", "--start", "2026-03", "--months", "1", "--output", str(one_config))
    one_config_data = json.loads(one_config.read_text(encoding="utf-8"))
    assert one_config_data["analysis_end_month"] == "2026-03"
    assert one_config_data["expected_months"] == 1

    twenty_four_config = test_root / "twenty_four_months.json"
    run("make-config", "--start", "2024-01", "--end", "2025-12", "--output", str(twenty_four_config))
    twenty_four_config_data = json.loads(twenty_four_config.read_text(encoding="utf-8"))
    assert twenty_four_config_data["expected_months"] == 24

    run("demo", "--months", "1")
    one = json.loads((ROOT / "work" / "demo_1_months" / "outputs" / "run_report.json").read_text(encoding="utf-8"))
    assert one["validation_failures"] == 0
    assert one["months"] == ["2026-03"]
    assert next(item for item in one["outputs"] if item["filename"] == "annual_practice_access_modelling_matrix.csv")["rows"] == 0

    run("demo", "--months", "3")
    three = json.loads((ROOT / "work" / "demo_3_months" / "outputs" / "run_report.json").read_text(encoding="utf-8"))
    assert three["validation_failures"] == 0
    output_rows = {item["filename"]: item["rows"] for item in three["outputs"]}
    assert output_rows["multichannel_practice_month_coverage.csv"] == 15
    assert output_rows["matched_online_and_scheduled_activity.csv"] == 6
    assert output_rows["matched_multichannel_activity.csv"] == 3
    assert output_rows["annual_practice_access_modelling_matrix.csv"] == 0

    multi_component_inputs = test_root / "multi_component_inputs"
    shutil.copytree(ROOT / "work" / "demo_3_months" / "inputs", multi_component_inputs)
    provenance_path = multi_component_inputs / "source_provenance.csv"
    provenance_rows = read_rows(provenance_path)
    for month in ("2026-03", "2026-04", "2026-05"):
        example = next(
            row for row in provenance_rows
            if row["dataset"] == "OCS" and row["observation_month"] == month
        )
        additional = dict(example)
        additional["component"] = "metadata_evidence"
        additional["notes"] = "Second independently owned component for ownership test"
        provenance_rows.append(additional)
    with provenance_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(provenance_rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(provenance_rows)
    multi_component_output = test_root / "multi_component_output"
    run(
        "run", "--config", str(multi_component_inputs / "synthetic_config.json"),
        "--input-dir", str(multi_component_inputs),
        "--output-dir", str(multi_component_output / "outputs"),
        "--database", str(multi_component_output / "pipeline.sqlite"),
        "--overwrite",
    )
    multi_component_report = json.loads(
        (multi_component_output / "outputs" / "run_report.json").read_text(encoding="utf-8")
    )
    assert multi_component_report["validation_failures"] == 0

    run("demo", "--months", "24", "--start-month", "2024-01")
    twenty_four = json.loads((ROOT / "work" / "demo_24_months" / "outputs" / "run_report.json").read_text(encoding="utf-8"))
    assert twenty_four["validation_failures"] == 0
    assert len(twenty_four["months"]) == 24
    assert twenty_four["months"][0] == "2024-01" and twenty_four["months"][-1] == "2025-12"
    assert next(item for item in twenty_four["outputs"] if item["filename"] == "annual_practice_access_modelling_matrix.csv")["rows"] == 0

    run("demo", "--months", "12")
    twelve_dir = ROOT / "work" / "demo_12_months"
    twelve = json.loads((twelve_dir / "outputs" / "run_report.json").read_text(encoding="utf-8"))
    assert twelve["validation_failures"] == 0
    assert_matrix(twelve_dir / "outputs" / "annual_practice_access_modelling_matrix.csv", 3, 13)
    assert_matrix(twelve_dir / "outputs" / "inbound_telephony_sensitivity_modelling_matrix.csv", 2, 16)
    assert_matrix(twelve_dir / "outputs" / "telephony_outcome_sensitivity_modelling_matrix.csv", 2, 20)

    twelve_practice_month_only_config = test_root / "twelve_practice_month_only.json"
    run(
        "make-config", "--start", "2025-04", "--months", "12",
        "--output", str(twelve_practice_month_only_config),
    )
    twelve_practice_month_only_dir = test_root / "twelve_practice_month_only"
    run(
        "run", "--config", str(twelve_practice_month_only_config),
        "--input-dir", str(twelve_dir / "inputs"),
        "--output-dir", str(twelve_practice_month_only_dir / "outputs"),
        "--database", str(twelve_practice_month_only_dir / "pipeline.sqlite"),
        "--overwrite",
    )
    twelve_practice_month_only = json.loads(
        (twelve_practice_month_only_dir / "outputs" / "run_report.json").read_text(encoding="utf-8")
    )
    assert twelve_practice_month_only["validation_failures"] == 0
    assert next(
        item for item in twelve_practice_month_only["outputs"]
        if item["filename"] == "annual_practice_access_modelling_matrix.csv"
    )["rows"] == 0

    connection = sqlite3.connect(twelve_dir / "pipeline.sqlite")
    row = connection.execute(
        "SELECT gpad_1_to_7_days_share, gpad_over_14_days_share "
        "FROM annual_practice_access_modelling_matrix WHERE practice_code_standardised = 'A00001'"
    ).fetchone()
    totals = connection.execute(
        "SELECT SUM(total_appointments), SUM(one_day + two_to_seven_days), "
        "SUM(fifteen_to_twenty_one_days + twenty_two_to_twenty_eight_days + more_than_twenty_eight_days) "
        "FROM appointment_activity_source WHERE practice_code_standardised = 'A00001'"
    ).fetchone()
    connection.close()
    assert abs(row[0] - totals[1] / totals[0]) < 1e-12
    assert abs(row[1] - totals[2] / totals[0]) < 1e-12

    reference_path = test_root / "reference_checks.csv"
    run("validate-reference", "--output", str(reference_path))
    reference = read_rows(reference_path)
    assert len(reference) == 14
    assert all(row["status"] == "PASS" for row in reference)

    checklist = test_root / "march_may_checklist.csv"
    run("data-checklist", "--config", str(ROOT / "configs" / "example_three_month_period.json"), "--output", str(checklist))
    checklist_rows = read_rows(checklist)
    assert {row["observation_month"] for row in checklist_rows} == {"2026-03", "2026-04", "2026-05"}
    assert {row["dataset"] for row in checklist_rows} == {"OCS", "GPAD", "CBT"}

    synthetic_inputs = ROOT / "work" / "demo_3_months" / "inputs"
    download_fields = ["dataset", "component", "observation_month", "publication_release_month", "publication_page_url", "direct_download_url", "local_relative_path", "expected_bytes", "expected_sha256", "expected_archive_members", "expected_header", "required", "selected", "notes"]
    download_rows = []
    files = {"OCS": "online_consultation_practice_month.csv", "GPAD": "appointment_activity_practice_month.csv", "CBT": "cloud_telephony_practice_month.csv"}
    for dataset, filename in files.items():
        source = synthetic_inputs / filename
        digest = hashlib.sha256(source.read_bytes()).hexdigest().upper()
        header = source.read_text(encoding="utf-8").splitlines()[0].replace(",", "|")
        for month in ("2026-03", "2026-04", "2026-05"):
            download_rows.append({"dataset": dataset, "component": "synthetic_component", "observation_month": month, "publication_release_month": month, "publication_page_url": "SYNTHETIC_FIXTURE", "direct_download_url": "SYNTHETIC_FIXTURE", "local_relative_path": filename, "expected_bytes": source.stat().st_size, "expected_sha256": digest, "expected_archive_members": "", "expected_header": header, "required": 1, "selected": 1, "notes": "test only"})
    download_manifest = test_root / "synthetic_download_manifest.csv"
    with download_manifest.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=download_fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(download_rows)
    download_audit = test_root / "synthetic_download_audit.csv"
    run("validate-downloads", "--config", str(synthetic_inputs / "synthetic_config.json"), "--manifest", str(download_manifest), "--download-dir", str(synthetic_inputs), "--output", str(download_audit), "--allow-synthetic")
    assert all(row["status"] == "PASS" for row in read_rows(download_audit))

    public_text_paths = [
        path for path in ROOT.rglob("*.md")
        if "work" not in path.relative_to(ROOT).parts
    ]
    public_text_paths += list((ROOT / "sql" / "portable").glob("*.sql"))
    public_text_paths.append(ROOT / "CITATION.cff")
    unexplained_design_terms = re.compile(r"\bscenario[_ -]?\d|fatal flaw", re.IGNORECASE)
    local_path = re.compile(r"C:\\Users\\HP", re.IGNORECASE)
    for path in public_text_paths:
        text = path.read_text(encoding="utf-8")
        assert unexplained_design_terms.search(text) is None, f"Unexplained development-only terminology in {path}"
        assert local_path.search(text) is None, f"Local user path in {path}"
        assert "\u2014" not in text, f"Em dash in public text: {path}"
        assert "\u00e2\u20ac" not in text and "\u00c3" not in text and "\ufffd" not in text, f"Likely text-encoding damage in {path}"

    markdown_paths = [
        path for path in ROOT.rglob("*.md")
        if "work" not in path.relative_to(ROOT).parts
    ]
    link_pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
    for path in markdown_paths:
        for target in link_pattern.findall(path.read_text(encoding="utf-8")):
            target = target.strip("<>").split("#", 1)[0]
            if not target or target.startswith(("http://", "https://", "mailto:")):
                continue
            assert (path.parent / target).resolve().exists(), f"Broken local link in {path}: {target}"

    result = {
        "status": "PASS",
        "one_month_sql_gates": one["validation_passes"],
        "three_month_sql_gates": three["validation_passes"],
        "twelve_month_sql_gates": twelve["validation_passes"],
        "twenty_four_month_sql_gates": twenty_four["validation_passes"],
        "reference_files_checked": len(reference),
        "download_intake_audit": "PASS",
        "multi_component_source_ownership": "PASS",
        "local_document_links": "PASS",
        "primary_synthetic_matrix": "3 rows x 13 features",
        "inbound_sensitivity_matrix": "2 rows x 16 features",
        "outcome_sensitivity_matrix": "2 rows x 20 features",
        "clustering_run": False,
    }
    (test_root / "test_summary.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
