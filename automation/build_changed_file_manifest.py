#!/usr/bin/env python3
"""Create the machine-readable PCADI v2 changed-file manifest."""

from __future__ import annotations

import csv
import hashlib
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DESTINATION = ROOT / "validation" / "pcadi_v2_changed_file_manifest.csv"
BASE_REF = "origin/main"


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest().upper()


def git(*arguments: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *arguments],
        cwd=ROOT,
        check=check,
        capture_output=True,
        text=True,
    )


def old_content(base_commit: str, path: str) -> bytes | None:
    result = subprocess.run(
        ["git", "show", f"{base_commit}:{path}"],
        cwd=ROOT,
        check=False,
        capture_output=True,
    )
    return result.stdout if result.returncode == 0 else None


def reason(path: str) -> tuple[str, str]:
    if path.startswith("sql/"):
        return "Propagate the locked 14-feature SQL contract.", "SQL regression and clean reference build"
    if path.startswith(("outputs/", "reference-release/validation/", "validation/")):
        return "Replace or register corrected reference evidence.", "Matrix, checksum and reference-validation gates"
    if path.startswith(("tests/", "automation/", ".github/")):
        return "Strengthen deterministic regression and release automation.", "Windows synthetic and publication tests"
    if path.startswith(("docs/", "README.md", "START_HERE.md")):
        return "Explain analytical populations and reproducibility for public readers.", "Documentation link and terminology gates"
    if path.startswith(("contracts/", "reference-release/documentation/")):
        return "Align contracts and definitions with actual output headers.", "Schema and data-dictionary checks"
    return "Prepare the controlled v2.0.0 repository release.", "Repository publication gate"


def main() -> None:
    base_commit = git("merge-base", "HEAD", BASE_REF).stdout.strip()
    if not base_commit:
        raise RuntimeError(f"Could not resolve merge base with {BASE_REF}")
    changed = {}
    for line in git("diff", "--name-status", base_commit).stdout.splitlines():
        parts = line.split("\t")
        status = parts[0]
        path = parts[-1].replace("\\", "/")
        changed[path] = {"M": "modified", "A": "added", "D": "deleted"}.get(status[0], "modified")
    for path in git("ls-files", "--others", "--exclude-standard").stdout.splitlines():
        changed[path.replace("\\", "/")] = "added"
    changed.pop(DESTINATION.relative_to(ROOT).as_posix(), None)

    rows = []
    for path, action in sorted(changed.items()):
        old = old_content(base_commit, path)
        current = ROOT / path
        new = current.read_bytes() if current.is_file() else None
        change_reason, evidence = reason(path)
        public_status = (
            "INTERNAL"
            if path.startswith(("docs/internal/", "work/"))
            else "PUBLIC"
        )
        rows.append(
            {
                "path": path,
                "action": action,
                "reason": change_reason,
                "old_sha256": sha256_bytes(old) if old is not None else "",
                "new_sha256": sha256_bytes(new) if new is not None else "",
                "validation_evidence": evidence,
                "public_internal_status": public_status,
            }
        )
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    with DESTINATION.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {len(rows)} changed-file records to {DESTINATION.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
