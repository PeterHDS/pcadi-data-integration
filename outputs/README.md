# Frozen reference outputs

These CSVs are the validated April 2025-March 2026 dissertation reference
release. Their names describe their analytical population or role. They are not
generic claims about access quality.

The complete checksum, row and column manifest is
`validation/output_register_and_checksums.csv`. Run
`RUN_REFERENCE_VALIDATION.cmd` to compare every file byte-for-byte with that
manifest.

## Primary clustering input

[`primary_practice_access_clustering_matrix.csv`](primary_practice_access_clustering_matrix.csv)
is the authoritative full-precision input for the main dissertation clustering
analysis. It contains 6,067 unique practices, one traceability identifier and
13 complete numerical features. The identifier must be excluded from the
feature matrix. The file is included for examiner review and independent
modelling; no clustering result is contained in it.

The principal groups are:

- source-led practice-month alignment tables;
- coverage-preserving multichannel practice-months;
- matched two-source and three-source cohorts;
- annual core and CBT sensitivity profiles;
- compact modelling matrices with the practice code retained only for traceability;
- supplementary OCS/CBT temporal features.

No clustering results are contained here.
