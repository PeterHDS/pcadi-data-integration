# Reference validation evidence

- `output_register_and_checksums.csv` records filename, table, dimensions, size
  and SHA-256 for every frozen output.
- `matrix_numeric_validation.csv` records identifier uniqueness, feature count,
  missingness and finite-number checks for the three modelling matrices.
- `VALIDATION_SUMMARY.md` gives the independently reviewed release verdict.

Large source databases are deliberately excluded. Validation relies on complete
SQL, contracts, manifests, aggregate evidence and deterministic fingerprints.

`repository_release_gate.csv` records the mandatory reference-application
checks. `release_file_manifest.csv` fingerprints the public file set without
exposing private project history.
