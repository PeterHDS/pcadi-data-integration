# Reference-application validation

- Overall evidence verdict: **VALIDATED**
- SQL gates: 26/26 passed
- Feature dependency and preservation checks: 39/39 passed
- Numerical matrix checks: 3/3 passed
- Working database integrity: `ok`
- Clustering run: **No**

The primary annual matrix contains 6,067 unique practices, fourteen complete numerical modelling features and one traceability identifier. The published GPAD `1 day` and `2 to 7 days` bands remain separate. The CBT inbound restricted-cohort matrix contains 3,020 practices and seventeen features. The CBT outcome-complete restricted-cohort matrix contains 1,456 practices and twenty-one raw features.

The independent temporal table contains 6,152 practices and 582 documented April 2025 Y60 integrity flags.

Feature-contract evidence is retained in `booking_delay_source_to_prepared_reconciliation.csv`, `booking_delay_feature_reconciliation.csv` and `primary_14_feature_range_and_missingness.csv`.

Run `RUN_REFERENCE_VALIDATION.cmd` to recalculate all fourteen output checksums without the source databases.
