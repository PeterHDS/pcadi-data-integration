# Validation framework

Release is controlled by evidence-producing gates rather than by informal inspection.

| Family | Test performed | Expected result | Primary evidence |
|---|---|---|---|
| Environment | Record Python, SQLite, OS and execution timestamps | Versions present | `logs/build_log.txt`, `software_environment.txt` |
| Database integrity | `PRAGMA integrity_check` and `foreign_key_check` | `ok`; zero violations | build log |
| Source row counts | Compare every raw table with manifest | Exact for all 21 files | `logs/import_log.csv`, source validation table |
| Date coverage | Count distinct required months and outside-window rows | April 2025-March 2026 only; 12 months | pipeline validations |
| Identifier validity | Test trimmed uppercase ODS-code pattern | Zero invalid retained codes | pipeline validations |
| Numeric conversion | Validate text before cast; count failures | Zero invalid required numeric values | numeric conversion audit |
| Exact duplicates | Group on complete source-detail keys and values | Zero duplicate groups | duplicate audit |
| Natural-key duplicates | Detect conflicting values at source natural keys | Zero conflicts | duplicate audit |
| Denominators | Count missing, nonpositive and conflicting practice-month values | Zero for eligible records | denominator conflict audit |
| Practice-month uniqueness | Compare rows with distinct practice-month keys | Difference zero | key audits and validations |
| Join cardinality | Compare expected matched keys with integrated rows | Multiplication factor 1.0 | `join_cardinality_audit.csv` |
| Source reconciliation | Compare standardised-source totals with source-specific aggregates | OCS within declared precision; GPAD exactly zero difference | `source_reconciliation_summary.csv` |
| Category reconciliation | Reconcile OCS components and parallel GPAD breakdown families | All internal tests PASS | annual internal validation |
| Cohort lineage | Count source, pre-rule, exclusions and final cohort | 6,210 / 6,184 / 6,210 / 6,130 / 63 / 6,067 | eligibility and exclusion files |
| Missingness | Count SQL NULL separately from observed zero | Zero final feature NULLs | `feature_missingness_audit.csv` |
| Observed zeros | Count without treating as missing | Retained and reported | missingness audit |
| Ranges | Min/max and invalid-range counts for every feature | 13 summaries; shares 0-1; rates/changes non-negative | `feature_range_summary.csv` |
| Final completeness | One identifier plus 13 finite numeric features | 6,067 complete unique practices | final validations |
| Deterministic ordering | Compare ordered practice sequence | Exact reference order | equivalence summary |
| Canonical fingerprint | SQLite `printf('%.17g')` per feature, concatenated per practice | 6,067 exact lines | fingerprint and equivalence files |
| Fresh-run equivalence | Compare every newly built canonical practice-feature line with the frozen expectation | No changed, missing or additional lines | `expected_modelling_output_fingerprint.csv`, build log |

## Mandatory release gate

`pipeline_validation_results` must contain exactly 36 rows, all marked `PASS`. The equivalence checker then applies the stricter cross-database gate. A tolerance summary is reported for diagnosis, but tolerance agreement cannot replace required exact canonical agreement.

## Deterministic trace

Thirty practices are selected by a documented deterministic rank/quantile rule. Each selected practice is traced across all 13 final features, producing 390 practice-feature comparisons. This is a small review aid, not a substitute for the complete-table equivalence check.

## Failure behaviour

The runner returns a nonzero status and writes `BLOCKERS_AND_EXCEPTIONS.md` if a
required gate fails. A failed build must not be described or packaged as a
validated release. The blocker file is removed only by a later successful
complete run.
