# Reference validation evidence

- `output_register_and_checksums.csv` records filename, table, dimensions, size
  and SHA-256 for every frozen output.
- `matrix_numeric_validation.csv` records identifier uniqueness, feature count,
  missingness and finite-number checks for the three modelling matrices.
- `VALIDATION_SUMMARY.md` gives the independently reviewed release verdict.

Large source databases are deliberately excluded. Validation relies on complete
SQL, contracts, manifests, aggregate evidence and deterministic fingerprints.

Local pre-publication scans are generated before the first commit but are not
part of the published validation evidence because their Git-status statements
become stale as soon as the repository is created.
