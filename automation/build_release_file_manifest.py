#!/usr/bin/env python3
"""Create a checksum inventory for the planned dissertation reference release."""

from __future__ import annotations

import csv
import hashlib
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DESTINATION = ROOT / "validation" / "release_file_manifest.csv"
EXCLUDED_PREFIXES = (
    ".git/",
    "work/",
    "data/downloads/",
    "data/prepared/",
    "data/raw/",
)
EXCLUDED_FILES = {
    DESTINATION.relative_to(ROOT).as_posix(),
    "validation/PRE_GIT_PUBLICATION_MANIFEST.csv",
    "validation/PRE_GIT_READINESS.json",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def category(path: str) -> str:
    if path.startswith("sql/"):
        return "SQL"
    if path.startswith(("outputs/", "reference-release/validation/", "validation/")):
        return "VALIDATION_OR_OUTPUT"
    if path.startswith(("tests/", "automation/", ".github/")):
        return "AUTOMATION_AND_TESTS"
    if path.startswith(("docs/", "README.md", "START_HERE.md")):
        return "DOCUMENTATION"
    if path.startswith(("contracts/", "reference-release/documentation/")):
        return "CONTRACT_OR_DICTIONARY"
    return "PROJECT"


def main() -> None:
    listed = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.splitlines()
    paths = sorted(
        relative.replace("\\", "/")
        for relative in listed
        if relative.replace("\\", "/") not in EXCLUDED_FILES
        and not relative.replace("\\", "/").startswith(EXCLUDED_PREFIXES)
        and (ROOT / relative).is_file()
    )
    rows = [
        {
            "path": relative,
            "category": category(relative),
            "bytes": (ROOT / relative).stat().st_size,
            "sha256": sha256(ROOT / relative),
            "public_status": "PUBLIC",
        }
        for relative in paths
    ]
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    with DESTINATION.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {len(rows)} release-file records to {DESTINATION.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
