#!/usr/bin/env python3
"""Build the pre-Git file manifest and fail on publication blockers."""

from __future__ import annotations

import csv
import hashlib
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXCLUDED_DIRS = {".git", "work", "__pycache__", ".pytest_cache"}
EXCLUDED_PREFIXES = {
    "data/downloads/",
    "data/prepared/",
    "data/raw/",
}
IGNORED_LARGE_OUTPUTS = {
    "outputs/online_consultation_led_appointment_alignment.csv",
    "outputs/appointment_led_online_consultation_alignment.csv",
    "outputs/multichannel_practice_month_coverage.csv",
    "outputs/online_consultation_appointment_complete_cases.csv",
    "outputs/three_source_complete_cases.csv",
    "outputs/telephone_matched_online_consultation_appointment_comparison.csv",
    "outputs/telephone_matched_multichannel_comparison.csv",
}
ARCHIVE_SUFFIXES = {".zip", ".7z", ".rar", ".gz", ".tar"}
DATABASE_SUFFIXES = {".db", ".sqlite", ".sqlite3"}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def is_candidate(path: Path) -> bool:
    relative = path.relative_to(ROOT).as_posix()
    if relative in {
        "INSPECT_BEFORE_GIT.md",
        "validation/GITHUB_READINESS.md",
        "validation/PRE_GIT_PUBLICATION_MANIFEST.csv",
        "validation/PRE_GIT_READINESS.json",
        "reference-release/documentation/GITHUB_PUBLICATION_CHECKLIST.md",
    }:
        return False
    if any(part in EXCLUDED_DIRS for part in path.relative_to(ROOT).parts):
        return False
    if any(relative.startswith(prefix) for prefix in EXCLUDED_PREFIXES):
        return False
    if relative in IGNORED_LARGE_OUTPUTS:
        return False
    return True


def main() -> None:
    files = sorted(path for path in ROOT.rglob("*") if path.is_file() and is_candidate(path))
    rows = []
    blockers = []
    text_suffixes = {".md", ".py", ".sql", ".json", ".csv", ".txt", ".yml", ".yaml", ".cmd", ".cff"}
    local_path_pattern = re.compile(r"C:\\Users\\HP", re.IGNORECASE)
    unexplained_design_pattern = re.compile(r"\bscenario[_ -]?\d|fatal flaw", re.IGNORECASE)
    public_roots = {"README.md", "START_HERE.md"}

    for path in files:
        relative = path.relative_to(ROOT).as_posix()
        category = "tracked_candidate"
        if path.suffix.lower() in ARCHIVE_SUFFIXES:
            blockers.append(f"Archive in tracked candidate: {relative}")
        if path.suffix.lower() in DATABASE_SUFFIXES:
            blockers.append(f"Database in tracked candidate: {relative}")
        if path.stat().st_size > 100 * 1024 * 1024:
            blockers.append(f"File exceeds 100 MiB: {relative}")
        if path.suffix.lower() in text_suffixes:
            text = path.read_text(encoding="utf-8-sig", errors="replace")
            if local_path_pattern.search(text):
                blockers.append(f"Local user path in tracked text: {relative}")
            if "\u00e2\u20ac" in text or "\u00c3" in text or "\ufffd" in text:
                blockers.append(f"Likely text-encoding damage: {relative}")
            public = (
                relative in public_roots
                or path.suffix.lower() == ".md"
                or relative.startswith("docs/")
                or relative.startswith("sql/portable/")
            )
            if public and unexplained_design_pattern.search(text):
                blockers.append(f"Unexplained development-only terminology in public material: {relative}")
        rows.append({
            "relative_path": relative,
            "category": category,
            "bytes": path.stat().st_size,
            "sha256": sha256(path),
        })

    validation = ROOT / "validation"
    validation.mkdir(exist_ok=True)
    manifest = validation / "PRE_GIT_PUBLICATION_MANIFEST.csv"
    with manifest.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    result = {
        "status": "PASS" if not blockers else "FAIL",
        "candidate_files": len(rows),
        "candidate_bytes": sum(row["bytes"] for row in rows),
        "largest_file": max(rows, key=lambda row: row["bytes"]),
        "blockers": blockers,
        "git_initialised": (ROOT / ".git").exists(),
        "clustering_run": False,
    }
    (validation / "PRE_GIT_READINESS.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    if blockers:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
