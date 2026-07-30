# Scenario 7, 7A, 7B and 7C OCS other/unknown lineage audit

Audit date: 19 July 2026  
Mode: read-only forensic review  
Primary period: April 2025 to March 2026  
Primary matrix: `booking_delay_correction/04_OUTPUTS/primary_practice_access_clustering_matrix.csv`

## A. Executive verdict

### Direct answer

The original NHS England OCS data does contain an explicit other/unknown request-type measure. In the selected May 2026 publication files its metric code is `OC_SUBMISSION_TYPE_OTHER`. The official local metadata defines it as "Other/unknown type submissions received by GP practice". NHS England's supporting information also states that submissions are broken down into clinical, administrative and other/unknown, and that suppliers unable to provide submission type place those submissions in other/unknown.

The pipeline did not lose this measure. It:

1. read `OC_SUBMISSION_TYPE_OTHER` from the official CSVs;
2. renamed it `ocs_other_unknown_submissions` at practice-month aggregation;
3. retained and summed it in Scenario 7 and Scenario 7A;
4. calculated `ocs_other_unknown_share` from annual counts;
5. retained the count and share in the wide annual Scenario 7A, 7B and 7C tables; and
6. omitted the explicit share only from the narrow modelling matrices.

In the final 6,067-practice matrix, other/unknown is therefore **implicitly encoded as an exact residual**:

```text
ocs_other_unknown_share
  = 1 - ocs_clinical_share - ocs_administrative_share
```

The maximum absolute disagreement between this residual and the explicitly retained annual `ocs_other_unknown_share` is `1.27e-16`, which is floating-point precision only.

### The 323 practices

The 323 positive-rate practices with both selected OCS shares equal to zero are not the product of missing values being changed to zero. All 323:

- are present in the official selected OCS evidence series;
- have 12 observed OCS months;
- have 12 months containing total, clinical, administrative and other metrics;
- have explicit source zeros for clinical and administrative submissions;
- have explicit `OC_SUBMISSION_TYPE_OTHER` counts equal to total submissions;
- have annual `ocs_other_unknown_share = 1`; and
- reconcile exactly, with no unexplained count difference.

Together they contain 6,372,615 recorded OCS submissions, all explicitly classified as other/unknown in the source. The observations are technically valid published records. Their clinical versus administrative mix is not informative. NHS England warns that other/unknown includes submissions from suppliers unable to provide submission type, so this pattern can reflect supplier and classification capability rather than a substantive request mix.

### Pipeline and modelling disposition

Scenario 7A behaved as implemented. No OCS category was accidentally dropped by a pivot, join, aggregation or zero-fill. Scenario 7B and Scenario 7C inherit the same OCS values exactly.

The 6,067-practice matrix does not require a data-engineering rebuild for this issue. It remains usable for descriptive clustering of recorded activity, but the OCS type shares require prespecified sensitivity analysis because they can encode classification-system effects. The appropriate disposition is:

> **Proceed, but require prespecified sensitivity analyses.**

Before GMM or further clustering is interpreted, the modelling protocol should require a same-cohort sensitivity run excluding both OCS type-share features. A secondary compositional analysis may also be justified. Adding the other/unknown share directly to the current two raw shares is not recommended because the three values sum exactly to one and would be linearly dependent.

No clustering was run and no production data, SQL, database table or existing output was changed during this audit.

## B. Question and verdict table

| Question | Direct finding | Status | Evidence | Confidence | Analytical implication |
|---|---|---|---|---|---|
| Does the official OCS source contain other/unknown? | Yes. `OC_SUBMISSION_TYPE_OTHER` is an explicit numeric source metric. | Confirmed | Local official metadata `OCVC_Metadata_2024.xlsx`, `Metric Descriptions!B17:C17`; official NHS supporting information | High | Other/unknown is not a researcher-invented residual category. |
| Where did it go in Scenario 7A? | It remains in the wide annual table as count and share, then is omitted from the narrow modelling selection. | Confirmed | `sql/core_pipeline/05_aggregate_online_consultation_activity.sql:44-52`; `09_construct_annual_features_and_cohort.sql:93-148,267-285`; `10_create_primary_clustering_matrix.sql:38-56` | High | The final matrix still encodes it as the exact residual of the two retained shares. |
| Was it lost in a join? | No. It is selected into the practice-month integration and annual source-first tables. | Confirmed | `sql/core_pipeline/08_integrate_practice_month_sources.sql:35-76`; join audit below | High | No OCS correction is needed. |
| Were clinical/admin missing values converted to zero for the 323? | No. The source contains numeric zero rows for both metrics in all 3,876 affected practice-months. | Confirmed | Read-only raw-metric reconciliation query | High | The zeros mean no submissions were recorded in those classifications, not no OCS activity. |
| Are the 323 valid observations? | They are valid published records with explicit other/unknown activity, but their request-type composition is classification-limited. | Confirmed for values; inferred for practice-level cause | Source reconciliation and NHS England data-quality guidance | High for values; medium for exact cause | Treat them as recorded activity, not as evidence that every request was substantively "other". |
| Did Scenario 7A multiply rows? | No. All material practice-month and annual keys are unique; multiplication factor is 1.0. | Confirmed | Database cardinality queries and unique indexes | High | Join mechanics do not explain the 323 pattern. |
| Are Scenario 7B and 7C affected? | They inherit the same OCS fields. There are 146 affected practices in 7B and 31 in 7C. | Confirmed | Corrected database comparisons; `scenario_07_remediation/sql/08_create_scenario_07a_core.sql:11-14` | High | The same interpretation and sensitivity requirement applies. |
| Must the matrix be rebuilt before modelling? | No for data correctness. Documentation and sensitivity specifications are required before interpretation. | Analytical recommendation | Full audit | High | Preserve the authoritative matrix, then test robustness on the same practices without the two OCS type shares. |

