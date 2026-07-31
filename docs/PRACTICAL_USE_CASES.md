# Practical use cases

This page maps common tasks to the required source files, analytical design, command or SQL entry point, output and validation evidence. Synthetic runs demonstrate execution; official-period runs require the corresponding official source files and provenance records.

## Audit source coverage before analysis

| Item | Guidance |
|---|---|
| User goal | Establish which practices and months report to OCS, GPAD and CBT |
| Required files | Prepared OCS, GPAD and CBT practice-month CSVs plus source provenance |
| Design | Coverage-preserving OCS, GPAD and CBT practice-month spine |
| Entry point | `python automation/pipeline_cli.py run ...`; SQL in `sql/portable/02_build_practice_month_designs.sql` |
| Output | `multichannel_practice_month_coverage` and `source_month_coverage.csv` |
| Validation | Key uniqueness, source-presence flags, month coverage and cardinality gates in `pipeline_validation_results.csv` |
| Interpretation | Reporting availability and overlap across the three publication families |

## Compare online consultation and appointment activity

| Item | Guidance |
|---|---|
| User goal | Compare OCS submissions and GPAD appointments on common practice-month keys |
| Required files | Prepared OCS and GPAD practice-month CSVs, registered-patient denominators and provenance |
| Design | Matched online consultation and appointment activity |
| Entry point | `sql/portable/02_build_practice_month_designs.sql` |
| Output | `matched_online_and_scheduled_activity` |
| Validation | One row per practice-month, matched-key counts, source totals and row-multiplication checks |
| Interpretation | Separate recorded OCS and GPAD measures within their common reporting population |

## Create a complete annual practice matrix

| Item | Guidance |
|---|---|
| User goal | Produce one annual row per practice from twelve complete eligible months |
| Required files | Prepared OCS, GPAD, registered-patient and provenance CSVs for exactly twelve months |
| Design | National annual OCS-GPAD access-activity matrix |
| Entry point | `sql/portable/03_build_annual_practice_profiles.sql` |
| Output | `annual_practice_access_modelling_matrix.csv`; reference contract: `outputs/primary_practice_access_clustering_matrix.csv` |
| Validation | Twelve-month completeness, identifier uniqueness, finite numerical values, feature ranges and checksum |
| Interpretation | Annual recorded online-consultation and appointment activity configuration for eligible practices |

## Examine CBT evidence in restricted matched cohorts

| Item | Guidance |
|---|---|
| User goal | Extend the annual profile with inbound telephony or supported CBT outcomes |
| Required files | Eligible annual OCS-GPAD parent table plus prepared CBT records and provenance |
| Design | CBT inbound restricted-cohort matrix or CBT outcome-complete restricted-cohort matrix |
| Entry point | `sql/portable/04_build_telephony_sensitivity_profiles.sql` |
| Output | `inbound_telephony_sensitivity_modelling_matrix.csv` or `telephony_outcome_sensitivity_modelling_matrix.csv` |
| Validation | Parent-cohort nesting, inherited-value equality, CBT eligibility, finite values and output checksums |
| Interpretation | Telephony evidence within explicitly restricted reporting populations |

## Build a selected observation period

| Item | Guidance |
|---|---|
| User goal | Build a one-, three-, six-, twelve-, twenty-four- or other consecutive-month practice-month panel |
| Required files | Compatible official OCS, GPAD, CBT and registered-patient files for the selected period |
| Design | Source-led, coverage or matched practice-month design selected from the [analytical design index](analytical-designs/README.md) |
| Entry point | `make-config`, `data-checklist` and `run` commands in `automation/pipeline_cli.py` |
| Output | Period-specific practice-month tables, manifests and validation results |
| Validation | Exact month bounds, selected source ownership, unique keys, source totals and mandatory SQL gates |
| Interpretation | Recorded activity and coverage across the configured compatible period |

Create the period controls first:

```powershell
python automation/pipeline_cli.py make-config --start 2026-03 --months 6 --output configs/my_period.json
python automation/pipeline_cli.py data-checklist --config configs/my_period.json --output work/my_period_checklist.csv
```

## Validate a published reference output

| Item | Guidance |
|---|---|
| User goal | Confirm that local reference files match the published analytical contracts |
| Required files | Repository checkout and access to the period-labelled GitHub release for any release-only CSVs |
| Design | Reference-output validation |
| Entry point | `RUN_REFERENCE_VALIDATION.cmd` or `python automation/pipeline_cli.py validate-reference --restore-missing ...` |
| Output | `reference_validation.csv` |
| Validation | Fourteen filenames, byte sizes, schemas, row counts and SHA-256 checksums |
| Interpretation | Byte-level agreement with the registered April 2025 to March 2026 outputs |

## Prepare inputs for downstream analysis

| Item | Guidance |
|---|---|
| User goal | Use a validated matrix for clustering, descriptive analysis or external context linkage |
| Required files | A selected matrix, its manifest, feature dictionary, cohort definition and validation report |
| Design | Annual matrix matching the evidence requirement |
| Entry point | Inspect `outputs/`, `validation/` and `reference-release/documentation/` |
| Output | Traceable practice identifier plus numerical analytical features |
| Validation | Identifier uniqueness, finite values, feature definitions, population contract and fingerprint |
| Interpretation | Validated input data; later methods supply their own modelling, association and uncertainty contracts |
