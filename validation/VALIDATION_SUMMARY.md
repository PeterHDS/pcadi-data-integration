# Frozen reference validation

- Overall evidence verdict: **VALIDATED**
- SQL gates: 26/26 passed
- Feature dependency and preservation checks: 39/39 passed
- Numerical matrix checks: 3/3 passed
- Working database integrity: `ok`
- Clustering run: **No**
- Repository publication changes no analytical values or validation verdicts.

The corrected primary annual matrix contains 6,067 unique practices and exactly fourteen
complete numerical modelling features plus one traceability identifier. The
separate GPAD 1-day and 2-to-7-day shares are retained in the primary feature
set. The corrected inbound CBT
sensitivity matrix contains 3,020 practices; the corrected CBT outcomes
sensitivity matrix contains 1,456. The independent temporal table contains
6,152 practices and 582 documented April 2025 Y60 integrity flags.

The booking-delay correction evidence is retained in
`booking_delay_correction_validation_results.csv`,
`booking_delay_source_to_prepared_reconciliation.csv`,
`booking_delay_feature_reconciliation.csv` and
`primary_14_feature_range_and_missingness.csv`.

Run `RUN_REFERENCE_VALIDATION.cmd` to recalculate all 14 output checksums without
the source databases.