## C. Scenario 1 to 8 inventory

The numbered names below are historical internal implementation names. The current public repository presents question-led analytical designs, but the historical SQL remains the clearest executable evidence of the original alternatives.

| Scenario | Authoritative implementation | Inputs | Grain and key | Join/order and missingness rule | Observed size | Output or status | Relevance to the 6,067 matrix |
|---|---|---|---|---|---:|---|---|
| 1, OCS-led coverage | `../sql_join_experiment/sql/10_scenario_01_ocs_left_gpad.sql:3-12` | OCS, GPAD | Practice-month; practice code + month | OCS left join GPAD; preserves OCS-only keys; no absent GPAD value becomes zero | 74,195 rows; 6,210 practices | `scenario_01_ocs_left_gpad` | Coverage evidence only; not the annual matrix source |
| 2, GPAD-led coverage | `../sql_join_experiment/sql/11_scenario_02_gpad_left_ocs.sql:3-12` | GPAD, OCS | Practice-month; practice code + month | GPAD left join OCS; preserves GPAD keys | 73,833 rows; 6,184 practices | `scenario_02_gpad_left_ocs` | Coverage evidence only |
| 3, multichannel union spine | `../sql_join_experiment/sql/12_scenario_03_union_spine_three_source.sql:3-16` | OCS, GPAD, CBT | Practice-month; practice code + month | Union-derived spine followed by three left joins; source-presence flags distinguish absence from zero | 74,195 rows; 6,210 practices | `scenario_03_union_spine_three_source` | Preferred coverage and provenance structure; Scenario 7A is derived from the same prepared source blocks, not by summing Scenario 3 fields |
| 4, OCS-GPAD complete case | `../sql_join_experiment/sql/13_scenario_04_ocs_gpad_complete_case.sql:3-5` | OCS, GPAD | Practice-month | Filters Scenario 3 to `has_ocs=1 AND has_gpad=1` | 73,833 rows; 6,184 practices | `scenario_04_ocs_gpad_complete_case` | Monthly matched cohort evidence; not the final annual selection |
| 5, three-source complete case | `../sql_join_experiment/sql/14_scenario_05_three_way_complete_case.sql:3-6` | OCS, GPAD, CBT | Practice-month | Requires all three sources and valid CBT mapping; missing activity is not imputed | 50,152 rows; 4,985 practices | `scenario_05_three_way_complete_case` | CBT sensitivity population only |
| 6, paired CBT comparison | `../sql_join_experiment/sql/15_scenario_06_cbt_matched_comparison.sql:2-22` | OCS, GPAD, CBT | Practice-month | Creates OCS-GPAD-only and OCS-GPAD-CBT tables on identical CBT-observed keys | 50,152 rows; 4,985 practices in each | Two paired Scenario 6 tables | Tests added CBT information without changing the compared cohort |
| 7, common-window annual | `../sql_join_experiment/sql/16_scenario_07_common_window_annual.sql:3-59` | OCS, GPAD, CBT annual blocks | One row per practice | Source-first annual aggregation, then join with coverage flags; original 12-month OCS-GPAD table had 6,130 before the positive OCS-total rule | 6,210 all-coverage; 6,130 12m OCS-GPAD; 3,042 original 12m three-source | Scenario 7 annual tables | Parent design for later remediated Scenario 7A, 7B and 7C |
| 7A, corrected OCS-GPAD annual core | `sql/core_pipeline/09_construct_annual_features_and_cohort.sql:93-155,243-369`; historical remediation at `../scenario_07_remediation/sql/08_create_scenario_07a_core.sql:7-10` | OCS, GPAD, monthly OCS registered-patient denominator | One row per practice | Annual source blocks inner-joined on practice; requires 12 OCS months, 12 GPAD months, 12 positive denominators, reconciled categories, positive annual OCS and GPAD totals, and complete features | 6,067 practices | `annual_practice_access_core`; primary 14-feature CSV | Direct authoritative lineage for the primary matrix |
| 7B, CBT inbound sensitivity | `sql/portable/04_build_telephony_sensitivity_profiles.sql:38-81`; historical remediation at `../scenario_07_remediation/sql/08_create_scenario_07a_core.sql:11-12` | Scenario 7A plus CBT inbound | One row per practice | Inner join to 12-month valid mapped CBT inbound evidence | 3,020 practices | CBT inbound wide table and 17-feature matrix | Inherits Scenario 7A OCS values exactly; 146 other-only practices |
| 7C, CBT outcomes sensitivity | `sql/portable/04_build_telephony_sensitivity_profiles.sql:83-132`; historical remediation at `../scenario_07_remediation/sql/08_create_scenario_07a_core.sql:13-14` | Scenario 7B plus complete CBT outcomes | One row per practice | Requires complete valid CBT outcome measures and excludes integrity-gap rows | 1,456 practices | CBT outcomes wide table and 21-feature matrix | Inherits Scenario 7A OCS values exactly; 31 other-only practices |
| 8, temporal OCS-CBT | Original status: `../sql_join_experiment/sql/17_scenario_08_optional_day_time.sql:2-5`; later recovery: `../scenario_08_recovery/SCENARIO_08_FULL_SQL.sql` | OCS and CBT day/time | Practice-month-weekday-common time bucket, then practice features | Original run correctly stopped when 12-month OCS day/time evidence was not established. Later recovery used a separate database and conditional sensitivity verdict. | Later feature table: 6,152 practices | Separate Scenario 8 recovery outputs | No contribution to 7A, 7B or 7C and no bearing on the OCS request-type residual |

