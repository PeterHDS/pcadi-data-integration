#!/usr/bin/env python3
"""Build the deterministic PCADI v2 reference-output release archive."""

from __future__ import annotations

import csv
import hashlib
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REGISTER = ROOT / "validation" / "pcadi_v2_authoritative_output_manifest.csv"
ARCHIVE = ROOT / "work" / "release" / "PCADI_V2_REFERENCE_OUTPUTS.zip"
MANIFEST = ROOT / "reference-release" / "validation" / "release_asset_manifest.csv"
ZIP_TIME = (2026, 7, 30, 0, 0, 0)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def main() -> None:
    with REGISTER.open("r", encoding="utf-8-sig", newline="") as handle:
        records = list(csv.DictReader(handle))
    ARCHIVE.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(
        ARCHIVE,
        "w",
        compression=zipfile.ZIP_DEFLATED,
        compresslevel=9,
    ) as archive:
        for record in sorted(records, key=lambda row: row["filename"]):
            source = ROOT / "outputs" / record["filename"]
            if not source.is_file():
                raise FileNotFoundError(source)
            if sha256(source) != record["sha256"]:
                raise ValueError(f"Manifest mismatch for {source.name}")
            info = zipfile.ZipInfo(f"outputs/{source.name}", date_time=ZIP_TIME)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 0
            info.external_attr = 0o600 << 16
            archive.writestr(info, source.read_bytes(), compresslevel=9)

    rows = [
        {
            "artifact": ARCHIVE.name,
            "role": "planned v2.0.0 GitHub Release asset",
            "rows": "",
            "columns": "",
            "bytes": ARCHIVE.stat().st_size,
            "sha256": sha256(ARCHIVE),
        }
    ]
    rows.extend(
        {
            "artifact": record["filename"],
            "role": "contained complete reference CSV",
            "rows": record["rows"],
            "columns": record["columns"],
            "bytes": record["bytes"],
            "sha256": record["sha256"],
        }
        for record in records
    )
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    with MANIFEST.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print(f"{ARCHIVE} | {ARCHIVE.stat().st_size} bytes | {sha256(ARCHIVE)}")


if __name__ == "__main__":
    main()
