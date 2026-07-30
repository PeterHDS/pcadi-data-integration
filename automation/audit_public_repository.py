#!/usr/bin/env python3
"""Audit PCADI public wording, links, images and analytical contracts."""

from __future__ import annotations

import csv
import hashlib
import json
import math
import re
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "work" / "public_repository_audit.json"
MARKDOWN_LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
HEADING = re.compile(r"^#{1,6}\s+(.+?)\s*$", re.MULTILINE)
LOCAL_PATH = re.compile(r"[A-Za-z]:[/\\]Users[/\\]|PCADI_PRIVATE_PROJECT_AUDIT", re.IGNORECASE)
FULL_HASH = re.compile(r"\b[A-Fa-f0-9]{64}\b")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def tracked_files() -> list[Path]:
    listed = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.splitlines()
    return sorted(ROOT / item for item in listed if (ROOT / item).is_file())


def github_anchor(heading: str) -> str:
    value = re.sub(r"<[^>]+>", "", heading).strip().lower()
    value = re.sub(r"[^\w\- ]", "", value, flags=re.UNICODE)
    return re.sub(r" +", "-", value)


def markdown_anchors(path: Path) -> set[str]:
    return {github_anchor(item) for item in HEADING.findall(path.read_text(encoding="utf-8"))}


def inspect_matrix(path: Path, rows: int, columns: int, expected_hash: str) -> dict[str, object]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        records = list(reader)
        header = reader.fieldnames or []
    codes = [row.get("practice_code_standardised", "").strip() for row in records]
    values_valid = True
    for row in records:
        for name in header[1:]:
            try:
                value = float(row[name])
            except (TypeError, ValueError):
                values_valid = False
                continue
            if not math.isfinite(value):
                values_valid = False
    return {
        "path": path.relative_to(ROOT).as_posix(),
        "rows": len(records),
        "columns": len(header),
        "sha256": sha256(path),
        "unique_ids": len(set(codes)),
        "blank_ids": sum(not code for code in codes),
        "numeric_finite": values_valid,
        "status": (
            "PASS"
            if len(records) == rows
            and len(header) == columns
            and sha256(path) == expected_hash
            and len(set(codes)) == rows
            and all(codes)
            and values_valid
            else "FAIL"
        ),
    }