All Scenario 1 to 7 practice-month joins use standardised practice code plus reporting month. The annual Scenario 7 branches join one-row-per-practice source blocks on standardised practice code. No scenario adds OCS submissions to GPAD appointments or CBT calls.

## D. Scenario 7A flow

### Authoritative artifact resolution

Several valid copies represent different points in the project history. The final modelling artifact for this audit is the corrected 14-feature CSV in `../booking_delay_correction/04_OUTPUTS`, not the earlier 13-feature combined-booking matrix still present in some repository outputs and database snapshots. The correction bundle is authoritative because it contains the separate official 1-day and 2-to-7-day features, 6,067 practices and the final checksum recorded above.

The 6.66 GB clean-build database in `work/reference-build` remains the strongest row-level source and join evidence because it contains the selected raw OCS tables and every prepared OCS stage. Its narrow matrix predates the booking-feature correction. This does not compromise the OCS audit: all eight audited OCS annual fields match the corrected annual core for all 6,067 practices with zero mismatches. The booking correction therefore changes GPAD feature presentation, not OCS lineage or cohort membership.

The historical `scenario_07_remediation` SQL establishes the original 7A, 7B and 7C parent-child design. The current `sql/core_pipeline` and `sql/portable` files are the public reproducible implementations. Where names differ, the executable grain, cohort and OCS values agree.

1. **Official OCS evidence series.** Two CSV members from the May 2026 publication vintage are frozen by hash. The analysis filters them to April 2025 through March 2026. The source uses a long metric/value layout.
2. **Raw import.** The two regional members contain 1,058,445 rows across the full publication file. Stage 02 retains 667,755 rows in the fixed 12-month window, exactly 9 metrics for each of 74,195 practice-months. See `sql/core_pipeline/02_standardise_source_data.sql:34-103`.
3. **OCS practice-month aggregation.** Stage 05 conditionally aggregates total, clinical, administrative and other counts to one row per practice-month. It preserves supplier strings, participation and source-row counts. See `sql/core_pipeline/05_aggregate_online_consultation_activity.sql:35-70`.
4. **GPAD preparation.** GPAD appointment-detail rows are independently classified and aggregated to one row per practice-month. Exact booking bands are mutually exclusive. See `sql/core_pipeline/06_aggregate_appointment_activity.sql:36-135`.
5. **Denominator.** `PATIENTS_REGISTERED` from the same OCS evidence series is validated to one positive, unconflicted value per practice-month. Annual exposure is the sum of the 12 monthly list sizes. See `sql/core_pipeline/04_construct_registered_population_denominators.sql`.
6. **Join audit.** Before integration, OCS has 74,195 unique keys, GPAD has 73,833 and the denominator has 74,195. There are 362 OCS-only keys, zero GPAD-only keys and no denominator gaps. Expected matched keys are 73,833.
7. **Practice-month integration.** The three unique blocks are inner-joined on practice code plus month. Output is 73,833 rows, 73,833 keys, multiplication factor 1.0. Other/unknown is selected explicitly at `sql/core_pipeline/08_integrate_practice_month_sources.sql:44-48`.
8. **Source-first annual aggregation.** Stage 09 independently sums OCS counts and registered-patient exposure. Shares are ratios of pooled annual components, not averages of monthly shares. Other/unknown is retained. See `sql/core_pipeline/09_construct_annual_features_and_cohort.sql:93-155`.
9. **Eligibility.** The candidate join has 6,130 unique practices. Sixty-three with zero annual OCS activity are excluded because OCS shares would be undefined. The eligible table has 6,067 unique practices. See `sql/core_pipeline/09_construct_annual_features_and_cohort.sql:243-369`.
10. **Narrow modelling export.** Stage 10 selects practice code and 14 numeric features. It includes clinical and administrative shares but does not select the explicit other/unknown share. See `sql/core_pipeline/10_create_primary_clustering_matrix.sql:38-56`.
11. **Corrected authoritative output.** The final CSV has 6,067 data rows, 15 columns and SHA-256 `C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF`.

