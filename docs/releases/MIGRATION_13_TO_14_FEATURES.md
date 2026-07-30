# Migration from the 13-feature to 14-feature matrix

## What changed

The first public release represented the official GPAD `1 day` and `2 to 7
days` booking bands as one combined modelling feature. The completed
dissertation analysis retained those source-defined bands separately. PCADI
v2.0.0 aligns the public interface with that authoritative specification.

The national matrix now has one identifier and fourteen numerical features.
The CBT inbound and raw outcome matrices inherit the same fourteen values and
contain seventeen and twenty-one numerical features respectively.

## How the discrepancy was identified

A manual DB Browser export was compared with the automated release output.
The cohort and common values agreed, but the public feature interface had
collapsed two source categories. The evidence review then traced the field
through annual SQL, export code, tests, documentation and checksums.

## What did not change

The verified national cohort remains 6,067 practices. The inbound and outcome
cohorts remain 3,020 and 1,456 practices. OCS and GPAD source totals, the
practice-month join architecture and the observation period did not change.

## File migration

| Superseded interface | v2.0.0 replacement |
|---|---|
| 6,067 rows, 14 total columns | `primary_practice_access_clustering_matrix.csv`, 15 total columns |
| 3,020 rows, 17 total columns | `cbt_inbound_sensitivity_clustering_matrix_17_features.csv`, 18 total columns |
| 1,456 rows, 21 total columns | `cbt_outcomes_sensitivity_clustering_matrix_21_features.csv`, 22 total columns |

Old byte hashes and replacement hashes are listed in
[`reference-release/validation/superseded_output_register.csv`](../../reference-release/validation/superseded_output_register.csv).
Superseded CSVs are no longer present in the active `outputs/` directory.

## Downstream action

Analyses using the old combined booking field should be rerun with the
fourteen-feature matrix. The exact `1 day` and `2 to 7 days` values should
remain separate in the primary specification. Any deliberate aggregation
belongs in a named downstream sensitivity analysis and must not replace the
source-defined fields silently.