def main() -> int:
    checks: list[dict[str, object]] = []
    files = tracked_files()
    markdown = [path for path in files if path.suffix.lower() == ".md"]

    broken_links: list[str] = []
    broken_anchors: list[str] = []
    for path in markdown:
        text = path.read_text(encoding="utf-8")
        for raw_target in MARKDOWN_LINK.findall(text):
            target = raw_target.strip().strip("<>")
            if target.startswith(("http://", "https://", "mailto:")):
                continue
            file_part, separator, anchor = target.partition("#")
            target_path = path if not file_part else (path.parent / unquote(file_part)).resolve()
            if not target_path.exists():
                broken_links.append(f"{path.relative_to(ROOT)} -> {target}")
                continue
            if separator and target_path.suffix.lower() == ".md":
                if anchor not in markdown_anchors(target_path):
                    broken_anchors.append(f"{path.relative_to(ROOT)} -> {target}")
    checks.append({
        "check": "markdown_links",
        "status": "PASS" if not broken_links else "FAIL",
        "failures": broken_links,
    })
    checks.append({
        "check": "markdown_anchors",
        "status": "PASS" if not broken_anchors else "FAIL",
        "failures": broken_anchors,
    })

    text_files = [
        path for path in files
        if path.suffix.lower() in {".md", ".py", ".sql", ".json", ".csv", ".txt", ".yml", ".yaml", ".cmd", ".cff"}
    ]
    prohibited_version_terms = [
        "v" + "1.0.0",
        "v" + "1.0.1",
        "v" + "2.0.0",
        "PCADI_" + "DISSERTATION",
        "release/" + "v1",
        "pcadi_" + "v2",
    ]
    prohibited_version_hits: list[str] = []
    local_path_hits: list[str] = []
    prohibited_academic_hits: list[str] = []
    allowed_academic = {
        "docs/research-context.md",
        "docs/audiences/examiner-guide.md",
    }
    for path in text_files:
        relative = path.relative_to(ROOT).as_posix()
        text = path.read_text(encoding="utf-8-sig", errors="replace")
        lowered = text.lower()
        for term in prohibited_version_terms:
            if term.lower() in lowered:
                prohibited_version_hits.append(f"{relative}: {term}")
        if relative != "automation/audit_public_repository.py" and LOCAL_PATH.search(text):
            local_path_hits.append(relative)
        publication_facing = path.suffix.lower() in {".md", ".cff"}
        if publication_facing and relative not in allowed_academic and (
            ("ds" + "7010") in lowered or ("disser" + "tation") in lowered
        ):
            prohibited_academic_hits.append(relative)
    checks.append({
        "check": "prohibited_public_version_references",
        "status": "PASS" if not prohibited_version_hits else "FAIL",
        "failures": prohibited_version_hits,
    })
    checks.append({
        "check": "prohibited_academic_positioning",
        "status": "PASS" if not prohibited_academic_hits else "FAIL",
        "failures": prohibited_academic_hits,
    })
    checks.append({
        "check": "local_or_private_paths",
        "status": "PASS" if not local_path_hits else "FAIL",
        "failures": local_path_hits,
    })

    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    checks.append({
        "check": "readme_hash_presentation",
        "status": "PASS" if not FULL_HASH.search(readme) else "FAIL",
        "failures": FULL_HASH.findall(readme),
    })
    checks.append({
        "check": "task_led_navigation",
        "status": (
            "PASS"
            if readme.index("## Start here") < readme.index("## Guides for particular readers")
            else "FAIL"
        ),
        "failures": [],
    })

    expected_png = {
        "pcadi-architecture.png": (1600, 1090),
        "pcadi-cohort-flow.png": (1400, 930),
        "social-preview.png": (1280, 640),
    }
    image_failures: list[str] = []
    image_dimensions: dict[str, tuple[int, int]] = {}
    for name, expected in expected_png.items():
        path = ROOT / "docs" / "assets" / name
        try:
            with path.open("rb") as handle:
                header = handle.read(24)
            if header[:8] != b"\x89PNG\r\n\x1a\n":
                raise ValueError("invalid PNG signature")
            observed = struct.unpack(">II", header[16:24])
            image_dimensions[name] = observed
            if observed != expected:
                image_failures.append(f"{name}: expected {expected}, observed {observed}")
        except Exception as exc:
            image_failures.append(f"{name}: {exc}")
    for name in ("pcadi-architecture.svg", "pcadi-cohort-flow.svg", "social-preview.svg"):
        try:
            root = ET.parse(ROOT / "docs" / "assets" / name).getroot()
            if not root.tag.endswith("svg"):
                image_failures.append(f"{name}: root is not svg")
        except Exception as exc:
            image_failures.append(f"{name}: {exc}")
    checks.append({
        "check": "public_images",
        "status": "PASS" if not image_failures else "FAIL",
        "dimensions": image_dimensions,
        "failures": image_failures,
    })

    matrices = [
        inspect_matrix(
            ROOT / "outputs" / "primary_practice_access_clustering_matrix.csv",
            6067,
            15,
            "C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF",
        ),
        inspect_matrix(
            ROOT / "outputs" / "cbt_inbound_sensitivity_clustering_matrix_17_features.csv",
            3020,
            18,
            "CCC179B870BBD3EC46DD1B75868DB38156FE23A44BBC5A8FF698505FC9B63ED5",
        ),
        inspect_matrix(
            ROOT / "outputs" / "cbt_outcomes_sensitivity_clustering_matrix_21_features.csv",
            1456,
            22,
            "D3D2E70C1A718260DD332B59F835EB6316826677A1DF5CEB928ED563C0FC1021",
        ),
    ]
    checks.append({
        "check": "authoritative_matrices",
        "status": "PASS" if all(item["status"] == "PASS" for item in matrices) else "FAIL",
        "matrices": matrices,
        "failures": [item["path"] for item in matrices if item["status"] != "PASS"],
    })

    citation = (ROOT / "CITATION.cff").read_text(encoding="utf-8")
    citation_ok = (
        "cff-version: 1.2.0" in citation
        and "type: software" in citation
        and "\nversion:" not in citation
        and "\ndate-released:" not in citation
    )
    checks.append({
        "check": "citation_metadata",
        "status": "PASS" if citation_ok else "FAIL",
        "failures": [],
    })

    passes = sum(item["status"] == "PASS" for item in checks)
    failures = len(checks) - passes
    report = {
        "status": "PASS" if failures == 0 else "FAIL",
        "passes": passes,
        "failures": failures,
        "prohibited_public_version_references": len(prohibited_version_hits),
        "prohibited_root_academic_references": sum(
            term in "\n".join(
                (ROOT / name).read_text(encoding="utf-8").lower()
                for name in ("README.md", "START_HERE.md", "CHANGELOG.md", "CITATION.cff")
            )
            for term in (("ds" + "7010"), ("disser" + "tation"))
        ),
        "checks": checks,
        "clustering_run": False,
    }
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