## E. Feature lineage

All annual rates use pooled counts divided by the sum of 12 monthly registered-patient counts. All annual shares use pooled annual component counts divided by the relevant pooled annual source total. No later Python step recalculates the authoritative CSV.

| Final feature | Raw source fields | Formula and time aggregation | NULL and zero rule | Filters | Code evidence |
|---|---|---|---|---|---|
| `ocs_submissions_per_1000_patient_months` | OCS `OC_TOTAL_SUBMISSIONS`; `PATIENTS_REGISTERED` | `1000 * SUM(total) / SUM(registered_patients)` across 12 months | Undefined denominator remains NULL; positive denominator required; reported total zero retained until annual eligibility | 12 OCS months and 12 positive denominators; positive annual OCS total | `09_construct_annual_features_and_cohort.sql:95-150` |
| `ocs_clinical_share` | `OC_SUBMISSION_TYPE_CLINICAL`; `OC_TOTAL_SUBMISSIONS` | `SUM(clinical) / SUM(total)` | Source zero is retained; absent component stays NULL and fails component completeness | 12 complete component months; annual total positive | Same file `:121-150,243-262` |
| `ocs_administrative_share` | `OC_SUBMISSION_TYPE_ADMIN`; `OC_TOTAL_SUBMISSIONS` | `SUM(admin) / SUM(total)` | Same as clinical | Same as clinical | Same file `:121-150,243-262` |
| `gpad_appointments_per_1000_patient_months` | `COUNT_OF_APPOINTMENTS`; OCS `PATIENTS_REGISTERED` | `1000 * SUM(appointments) / SUM(registered_patients)` | Null appointment rows are audited and excluded by eligibility; no activity imputation | 12 GPAD months, 12 positive denominators, positive annual GPAD total | `06_aggregate_appointment_activity.sql:82-109`; `09_construct_annual_features_and_cohort.sql:180-238` |
| `gpad_dna_share` | `APPT_STATUS='DNA'`; `COUNT_OF_APPOINTMENTS` | Annual DNA / annual GPAD total | Source classification is explicit; annual total positive | Status family must reconcile | `06_aggregate_appointment_activity.sql:47,56-60,91-94`; Stage 09 `:185-235` |
| `gpad_face_to_face_share` | `APPT_MODE='FACE-TO-FACE'` | Annual face-to-face / annual GPAD total | Unknown and other modes remain separate upstream | Mode family must reconcile | `06_aggregate_appointment_activity.sql:61-68,95-100`; Stage 09 `:189-235` |
| `gpad_telephone_share` | `APPT_MODE='TELEPHONE'` | Annual telephone / annual GPAD total | Same mode rules | Mode family must reconcile | Same files |
| `gpad_same_day_share` | `TIME_BETWEEN_BOOK_AND_APPT='SAME DAY'` | Annual exact same-day count / annual GPAD total | Exact source label; no overlap | Booking family must reconcile | `06_aggregate_appointment_activity.sql:69-79,101-109`; Stage 09 `:195-224` |
| `gpad_1_day_share` | `TIME_BETWEEN_BOOK_AND_APPT='1 DAY'` | Annual exact one-day count / annual GPAD total | Exact source label; no overlap | Booking family must reconcile | Same files |
| `gpad_2_to_7_days_share` | `TIME_BETWEEN_BOOK_AND_APPT='2 TO 7 DAYS'` | Annual exact 2-to-7-day count / annual GPAD total | Exact source label; no overlap | Booking family must reconcile | Same files |
| `gpad_8_to_14_days_share` | `TIME_BETWEEN_BOOK_AND_APPT='8  TO 14 DAYS'` | Annual 8-to-14-day count / annual GPAD total | Exact normalised source label | Booking family must reconcile | Same files |
| `gpad_over_14_days_share` | 15-to-21, 22-to-28 and more-than-28-day labels | Sum of three annual component counts / annual GPAD total | Unknown/data-issue and other are excluded from this derived band but retained upstream | Booking family must reconcile | `09_construct_annual_features_and_cohort.sql:199-224` |
| `ocs_mean_absolute_monthly_rate_change` | Monthly OCS total and monthly registered patients | Mean of 11 absolute differences between adjacent monthly OCS rates | Missing monthly rate is not zero; 12 valid denominator months required | Complete OCS window | Stage 09 `:95-150` |
| `gpad_mean_absolute_monthly_rate_change` | Monthly GPAD total and monthly registered patients | Mean of 11 absolute differences between adjacent monthly GPAD rates | Missing monthly rate is not zero; 12 valid denominator months required | Complete GPAD window | Stage 09 `:159-238` |

