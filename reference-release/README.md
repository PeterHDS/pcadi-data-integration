# April 2025-March 2026 reference release

This directory preserves the dissertation observation window as a worked,
validated example of the configurable pipeline. Publication vintages may be
later than the observation months they own.

## Evidence

- `manifests/primary_annual_raw_input_manifest.csv` identifies the 21 exact OCS,
  GPAD and organisational-reference inputs for the independently reproduced
  annual core, including checksums, schemas and row counts.
- `manifests/selected_release_manifest.csv` records the wider imported source
  members and their selection decisions.
- `manifests/source_month_ownership.csv` proves one selected owner per required
  component-month.
- `manifests/source_month_matrix.csv` summarises twelve-month coverage.
- `manifests/temporal_official_download_manifest.csv` retains the official OCS
  day/time resource URLs and checksums used for the temporal analysis.
- `validation/reference_output_manifest.csv` fingerprints all 14 derived outputs.
- `documentation/` contains the reference feature dictionaries, lineage,
  cohort rules and academic methods text.

The evidence has two defined scopes. The source-month ownership and matrix
files describe the main practice-month integration and record that OCS
day/time data were outside that input set. The temporal download manifest and
temporal output checksum separately describe the supplementary day/time
analysis. Keeping the scopes separate prevents a temporal resource from being
mistaken for an input to the main practice-month build.

No raw downloads, archives or SQLite databases are included. The main
repository outputs can be validated from their checksums without rebuilding the
large databases. A complete rebuild additionally requires the exact official
files listed in the manifests.

The fourteen complete reference CSVs are packaged as the v2.0.0 GitHub Release
asset `PCADI_V2_REFERENCE_OUTPUTS.zip`. The archive includes the seven large
practice-month tables omitted from Git history and the seven smaller annual,
modelling and temporal outputs tracked in the repository. The asset and every
contained file have locked checksums in
`validation/release_asset_manifest.csv`. After v2.0.0 is published, the
reference validator can restore missing files without overwriting files that
are already present.
