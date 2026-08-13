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
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PYTHON = sys.executable


def run(*arguments: str) -> None:
    subprocess.run([PYTHON, str(ROOT / "automation" / "pipeline_cli.py"), *arguments], cwd=ROOT, check=True)


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


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


def assert_inherited_values(parent_path: Path, child_path: Path) -> None:
    parent_rows = {row["practice_code_standardised"]: row for row in read_rows(parent_path)}
    child_rows = read_rows(child_path)
    shared = [name for name in child_rows[0] if name in next(iter(parent_rows.values()))]
    for child in child_rows:
        identifier = child["practice_code_standardised"]
        assert identifier in parent_rows
        parent = parent_rows[identifier]
        for name in shared:
            assert child[name] == parent[name], (identifier, name, parent[name], child[name])


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
    assert_matrix(twelve_dir / "outputs" / "annual_practice_access_modelling_matrix.csv", 3, 14)
    assert_matrix(twelve_dir / "outputs" / "inbound_telephony_sensitivity_modelling_matrix.csv", 2, 17)
    assert_matrix(twelve_dir / "outputs" / "telephony_outcome_sensitivity_modelling_matrix.csv", 2, 21)

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
        "SELECT gpad_1_day_share, gpad_2_to_7_days_share, gpad_over_14_days_share "
        "FROM annual_practice_access_modelling_matrix WHERE practice_code_standardised = 'A00001'"
    ).fetchone()
    totals = connection.execute(
        "SELECT SUM(total_appointments), SUM(one_day + two_to_seven_days), "
        "SUM(fifteen_to_twenty_one_days + twenty_two_to_twenty_eight_days + more_than_twenty_eight_days) "
        "FROM appointment_activity_source WHERE practice_code_standardised = 'A00001'"
    ).fetchone()
    one_day_total = connection.execute(
        "SELECT SUM(one_day) FROM appointment_activity_source "
        "WHERE practice_code_standardised = 'A00001'"
    ).fetchone()[0]
    two_to_seven_total = connection.execute(
        "SELECT SUM(two_to_seven_days) FROM appointment_activity_source "
        "WHERE practice_code_standardised = 'A00001'"
    ).fetchone()[0]
    connection.close()
    assert abs(row[0] - one_day_total / totals[0]) < 1e-12
    assert abs(row[1] - two_to_seven_total / totals[0]) < 1e-12
    assert one_day_total != two_to_seven_total
    assert row[0] != row[1]
    assert abs(row[2] - totals[2] / totals[0]) < 1e-12

    assert_inherited_values(
        twelve_dir / "outputs" / "annual_practice_access_modelling_matrix.csv",
        twelve_dir / "outputs" / "inbound_telephony_sensitivity_modelling_matrix.csv",
    )
    assert_inherited_values(
        twelve_dir / "outputs" / "inbound_telephony_sensitivity_modelling_matrix.csv",
        twelve_dir / "outputs" / "telephony_outcome_sensitivity_modelling_matrix.csv",
    )

    reference_path = test_root / "reference_checks.csv"
    run("validate-reference", "--restore-missing", "--output", str(reference_path))
    reference = read_rows(reference_path)
    assert len(reference) == 14
    assert all(row["status"] == "PASS" for row in reference)

    asset_rows = read_rows(
        ROOT / "reference-release" / "validation" / "release_asset_manifest.csv"
    )
    contained = {
        row["artifact"]: row
        for row in asset_rows
        if row["role"] == "contained complete reference CSV"
    }
    asset = next(
        row for row in asset_rows
        if row["artifact"] == "PCADI_REFERENCE_OUTPUTS_APR2025_MAR2026.zip"
    )
    assert asset["bytes"] == "40656898"
    assert asset["sha256"] == "93F6594BE743DA79CE4E8461DD307AF99692B31D61AAF2E12C003DB336C55022"
    assert len(contained) == 14

    primary_reference = ROOT / "outputs" / "primary_practice_access_clustering_matrix.csv"
    inbound_reference = ROOT / "outputs" / "cbt_inbound_sensitivity_clustering_matrix_17_features.csv"
    outcome_reference = ROOT / "outputs" / "cbt_outcomes_sensitivity_clustering_matrix_21_features.csv"
    assert_matrix(primary_reference, 6067, 14)
    assert_matrix(inbound_reference, 3020, 17)
    assert_matrix(outcome_reference, 1456, 21)
    assert sha256(primary_reference) == "C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF"
    assert sha256(inbound_reference) == "CCC179B870BBD3EC46DD1B75868DB38156FE23A44BBC5A8FF698505FC9B63ED5"
    assert sha256(outcome_reference) == "D3D2E70C1A718260DD332B59F835EB6316826677A1DF5CEB928ED563C0FC1021"
    assert_inherited_values(primary_reference, inbound_reference)
    assert_inherited_values(inbound_reference, outcome_reference)
    for path in (primary_reference, inbound_reference, outcome_reference):
        header = path.read_text(encoding="utf-8").splitlines()[0].split(",")
        assert "gpad_1_day_share" in header
        assert "gpad_2_to_7_days_share" in header
        obsolete_booking_name = "gpad_1_" + "to_7_days_share"
        assert obsolete_booking_name not in header

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
        and "pre_clustering_readiness_audit" not in path.relative_to(ROOT).parts
        and "python-modelling" not in path.relative_to(ROOT).parts
        and "internal" not in path.relative_to(ROOT).parts
    ]
    public_text_paths += list((ROOT / "sql" / "portable").glob("*.sql"))
    public_text_paths.append(ROOT / "CITATION.cff")
    unexplained_design_terms = re.compile(r"\bscenario[_ -]?\d|fatal flaw", re.IGNORECASE)
    local_path = re.compile(r"C:[/\\]Users[/\\]HP", re.IGNORECASE)
    for path in public_text_paths:
        text = path.read_text(encoding="utf-8")
        assert unexplained_design_terms.search(text) is None, f"Unexplained development-only terminology in {path}"
        assert local_path.search(text) is None, f"Local user path in {path}"
        assert "\u2014" not in text, f"Unexpected em dash in public text: {path}"
        assert "\u00e2\u20ac" not in text and "\u00c3" not in text and "\ufffd" not in text, f"Likely text-encoding damage in {path}"

    public_positioning = "\n".join(
        path.read_text(encoding="utf-8")
        for path in public_text_paths
    ).lower()
    for prohibited in (
        "v" + "1.0.0",
        "v" + "1.0.1",
        "v" + "2.0.0",
        "dissertation " + "release",
        "dissertation reference " + "release",
        "pcadi_" + "dissertation",
        "fixed dissertation " + "build",
        "checkout of " + "v1",
        "release/" + "v1",
        "pcadi_" + "v2",
        "former release " + "was wrong",
        "corrected " + "13-feature release",
        "superseded " + "active matrix",
        "migration to " + "v" + str(2),
    ):
        assert prohibited not in public_positioning, f"Development positioning remains public: {prohibited}"

    root_public = "\n".join(
        path.read_text(encoding="utf-8").lower()
        for path in (
            ROOT / "README.md",
            ROOT / "START_HERE.md",
            ROOT / "docs" / "PROJECT_UPDATES.md",
            ROOT / "CITATION.cff",
        )
    )
    assert "ds" + "7010" not in root_public
    assert "disser" + "tation" not in root_public

    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    assert "## Start here" in readme
    assert readme.index("## Start here") < readme.index("## Guides by reader")
    assert "Dissertation " + "release:" not in readme
    for fingerprint in (
        "C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF",
        "CCC179B870BBD3EC46DD1B75868DB38156FE23A44BBC5A8FF698505FC9B63ED5",
        "D3D2E70C1A718260DD332B59F835EB6316826677A1DF5CEB928ED563C0FC1021",
    ):
        assert fingerprint not in readme

    citation = (ROOT / "CITATION.cff").read_text(encoding="utf-8")
    assert "cff-version: 1.2.0" in citation
    assert 'title: "PCADI: Primary Care Activity Data Integration"' in citation
    assert "type: software" in citation
    assert "\nversion:" not in citation
    assert "\ndate-released:" not in citation

    for filename in ("CODE_OF_CONDUCT.md", "CONTRIBUTING.md", "SECURITY.md"):
        assert (ROOT / ".github" / filename).is_file()
        assert not (ROOT / filename).exists()
    for filename in ("DATA_AVAILABILITY.md", "EVIDENCE_BASE_AND_REFERENCES.md", "PRACTICAL_USE_CASES.md", "PROJECT_ARCHITECTURE.md", "PROJECT_CONTEXT_AND_RESPONSIBLE_USE.md", "PROJECT_UPDATES.md"):
        assert (ROOT / "docs" / filename).is_file()
    for filename in ("CHANGELOG.md", "DATA_AVAILABILITY.md", "DISCLAIMER.md"):
        assert not (ROOT / filename).exists()

    expected_images = {
        "pcadi-architecture.png": (1600, 1090),
        "pcadi-cohort-flow.png": (1400, 930),
        "social-preview.png": (1280, 640),
    }
    for filename, expected_dimensions in expected_images.items():
        path = ROOT / "docs" / "assets" / filename
        with path.open("rb") as handle:
            signature = handle.read(24)
        assert signature[:8] == b"\x89PNG\r\n\x1a\n"
        assert struct.unpack(">II", signature[16:24]) == expected_dimensions
    for filename in ("pcadi-architecture.svg", "pcadi-cohort-flow.svg", "social-preview.svg"):
        root = ET.parse(ROOT / "docs" / "assets" / filename).getroot()
        assert root.tag.endswith("svg")

    pipeline_cli_text = (ROOT / "automation" / "pipeline_cli.py").read_text(encoding="utf-8")
    assert "reference-apr2025-mar2026" in pipeline_cli_text
    assert "PCADI_REFERENCE_OUTPUTS_APR2025_MAR2026.zip" in pipeline_cli_text
    assert 'members.get(f"outputs/{filename}")' in pipeline_cli_text
    assert "PRE_RELEASE_FALLBACK" not in pipeline_cli_text

    markdown_paths = [
        path for path in ROOT.rglob("*.md")
        if "work" not in path.relative_to(ROOT).parts
        and "pre_clustering_readiness_audit" not in path.relative_to(ROOT).parts
        and "python-modelling" not in path.relative_to(ROOT).parts
    ]
    link_pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
    for path in markdown_paths:
        for target in link_pattern.findall(path.read_text(encoding="utf-8")):
            target = target.strip("<>").split("#", 1)[0]
            if not target or target.startswith(("http://", "https://", "mailto:")):
                continue
            assert (path.parent / target).resolve().exists(), f"Broken local link in {path}: {target}"

    acquisition_guide = (ROOT / "docs" / "get-official-nhs-data" / "README.md").read_text(encoding="utf-8")
    for series_path in (
        "submissions-via-online-consultation-systems-in-general-practice",
        "appointments-in-general-practice",
        "cloud-based-telephony-data-in-general-practice",
        "patients-registered-at-a-gp-practice",
    ):
        expected_url = f"https://digital.nhs.uk/data-and-information/publications/statistical/{series_path}"
        assert expected_url in acquisition_guide, f"Official NHS England release index missing: {expected_url}"

    inspection_guide = (ROOT / "docs" / "audiences" / "reference-inspection-guide.md").read_text(encoding="utf-8")
    assert "../../outputs/primary_practice_access_clustering_matrix.csv" in inspection_guide
    assert "../../validation/authoritative_output_manifest.csv" in inspection_guide
    assert "6,067" in inspection_guide and "14 complete numerical modelling features" in inspection_guide

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
        "primary_synthetic_matrix": "3 rows x 14 features",
        "inbound_sensitivity_matrix": "2 rows x 17 features",
        "outcome_sensitivity_matrix": "2 rows x 21 features",
        "clustering_run": False,
    }
    (test_root / "test_summary.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