The practice identifier remains attached only for traceability and must not enter numerical clustering.

## F. OCS category reconciliation

### Official and local source fields

The locally retained official metadata workbook defines the four relevant source metrics:

| Metric code | Official local metadata definition |
|---|---|
| `OC_TOTAL_SUBMISSIONS` | Total OC submissions received by GP practice |
| `OC_SUBMISSION_TYPE_CLINICAL` | Clinical OC submissions received by GP practice |
| `OC_SUBMISSION_TYPE_ADMIN` | Administrative OC submissions received by practice |
| `OC_SUBMISSION_TYPE_OTHER` | Other/unknown type submissions received by GP practice |

Evidence: `../sql_join_experiment/selected_release/may_2026_evidence_series/metadata/OCVC_Metadata_2024.xlsx`, worksheet `Metric Descriptions`, cells `B15:C18`.

The selected source members and checksums are:

| File | Rows | SHA-256 |
|---|---:|---|
| `Submissions via OC Systems in General Practice - May 2026_north_regions.csv` | 532,746 | `993FEF04210D036742373EFC04604AFD484E2F670DA77416E5D6EBC26586E644` |
| `Submissions via OC Systems in General Practice - May 2026_south_regions.csv` | 525,699 | `3066E492DABFCBBB1880F6D2C21B433BE01D4D14DB9084537F15E87C06A0AC58` |

The May 2026 publication is the file vintage. May 2026 observations do not enter the model. Stage 02 restricts observations to April 2025 through March 2026.

### Quantitative reconciliation

| Grain | Records or groups | Total | Clinical | Administrative | Other/unknown | Null component groups | Discrepancies | Maximum absolute difference |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Raw long data pivoted at practice-month-supplier | 74,195 | 87,794,615 | 56,948,867 | 21,709,096 | 9,136,652 | 0 | 0 | 0 |
| Prepared OCS practice-month | 74,195 | 87,794,615 | 56,948,867 | 21,709,096 | 9,136,652 | 0 | 0 | 0 |
| Annual OCS, all 6,210 practices | 6,210 | 87,794,615 | 56,948,867 | 21,709,096 | 9,136,652 | 0 incomplete annual component sets | 0 | 0 |
| Final Scenario 7A cohort | 6,067 | 87,645,955 | 56,855,534 | 21,682,580 | 9,107,841 | 0 | 0 | 0 |

Every raw pivot group has exactly nine expected OCS metrics. There are no duplicate practice-month-supplier-metric keys in the selected analytical window.

### Share accounting in the final cohort

| Result | Practices |
|---|---:|
| Clinical + administrative share approximately 1 | 5,263 |
| Clinical + administrative share below 1 | 804 |
| Clinical + administrative share above 1 | 0 |
| Positive explicit other/unknown share | 804 |
| Both clinical and administrative shares equal zero | 323 |
| Explicit other/unknown share equals 1 | 323 |

Both selected shares use annual total OCS submissions as denominator, so the denominator includes other/unknown. The residual is mathematically exact in this cohort because component reconciliation is an eligibility condition.

Semantically, it is not a pure "other" request category. NHS England defines the published component as other/unknown and explicitly states that submissions from suppliers unable to provide submission type are placed there. The residual can therefore combine substantive other requests, unclassified requests and supplier reporting limitations.

### Fate verdict

- In the official source: **explicitly retained** as `OC_SUBMISSION_TYPE_OTHER`.
- In prepared and wide annual Scenario 7A, 7B and 7C tables: **explicitly retained** as count and share.
- In the narrow modelling matrices: **implicitly encoded as an exact residual** and intentionally excluded by the feature-selection list.
- There is no evidence of accidental loss, zero imputation or irrecoverability.

The implementation selects two of the three dependent raw shares. Current documentation calls other/unknown a residual. No original contemporaneous comment was found that records why that particular component was omitted. The later pre-clustering governance review supplies a defensible modelling reason: directly adding all three raw shares would create exact linear dependence.

## G. Audit of the 323 practices

### Source and lineage reconciliation

