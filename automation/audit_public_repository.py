#!/usr/bin/env python3
"""Audit PCADI public writing, navigation, images and analytical contracts."""

from __future__ import annotations

import csv
import hashlib
import json
import math
import re
import struct
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "work" / "public_repository_audit.json"
MARKDOWN_LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
HEADING = re.compile(r"^(#{1,6})\s+(.+?)\s*$", re.MULTILINE)
LOCAL_PATH = re.compile(r"[A-Za-z]:[/\\]Users[/\\]|PCADI_PRIVATE_PROJECT_AUDIT", re.IGNORECASE)
FULL_HASH = re.compile(r"\b[A-Fa-f0-9]{64}\b")
STRUCTURAL_LINE = re.compile(r"^(?:\s*$|#{1,6}\s|\s*(?:[-+*]|\d+[.)])\s+|\s*\||\s*>|\s{4}|\t|```|~~~|<[^>]+>|---+$|___+$|\*\*\*+$)")

PROHIBITED_PUBLIC_PATTERNS = {
    "defensive_scope": re.compile(
        r"\b(?:this is not|it is not|not an NHS|not a performance|must not be interpreted|"
        r"does not establish|does not measure|cannot be used|not total demand|not total workload|"
        r"not patient journeys|not a failed join|not automatically)\b",
        re.IGNORECASE,
    ),
    "release_positioning": re.compile(
        r"\b(?:reframe|v1\.0\.0|v1\.0\.1|v2\.0\.0|dissertation release|corrected release|"
        r"former release|superseded release|release/v1|pcadi_v2)\b",
        re.IGNORECASE,
    ),
    "internal_or_ai_language": re.compile(
        r"\b(?:AI-written|AI generated|Codex|scenario\s+[1-8])\b",
        re.IGNORECASE,
    ),
    "formulaic_prose": re.compile(
        r"\b(?:This is not just|More than merely|At its core|In today.s rapidly evolving|Delve into|"
        r"Seamlessly|Robust and comprehensive|Underscores the importance|A testament to|"
        r"Game-changing|Holistic)\b",
        re.IGNORECASE,
    ),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def repository_files() -> list[Path]:
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
    return {github_anchor(title) for _, title in HEADING.findall(path.read_text(encoding="utf-8"))}


def inspect_markdown_style(path: Path) -> list[str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    failures: list[str] = []
    fenced = False
    previous_heading = 0
    blank_run = 0
    table_columns: int | None = None
    for index, line in enumerate(lines, start=1):
        stripped = line.strip()
        if stripped.startswith(("```", "~~~")):
            fenced = not fenced
            blank_run = 0
            table_columns = None
            continue
        if fenced:
            continue
        if line != line.rstrip():
            failures.append(f"{path.relative_to(ROOT)}:{index}: trailing whitespace")
        if not stripped:
            blank_run += 1
            if blank_run > 1:
                failures.append(f"{path.relative_to(ROOT)}:{index}: consecutive blank line")
            table_columns = None
            continue
        blank_run = 0
        heading = re.match(r"^(#{1,6})\s+", line)
        if heading:
            level = len(heading.group(1))
            if previous_heading and level > previous_heading + 1:
                failures.append(f"{path.relative_to(ROOT)}:{index}: heading jump {previous_heading}->{level}")
            previous_heading = level
        if stripped.startswith("|") and stripped.endswith("|"):
            table_shape = re.sub(r"`[^`]*`", "", stripped)
            columns = len(re.findall(r"(?<!\\)\|", table_shape)) - 1
            if table_columns is None:
                table_columns = columns
            elif columns != table_columns:
                failures.append(f"{path.relative_to(ROOT)}:{index}: table has {columns} columns, expected {table_columns}")
        else:
            table_columns = None
        if index < len(lines):
            next_line = lines[index]
            if stripped and next_line.strip() and not STRUCTURAL_LINE.match(line) and not STRUCTURAL_LINE.match(next_line):
                failures.append(f"{path.relative_to(ROOT)}:{index}: hard-wrapped prose")
    text = "\n".join(lines)
    if re.search(r"\]\s*\n\s*\(", text):
        failures.append(f"{path.relative_to(ROOT)}: broken inline link across source lines")
    return failures


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
    observed_hash = sha256(path)
    return {
        "path": path.relative_to(ROOT).as_posix(),
        "rows": len(records),
        "columns": len(header),
        "sha256": observed_hash,
        "unique_ids": len(set(codes)),
        "blank_ids": sum(not code for code in codes),
        "numeric_finite": values_valid,
        "status": "PASS" if len(records) == rows and len(header) == columns and observed_hash == expected_hash and len(set(codes)) == rows and all(codes) and values_valid else "FAIL",
    }


def add_check(checks: list[dict[str, object]], name: str, failures: list[str], **details: object) -> None:
    checks.append({"check": name, "status": "PASS" if not failures else "FAIL", "failures": failures, **details})


def main() -> int:
    checks: list[dict[str, object]] = []
    files = repository_files()
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
            if separator and target_path.suffix.lower() == ".md" and anchor not in markdown_anchors(target_path):
                broken_anchors.append(f"{path.relative_to(ROOT)} -> {target}")
    add_check(checks, "markdown_links", broken_links)
    add_check(checks, "markdown_anchors", broken_anchors)

    writing_hits: dict[str, list[str]] = {name: [] for name in PROHIBITED_PUBLIC_PATTERNS}
    local_path_hits: list[str] = []
    academic_hits: list[str] = []
    allowed_academic = {"docs/research-context.md"}
    public_text = [path for path in files if path.suffix.lower() in {".md", ".html", ".svg", ".cff"}]
    for path in public_text:
        relative = path.relative_to(ROOT).as_posix()
        text = path.read_text(encoding="utf-8-sig", errors="replace")
        for name, pattern in PROHIBITED_PUBLIC_PATTERNS.items():
            for match in pattern.finditer(text):
                line = text.count("\n", 0, match.start()) + 1
                writing_hits[name].append(f"{relative}:{line}: {match.group(0)}")
        if LOCAL_PATH.search(text):
            local_path_hits.append(relative)
        lowered = text.lower()
        if path.suffix.lower() in {".md", ".cff"} and relative not in allowed_academic and (("ds" + "7010") in lowered or ("disser" + "tation") in lowered):
            academic_hits.append(relative)
    for name, failures in writing_hits.items():
        add_check(checks, f"public_writing_{name}", failures)
    add_check(checks, "local_or_private_paths", local_path_hits)
    add_check(checks, "academic_context_location", academic_hits)

    style_failures = [failure for path in markdown for failure in inspect_markdown_style(path)]
    add_check(checks, "markdown_source_style", style_failures)

    required_community = [ROOT / ".github" / name for name in ("CODE_OF_CONDUCT.md", "CONTRIBUTING.md", "SECURITY.md")]
    community_failures = [str(path.relative_to(ROOT)) for path in required_community if not path.is_file()]
    add_check(checks, "github_community_files", community_failures)

    forbidden_root = ["CHANGELOG.md", "CODE_OF_CONDUCT.md", "CONTRIBUTING.md", "DATA_AVAILABILITY.md", "DISCLAIMER.md", "SECURITY.md"]
    required_docs = ["docs/DATA_AVAILABILITY.md", "docs/EVIDENCE_BASE_AND_REFERENCES.md", "docs/PRACTICAL_USE_CASES.md", "docs/PROJECT_ARCHITECTURE.md", "docs/PROJECT_CONTEXT_AND_RESPONSIBLE_USE.md", "docs/PROJECT_UPDATES.md"]
    housekeeping = [name for name in forbidden_root if (ROOT / name).exists()] + [name for name in required_docs if not (ROOT / name).is_file()]
    add_check(checks, "root_housekeeping", housekeeping)

    private_tracked = [path.relative_to(ROOT).as_posix() for path in files if "PCADI_PRIVATE_PROJECT_AUDIT" in path.relative_to(ROOT).as_posix()]
    add_check(checks, "private_audit_excluded", private_tracked)

    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    required_readme_sections = ["## Start here", "## What PCADI provides", "## Choose an analytical design", "## Evidence base and design input", "## Project architecture and downstream use", "## Guides by reader"]
    readme_failures = [section for section in required_readme_sections if section not in readme]
    if FULL_HASH.search(readme):
        readme_failures.append("full SHA-256 displayed on landing page")
    add_check(checks, "readme_structure", readme_failures)

    expected_png = {"pcadi-architecture.png": (1600, 1090), "pcadi-cohort-flow.png": (1400, 930), "social-preview.png": (1280, 640)}
    image_failures: list[str] = []
    dimensions: dict[str, tuple[int, int]] = {}
    for name, expected in expected_png.items():
        path = ROOT / "docs" / "assets" / name
        try:
            with path.open("rb") as handle:
                header = handle.read(24)
            if header[:8] != b"\x89PNG\r\n\x1a\n":
                raise ValueError("invalid PNG signature")
            observed = struct.unpack(">II", header[16:24])
            dimensions[name] = observed
            if observed != expected:
                image_failures.append(f"{name}: expected {expected}, observed {observed}")
        except Exception as exc:
            image_failures.append(f"{name}: {exc}")
    for name in ("pcadi-architecture.svg", "pcadi-cohort-flow.svg", "social-preview.svg"):
        try:
            root = ET.parse(ROOT / "docs" / "assets" / name).getroot()
            if not root.tag.endswith("svg"):
                image_failures.append(f"{name}: root element")
        except Exception as exc:
            image_failures.append(f"{name}: {exc}")
    add_check(checks, "public_images", image_failures, dimensions=dimensions)

    matrices = [
        inspect_matrix(ROOT / "outputs" / "primary_practice_access_clustering_matrix.csv", 6067, 15, "C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF"),
        inspect_matrix(ROOT / "outputs" / "cbt_inbound_sensitivity_clustering_matrix_17_features.csv", 3020, 18, "CCC179B870BBD3EC46DD1B75868DB38156FE23A44BBC5A8FF698505FC9B63ED5"),
        inspect_matrix(ROOT / "outputs" / "cbt_outcomes_sensitivity_clustering_matrix_21_features.csv", 1456, 22, "D3D2E70C1A718260DD332B59F835EB6316826677A1DF5CEB928ED563C0FC1021"),
    ]
    add_check(checks, "authoritative_matrices", [item["path"] for item in matrices if item["status"] != "PASS"], matrices=matrices)

    citation = (ROOT / "CITATION.cff").read_text(encoding="utf-8")
    citation_ok = "cff-version: 1.2.0" in citation and "type: software" in citation and "\nversion:" not in citation and "\ndate-released:" not in citation
    add_check(checks, "citation_metadata", [] if citation_ok else ["CITATION.cff must remain valid and versionless"])

    passes = sum(item["status"] == "PASS" for item in checks)
    failures = len(checks) - passes
    report = {
        "status": "PASS" if failures == 0 else "FAIL",
        "passes": passes,
        "failures": failures,
        "public_writing_occurrences": sum(len(items) for items in writing_hits.values()),
        "checks": checks,
        "clustering_run": False,
    }
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
