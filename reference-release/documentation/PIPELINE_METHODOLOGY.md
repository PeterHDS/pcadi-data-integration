# Pipeline methodology

## Analytical objective

The pipeline constructs one annual record per eligible GP practice describing two separate domains: recorded online-consultation submissions and recorded scheduled appointment activity. The fixed observation window is April 2025-March 2026. Integration occurs at practice-month before annual aggregation so that time-varying activity is matched to time-varying registered-list exposure.

## Stage specification

| Stage | What entered and at what grain? | Transformation and reason | Assumptions | Validation gate | Output |
|---|---|---|---|---|---|
| 01. Create raw source tables | Empty database; manifest definitions at file-row grain | Creates 21 explicit tables with text fields so import does not infer types or silently alter blanks | Manifest schemas are the frozen import contract | Table/header agreement; later hash and row-count gates | Raw OCS, GPAD and mapping tables |
| 02. Standardise source data | Raw supplier-metric OCS rows, GPAD appointment-detail rows and mapping rows | Unions components, trims and uppercases identifiers, normalises months, validates numeric text and converts only valid values | A valid practice code is one uppercase letter plus five digits; required months are fixed | No invalid numeric conversion or invalid code may enter aggregation | `standardised_online_consultation_activity`, `standardised_appointment_activity`, mapping reference |
| 03. Validate source integrity | Standardised detail tables | Audits manifest row counts, month coverage, exact duplicates and natural-key conflicts before aggregation | Duplicate evidence is assessed at source-appropriate keys | Exact expected file counts; 12 required months; zero invalid conversion and duplicate conflicts | Source validation and duplicate-audit tables |
| 04. Construct denominators | OCS `PATIENTS_REGISTERED` rows and mapping reference | Validates identical supplier copies and retains one positive registered-list value per practice-month; audits reference coverage | Supplier repeats for the same practice-month must agree | One positive, unconflicted denominator per retained key | `registered_population_by_practice_month`, denominator and mapping audits |
| 05. Aggregate OCS | Valid standardised OCS rows at practice-month-supplier-metric grain | Pivots selected measures and sums to one row per practice-month before any cross-source join | Total, clinical, administrative and other/unknown metrics are parallel OCS measures; absence is not zero-filled | Unique practice-month keys and component reconciliation | `online_consultation_practice_month` |
| 06. Aggregate GPAD | Valid standardised appointment-detail rows | Classifies exact status, mode and booking labels, then conditionally sums once to one row per practice-month | Breakdown families are parallel; booking bands are mutually exclusive; unknown/other remain explicit | Unique keys; status, mode and booking totals reconcile to the source total | `appointment_activity_practice_month` |
| 07. Validate join cardinality | OCS, GPAD and denominator practice-month tables | Measures matched, left-only and right-only keys and expected output size before integration | Integration must not multiply source records | Observed integrated row count must equal expected matched keys; multiplication factor 1.0 | `practice_month_join_cardinality_audit` |
| 08. Integrate practice-month sources | Three unique practice-month blocks | Inner-joins on standardised practice code and reporting month after source aggregation | The analytical panel requires observed OCS, GPAD and denominator records; missing rows are not manufactured | Unique joined keys; expected row count; no dates outside window | `integrated_practice_month_panel` |
| 09. Construct annual features and cohort | Integrated practice-month panel plus source-specific complete series | Sums annual counts and patient-month exposure, recalculates ratios from annual components, computes adjacent-month changes, applies eligibility rules | Rates use summed monthly list sizes; shares use annual components; 1-7 days is 1-day share plus 2-7-day share | Twelve months, positive denominators, reconciled categories, positive OCS total, complete feature set | Annual OCS, GPAD and denominator tables; eligibility and exclusion tables |
| 10. Create primary matrix | Eligible annual feature table | Selects the identifier plus exactly 13 prevalidated features, without imputation or feature rescaling | Identifier is traceability only | 6,067 unique practices; 14 columns; no NULL, invalid range or negative rate/change | `primary_practice_access_clustering_matrix` |
| 11. Validate complete pipeline | Raw, intermediate and final tables | Creates reconciliation, missingness, range, lineage and 36 substantive test records | Expected counts are comparison targets, not cohort-construction rules | Exactly 36 PASS and 0 FAIL | Validation tables and reports |
| 12. Order, fingerprint and export | Validated matrix | Orders by practice code and creates canonical `printf('%.17g')` lines for deterministic comparison | SQLite canonical formatting is the tested equivalence representation | 6,067 ordered canonical lines and exact fresh-run reference equality | Ordered matrix, fingerprint and export metadata |

## Key design choices

### Source aggregation precedes joining

OCS has supplier/metric detail and GPAD has crossed appointment dimensions. Directly joining those detail tables would create a many-to-many product. Each source is therefore collapsed independently to its stated practice-month grain, indexed uniquely and audited before joining.

### Month-matched patient exposure

Annual rates use `SUM(registered_patients)` across the 12 practice-months. The unit is activity per 1,000 registered patient-months. A single March list size is not substituted for the changing monthly denominator.

### Parallel activity domains

OCS submissions may or may not lead to appointments; GPAD appointments may originate through many channels. The pipeline does not link patients or events, does not add OCS and GPAD totals and does not infer substitution between channels.

### Missingness and zero

Zero values reported in present source rows remain zero. Missing files, missing rows, invalid numeric fields, non-participation and undefined ratios remain distinguishable and are not imputed. Practices with zero annual OCS submissions are excluded because OCS composition shares would be undefined, not because a target row count is required.

### Determinism

Inputs are frozen by SHA-256. SQL stage order, join keys, feature order and final row order are explicit. Export uses 17 significant digits. The independent checker compares both feature values and concatenated canonical lines to the read-only reference.