| Test | Observed result | Verdict |
|---|---:|---|
| Practices identified independently from the corrected 14-feature matrix | 323 | Confirmed |
| Present in annual Scenario 7A core | 323 | Confirmed |
| Practice-month source rows | 3,876, exactly 12 per practice | Confirmed |
| Months with all four OCS count metrics | 3,876 | Confirmed |
| Practice-months with clinical = 0 and admin = 0 | 3,876 | Confirmed |
| Practice-months with other = total | 3,876 | Confirmed |
| Positive-total practice-months | 3,548 | Confirmed |
| Zero-total practice-months | 328 | Confirmed |
| Annual total submissions | 6,372,615 | Confirmed |
| Annual other/unknown submissions | 6,372,615 | Confirmed |
| Annual clinical submissions | 0 | Confirmed |
| Annual administrative submissions | 0 | Confirmed |
| Annual reconciliation failures | 0 | Confirmed |

Positive observed months per practice are distributed as follows:

| Positive months | Practices |
|---:|---:|
| 12 | 279 |
| 11 | 2 |
| 10 | 2 |
| 8 | 1 |
| 6 | 1 |
| 4 | 34 |
| 3 | 1 |
| 2 | 2 |
| 1 | 1 |

All 323 still have a present source row and a complete component set in every month. A month with a published total of zero remains an observed zero month, not a manufactured zero for an absent record. NHS England cautions that a zero-submission month may reflect system availability or no completed submissions and should not be interpreted as zero underlying demand.

### Supplier pattern

The 323 are highly concentrated in supplier patterns whose published counts are wholly other/unknown:

- 162 practices report only `EVERGREEN HEALTH SOLUTIONS` across the window.
- 112 report only `SILICON PRACTICE LTD`.
- 32 alternate between `Blinx Healthcare` and `No data`.
- 17 have smaller mixed patterns involving those suppliers, `No Data`, Engage Health Systems or Continuum.

At affected practice-month level, positive activity occurs under Evergreen, Silicon, Blinx or a small number of combined supplier labels, and every positive count remains wholly other/unknown. The 328 `No data` or `No Data` affected practice-months all have total zero.

NHS England's official explanation supports a supplier/classification-capability interpretation, but the local data does not identify the exact technical reason for every practice. The strongest defensible conclusion is:

- **Confirmed:** the condition exists in official source values and is not created downstream.
- **Confirmed:** all activity is explicitly classified in the published other/unknown component.
- **Inferred:** supplier capability or supplier-specific implementation is the principal explanation for the concentration.
- **Unresolved:** whether an individual submission is substantively "other" or merely unclassifiable cannot be separated in this release.

Four additional upstream practices have the same positive-total, clinical-zero, administrative-zero condition but are excluded before Scenario 7A because they have only 4, 5, 7 or 8 observed OCS months. They are `C81074`, `L84069`, `L85010` and `P87651`. Their exclusion is a documented 12-month coverage rule, not a category-related join loss.

### Minor audit-flag limitation

`ocs_unknown_supplier_flag` flags blank, `NONE`, `UNKNOWN` and `NONE/UNKNOWN` at `sql/core_pipeline/05_aggregate_online_consultation_activity.sql:58-63`. It does not normalise `No data` or `No Data` to the same audit state. This does not change OCS counts, shares, eligibility or the final matrix because the flag is not a final Scenario 7A feature. It does mean that the upstream unknown-supplier audit flag is narrower than the supplier text actually observed. This is a documentation or future-audit improvement, not a reason to rebuild the current matrix.

## H. Join-integrity findings

| Checkpoint | Rows | Unique keys | Duplicate keys | Finding |
|---|---:|---:|---:|---|
| Standardised OCS detail, natural source key | 667,755 | 667,755 | 0 | No hidden source-key duplication |
| OCS practice-month | 74,195 | 74,195 | 0 | Unique before joining |
| GPAD practice-month | 73,833 | 73,833 | 0 | Unique before joining |
| Registered population practice-month | 74,195 | 74,195 | 0 | Unique before joining |
| Integrated practice-month panel | 73,833 | 73,833 | 0 | Expected matched-key count; multiplication factor 1.0 |
| Annual OCS | 6,210 | 6,210 | 0 | One row per practice |
| Annual GPAD | 6,184 | 6,184 | 0 | One row per practice |
| Annual denominator audit | 6,210 | 6,210 | 0 | One row per practice |
| Candidate annual join | 6,130 | 6,130 | 0 | No annual multiplication |
| Eligible annual Scenario 7A | 6,067 | 6,067 | 0 | One row per practice |

There are 362 OCS practice-months without GPAD, zero GPAD practice-months without OCS, and no denominator gaps among either prepared source. These counts are explicit in `practice_month_join_cardinality_audit`. The integrated inner join loses the 362 OCS-only keys by design, but final annual OCS features are calculated from the source-specific OCS table and the final cohort separately requires 12 months from each source. No affected final practice loses an OCS month.

Independent comparison found zero OCS-value mismatches between:

- the clean-build `eligible_annual_practice_features` table;
- the corrected `annual_practice_access_core` table; and
- the OCS fields copied into the Scenario 7B and 7C wide tables.

The booking-delay correction changed GPAD feature selection only. It did not change practice membership or any OCS value.

## I. Analytical decision

### Provisional disposition

