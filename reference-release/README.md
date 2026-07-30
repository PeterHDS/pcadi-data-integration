# April 2025 to March 2026 reference evidence

This directory preserves the verified observation window as a worked example
of the configurable PCADI pipeline. Publication vintages may be later than the
observation months they own.

## Evidence

- `manifests/primary_annual_raw_input_manifest.csv` identifies the 21 exact OCS,
  GPAD and organisational-reference inputs for the independently reproduced
  annual core.
- `manifests/selected_release_manifest.csv` records imported source members and
  selection decisions.
- `manifests/source_month_ownership.csv` records one selected owner per required
  component-month.
- `manifests/source_month_matrix.csv` summarises twelve-month coverage.
- `manifests/temporal_official_download_manifest.csv` records official OCS
  day/time resources used for the supplementary temporal analysis.
- `validation/reference_output_manifest.csv` fingerprints all 14 derived
  outputs.
- `documentation/` contains feature dictionaries, lineage, cohort rules and
  reproduction guidance.

The source-month ownership and matrix manifests describe the main
practice-month integration. The temporal manifest and temporal output checksum
describe the supplementary day/time analysis separately.

No raw downloads, archives or SQLite databases are included. A full rebuild
requires the exact official files listed in the manifests.

The 14 complete reference CSVs are packaged in
`PCADI_REFERENCE_OUTPUTS_APR2025_MAR2026.zip`. The archive contains the seven
large practice-month tables omitted from Git history and the seven smaller
annual, modelling and temporal outputs tracked in the repository. The archive
and every member are locked in `validation/release_asset_manifest.csv`.

On a clean checkout, the reference validator downloads the period-labelled
asset, checks its name, byte size and SHA-256 fingerprint, supports its
`outputs/<filename>` member layout, restores only absent outputs and validates
every CSV. Existing output files are not overwritten.
