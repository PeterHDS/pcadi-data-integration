# Frozen reference outputs

These CSVs belong to the verified April 2025 to March 2026 reference application. Names describe the population or role, not access quality.

## Authoritative modelling matrices

| File | Practices | Numerical features |
|---|---:|---:|
| [`primary_practice_access_clustering_matrix.csv`](primary_practice_access_clustering_matrix.csv) | 6,067 | 14 |
| [`cbt_inbound_sensitivity_clustering_matrix_17_features.csv`](cbt_inbound_sensitivity_clustering_matrix_17_features.csv) | 3,020 | 17 |
| [`cbt_outcomes_sensitivity_clustering_matrix_21_features.csv`](cbt_outcomes_sensitivity_clustering_matrix_21_features.csv) | 1,456 | 21 |

Each first column is a traceability identifier and is excluded from numerical modelling. The GPAD `1 day` and `2 to 7 days` booking bands are separate in all three matrices.

The complete dimensions and SHA-256 hashes are in [`validation/output_register_and_checksums.csv`](../validation/output_register_and_checksums.csv). Run `RUN_REFERENCE_VALIDATION.cmd` from the repository root to verify them.

## Supporting outputs

Detailed annual tables retain counts, denominator evidence, reconciliation fields and audit-only derivatives. The temporal table preserves the April 2025 Y60 CBT integrity flag. Large practice-month outputs are retrieved from the period-labelled release asset when reference validation runs on a clean checkout.

No clustering results are stored here.