**Proceed, but require prespecified sensitivity analyses.**

This conclusion separates engineering correctness from modelling usefulness:

- **Engineering:** solid and correctly implemented. Other/unknown is explicit in source and wide lineage, all components reconcile, no zero-fill or row multiplication created the pattern, and the final residual is exact.
- **Primary descriptive use:** feasible if the clusters are described as profiles of recorded OCS and GPAD activity, including supplier and recording-system effects.
- **Clinical/administrative mix interpretation for 323 practices:** analytically inappropriate. Two zero shares do not mean no online activity and should not be interpreted as a meaningful split of request types.
- **Exact practice-level cause:** unresolved beyond the published other/unknown label because the source does not separate substantive other requests from unclassified submissions.

### Required sensitivity specification

1. **Same-cohort OCS-type-free sensitivity.** Retain all 6,067 practices and all non-OCS-type features, but omit both `ocs_clinical_share` and `ocs_administrative_share`. Compare assignments and substantive interpretation with the primary result. This tests whether supplier classification geometry drives the solution without changing the cohort.
2. **Complete-composition sensitivity.** If OCS composition is substantively important, derive clinical, administrative and other/unknown from the wide annual core and apply a defensible compositional approach such as an isometric log-ratio transformation. A zero-handling rule must be stated before modelling.
3. **Classification-completeness cohort sensitivity.** A secondary restricted cohort may test practices with complete clinical/admin classification, but it must be labelled a selection sensitivity. It must not replace the national core merely because cluster metrics improve.

### Options assessed

| Option | Assessment |
|---|---|
| Retain current two shares | Defensible as the primary recorded-data specification, provided supplier/classification caveats and sensitivity tests are explicit |
| Remove both OCS shares | Best first sensitivity because it keeps the same practices and tests dependence on classification capability |
| Add a classification-completeness or residual indicator | Useful as a contextual audit variable; not automatically a modelling feature because it is derived from the two existing shares and can double-weight the same pattern |
| Add explicit other/unknown alongside both current shares | Not recommended in raw form because the three shares are exactly dependent |
| Use a compositional transformation | Methodologically solid sensitivity, but zeros require a prespecified treatment and the other/unknown component remains semantically mixed |
| Delete the 323 practices | Not supported. They are valid published records, and removal solely to improve silhouette, ARI or another clustering metric would alter the estimand without a data-quality basis |

Scenario 7B and 7C should apply the same sensitivity logic. Their smaller cohorts do not repair the OCS classification issue; they simply retain 146 and 31 of the other-only practices after CBT eligibility filters.

## J. Minimal remediation plan

No production SQL or matrix rebuild is required for the OCS other/unknown issue.

Before substantive model interpretation:

1. document that `OC_SUBMISSION_TYPE_OTHER` is the official source component and that the final matrix encodes it as a residual;
2. state that 323 primary-cohort practices are wholly other/unknown in the published source;
3. state that clinical and administrative zeros do not mean zero online activity;
4. prespecify the same-cohort sensitivity excluding both OCS type shares;
5. if used, define the complete-composition transformation and zero rule before examining results; and
6. report Scenario 7B and 7C affected counts separately.

Optional future pipeline improvement:

- extend `ocs_unknown_supplier_flag` to normalise `No data` and `No Data`, then validate that the change affects only audit context and not counts, cohort membership or modelling features.

Current documentation also contains a pre-correction wording mismatch: `reference-release/documentation/PIPELINE_METHODOLOGY.md:20` still describes 13 features and 14 columns, while the corrected primary specification has 14 features and 15 columns. Some pre-clustering files likewise describe the earlier combined 1-to-7-day representation. This does not affect the OCS other/unknown findings, but those statements should be aligned before the repository is presented as the final modelling release.

Validation conditions for any future change:

- Scenario 7A remains 6,067 unique practices;
- all OCS counts and rates remain bit-for-bit or canonical-fingerprint identical;
- the two selected OCS shares remain unchanged;
- raw, practice-month and annual category reconciliation remains zero;
- Scenario 7B remains 3,020 and Scenario 7C remains 1,456 practices; and
- no source-reported zero is converted to missing or vice versa.

## K. Reproducibility appendix

### Authoritative artifacts inspected

