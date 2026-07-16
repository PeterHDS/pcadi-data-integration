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

## Primary dissertation modelling input

The examiner-ready input for the main national clustering analysis is:

**[`primary_practice_access_clustering_matrix.csv`](../../outputs/primary_practice_access_clustering_matrix.csv)**

[Download the complete CSV](https://raw.githubusercontent.com/PeterHDS/pcadi-data-integration/main/outputs/primary_practice_access_clustering_matrix.csv)

This is the authoritative full-precision file included in the repository. It
contains:

- 6,067 rows, with exactly one row per practice;
- one standardised practice identifier retained for traceability;
- 13 complete numerical modelling features;
- zero duplicate or blank identifiers;
- zero missing, non-numeric or non-finite modelling values; and
- SHA-256 `97B5EDA02117F14250D712E5F265E465E165725340D415B81178E78931011444`.

The practice identifier is not a modelling feature. The CBT matrices are
smaller sensitivity-analysis cohorts and do not replace this primary national
matrix. The file is the validated input to clustering, not a clustering result,
and its values must not be replaced by a rounded display export.

The dimensions and numerical checks are recorded in
[`matrix_numeric_validation.csv`](../../validation/matrix_numeric_validation.csv),
and the deterministic file fingerprint is recorded in
[`output_register_and_checksums.csv`](../../validation/output_register_and_checksums.csv).

## What establishes reproducibility

- complete ordered SQL in `sql/portable/` and `sql/core_pipeline/`;
- exact source and output contracts;
- a selected-vintage row for every source observation month;
- source-specific aggregation before joins;
- explicit join cardinality and reconciliation gates;
- deterministic output ordering and checksums;
- a synthetic clean-room run independent of the dissertation files;
- a frozen April 2025-March 2026 evidence release.

Clustering is deliberately outside this repository.
