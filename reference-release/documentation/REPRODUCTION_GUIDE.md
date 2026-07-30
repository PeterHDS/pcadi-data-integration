# Reproduce the fixed April 2025 to March 2026 release

There are two levels of review. Choose the one supported by the files available
to you.

## Validate the published derived outputs

Double-click `RUN_REFERENCE_VALIDATION.cmd`, or run:

```powershell
python automation/pipeline_cli.py validate-reference `
  --restore-missing `
  --output work/reference_validation.csv
```

This recalculates SHA-256 checksums for the fourteen fixed outputs and compares
them with `validation/output_register_and_checksums.csv`. It does not require a
source database. On a fresh clone of v2.0.0, `--restore-missing` downloads the
pinned `PCADI_V2_REFERENCE_OUTPUTS.zip` asset, verifies its 40,656,898-byte
archive and SHA-256 checksum, restores only absent reference CSVs and verifies
every restored file before validation. Existing output files are not
overwritten.

During review, before the v2.0.0 asset exists, the same command may obtain the
seven unchanged practice-month outputs from the published v1.0.1 archive. The
fallback is accepted only if each filename, byte count and SHA-256 checksum
matches the current v2 manifest. It cannot restore or replace the corrected
annual modelling matrices.

## Rebuild the primary annual OCS-GPAD matrix from source CSVs

Obtain the exact 21 official CSVs listed in
`reference-release/input_manifest.csv`. Place each file at its
`recommended_relative_path`, preserving its bytes, filename and header. Then
double-click `RUN_REFERENCE_BUILD.cmd`, or run its documented Python command.

The runner:

1. checks all 21 source hashes, headers and row counts;
2. imports every field as text into a new ignored SQLite database;
3. executes the twelve ordered SQL stages in `sql/core_pipeline/`;
4. runs 39 mandatory validations plus database integrity checks; and
5. compares all 6,067 canonical feature fingerprints with the expected
   fingerprint evidence.

The build writes under `work/reference-build/`, which is excluded from Git. It
does not modify the fixed CSVs in `outputs/`.

## What this rebuild proves

The full raw-source build independently reconstructs the primary annual
OCS-GPAD analytical matrix. The wider fixed release also contains CBT
sensitivity and temporal outputs whose complete SQL, manifests and checksums
are retained as separate evidence. Rebuilding those products requires their
own official source files and is not silently substituted by the OCS-GPAD
rebuild.

## Analytical boundaries

- The practice identifier is retained for traceability and is not a feature.
- OCS, GPAD and CBT activity counts are never added together.
- Missing source rows are not interpreted as zero activity.
- No feature is imputed, capped or winsorised.
- No clustering is executed by this repository.