- `sql/core_pipeline/02_standardise_source_data.sql`
- `sql/core_pipeline/04_construct_registered_population_denominators.sql`
- `sql/core_pipeline/05_aggregate_online_consultation_activity.sql`
- `sql/core_pipeline/06_aggregate_appointment_activity.sql`
- `sql/core_pipeline/07_validate_join_cardinality.sql`
- `sql/core_pipeline/08_integrate_practice_month_sources.sql`
- `sql/core_pipeline/09_construct_annual_features_and_cohort.sql`
- `sql/core_pipeline/10_create_primary_clustering_matrix.sql`
- `sql/portable/01_create_canonical_source_tables.sql`
- `sql/portable/02_build_practice_month_designs.sql`
- `sql/portable/03_build_annual_practice_profiles.sql`
- `sql/portable/04_build_telephony_sensitivity_profiles.sql`
- `reference-release/input_manifest.csv`
- `reference-release/documentation/DATA_SOURCES.md`
- `reference-release/documentation/PIPELINE_METHODOLOGY.md`
- `reference-release/documentation/FEATURE_DICTIONARY.md`
- `pre_clustering_readiness_audit/*`
- `../sql_join_experiment/sql/10_scenario_01_ocs_left_gpad.sql` through `17_scenario_08_optional_day_time.sql`
- `../scenario_07_remediation/sql/08_create_scenario_07a_core.sql`
- `../booking_delay_correction/02_SQL/*`
- `../booking_delay_correction/04_OUTPUTS/*`
- local official metadata workbook `../sql_join_experiment/selected_release/may_2026_evidence_series/metadata/OCVC_Metadata_2024.xlsx`
- read-only SQLite databases in `work/reference-build`, `work/authoritative_release`, `../booking_delay_correction/03_DATABASE` and `../sql_join_experiment/database`

### Read-only query patterns used

```sql
-- Source metric inventory
SELECT metric, COUNT(*), COUNT(DISTINCT practice_code_standardised),
       MIN(value_numeric), MAX(value_numeric)
FROM standardised_online_consultation_activity
GROUP BY metric;

-- Raw category reconciliation after pivoting the long source
WITH p AS (
  SELECT practice_code_standardised, reporting_month, supplier,
         SUM(CASE WHEN metric='OC_TOTAL_SUBMISSIONS' THEN value_numeric END) AS total,
         SUM(CASE WHEN metric='OC_SUBMISSION_TYPE_CLINICAL' THEN value_numeric END) AS clinical,
         SUM(CASE WHEN metric='OC_SUBMISSION_TYPE_ADMIN' THEN value_numeric END) AS admin,
         SUM(CASE WHEN metric='OC_SUBMISSION_TYPE_OTHER' THEN value_numeric END) AS other
  FROM standardised_online_consultation_activity
  GROUP BY practice_code_standardised, reporting_month, supplier
)
SELECT COUNT(*),
       SUM(total IS NULL OR clinical IS NULL OR admin IS NULL OR other IS NULL),
       SUM(ABS(clinical + admin + other - total) > 0.000001),
       MAX(ABS(clinical + admin + other - total))
FROM p;

-- Independent 323-practice definition
SELECT practice_code_standardised
FROM primary_practice_access_clustering_matrix_14_features
WHERE ocs_submissions_per_1000_patient_months > 0
  AND ocs_clinical_share = 0
  AND ocs_administrative_share = 0;

-- Residual agreement
SELECT MAX(ABS(
  (1 - ocs_clinical_share - ocs_administrative_share)
  - ocs_other_unknown_share
))
FROM annual_practice_access_core;
```

CSV structure was also inspected with the project spreadsheet tooling. The authoritative matrix contains 6,068 CSV rows including its header and 15 columns. The annual core contains 6,068 CSV rows including its header and 52 columns.

### Official interpretation sources

- [NHS England Digital, Submissions via Online Consultation Systems in General Practice: Supporting Information](https://digital.nhs.uk/data-and-information/publications/statistical/submissions-via-online-consultation-systems-in-general-practice/submissions-via-online-consultation-systems-in-general-practice-supporting-information). This defines clinical, administrative and other/unknown; explains that some suppliers cannot provide submission type; and documents supplier, participation and completeness limitations.
- [NHS England Digital, Submissions via Online Consultation Systems in General Practice, May 2026](https://digital.nhs.uk/data-and-information/publications/statistical/submissions-via-online-consultation-systems-in-general-practice/may-2026). This is the selected publication vintage and identifies the practice-level resource, publication date and official-statistics-in-development status.
- [NHS England, Online consultations frequently asked questions and support resources](https://www.england.nhs.uk/long-read/online-consultations-frequently-asked-questions/). This states that clinical versus administrative classification depends on the tool and patient options and is not nationally defined.

### Unresolved evidence gaps

- The official source does not separate substantive "other" requests from unknown or unclassifiable requests within `OC_SUBMISSION_TYPE_OTHER`.
- It does not provide a practice-level reason explaining why every affected supplier/practice reports only other/unknown.
- It cannot establish whether any individual OCS submission led to a GPAD appointment or CBT call.

These gaps limit interpretation but do not undermine the audited count lineage.

## Final audit conclusion

The OCS other/unknown category was present in the original official NHS England data and was preserved correctly through Scenario 7A, 7B and 7C wide tables. It was omitted only as an explicit column from the narrow modelling matrices, where it remains exactly recoverable from the two retained shares. The 323-practice pattern is genuine published other/unknown classification, not a join error or zero-imputation error. The matrix can proceed to later modelling only with documented, prespecified sensitivity analysis for OCS classification effects.
