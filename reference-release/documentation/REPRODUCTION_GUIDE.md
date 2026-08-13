# Reproduce the April 2025 to March 2026 reference application

There are two review levels. Choose the one supported by the available files.

## Validate the published derived outputs

Double-click `RUN_REFERENCE_VALIDATION.cmd`, or run:

```powershell
python automation/pipeline_cli.py validate-reference `
  --restore-missing `
  --output work/reference_validation.csv
```

The command checks 14 outputs against `validation/output_register_and_checksums.csv`. It does not require a source database. On a clean checkout, `--restore-missing` downloads `PCADI_REFERENCE_OUTPUTS_APR2025_MAR2026.zip` from the `reference-apr2025-mar2026` release, verifies its 40,656,898-byte size and SHA-256 checksum, retrieves only absent `outputs/<filename>` members, and verifies every restored CSV. Existing output files are not overwritten.

## Rebuild the primary annual OCS-GPAD matrix

Obtain the exact 21 official CSVs listed in `reference-release/input_manifest.csv`. These are the OCS, GPAD and mapping inputs for the national annual OCS-GPAD build. Place each file at its `recommended_relative_path`, preserving its bytes, filename and header. Then double-click `RUN_REFERENCE_BUILD.cmd`, or run its documented Python command.

The runner:

1. checks all 21 source hashes, headers and row counts;
2. imports every field as text into a new ignored SQLite database;
3. executes the twelve ordered SQL stages in `sql/core_pipeline/`;
4. runs 39 mandatory validations plus database integrity checks; and
5. compares all 6,067 canonical feature fingerprints with the expected evidence.

The build writes under `work/reference-build/`, which is excluded from Git. It does not modify the frozen CSVs in `outputs/`.

## Scope

The raw-source build independently reconstructs the primary annual OCS-GPAD matrix. The reference application also contains CBT sensitivity and temporal outputs whose SQL, selected-release manifests, prepared-evidence contracts and checksums are retained separately. Rebuilding CBT directly from raw official archives requires its own acquisition, account-to-practice mapping, integrity and reconciliation workflow beyond the 21-file command.

- The practice identifier is retained for traceability and is not a feature.
- OCS, GPAD and CBT activity counts are never added together.
- Missing source rows are not interpreted as zero activity.
- No feature is imputed, capped or winsorised.
- No clustering is executed by this repository.
