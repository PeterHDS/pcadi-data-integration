# Examiner guide

Begin with the question-to-output map in
`docs/analytical-designs/README.md`. It states the retained population, grain,
appropriate use and limitation before any result is reviewed.

## Fastest review

Double-click `RUN_DEMO.cmd`. The command uses deterministic synthetic data,
executes the same portable SQL used for custom periods and creates
`work/demo_3_months/outputs/run_report.json` plus an evidence table containing
the test, expected result, observed result, status and interpretation.

Three months is used only to keep the first review small. The configurable
practice-month pipeline accepts any positive number of consecutive months. The
fixed twelve-month dissertation release is reviewed separately below.

Then run `RUN_REFERENCE_VALIDATION.cmd`. It independently recalculates SHA-256
checksums for the 14 frozen reference outputs without requiring the large source
databases.

## What establishes reproducibility

- complete ordered SQL in `sql/portable/` and `sql/core_pipeline/`;
- exact source and output contracts;
- a selected-vintage row for every source observation month;
- source-specific aggregation before joins;
- explicit join cardinality and reconciliation gates;
- deterministic output ordering and checksums;
- a synthetic clean-room run independent of the dissertation files;
- a frozen April 2025-March 2026 evidence release.

The main dissertation matrix contains 6,067 unique practices, one traceability
identifier and 13 numerical features. Clustering is deliberately outside this
repository.
