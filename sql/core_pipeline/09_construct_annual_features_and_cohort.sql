/* ============================================================
   STAGE 09 - CONSTRUCT ANNUAL FEATURES AND COHORT

   Purpose
   Convert monthly OCS, GPAD and registered-population data into audited
   twelve-month practice features and apply explicit eligibility rules.

   Inputs
   online_consultation_practice_month,
   appointment_activity_practice_month,
   registered_population_by_practice_month.

   Outputs
   annual_population_denominator_audit,
   annual_online_consultation_features,
   annual_appointment_features,
   eligible_practices_before_activity_total_rule,
   candidate_annual_practice_features,
   analytical_cohort_exclusion_audit,
   eligible_annual_practice_features and
   annual_feature_internal_validation.

   Analytical grain
   One row per practice.

   Rationale
   Annual counts are summed from observed monthly counts. Annual rates use
   twelve month-matched registered-patient denominators (patient-months).
   Shares are ratios of annual component totals, not unweighted averages of
   monthly shares. Monthly-rate change uses consecutive observed months.

   Key assumptions
   Eligible practices require twelve OCS months, twelve GPAD months and
   twelve positive, unconflicted denominators. Source component families
   must reconcile. Zero annual OCS activity is retained in an exclusion
   audit because OCS composition shares are undefined; it is not imputed.

   Validation gate
   Unique annual practice keys; complete months; positive denominators;
   OCS, GPAD status, mode and booking reconciliation; complete finite
   analytical features after the documented activity-total rule.

   Expected result
   6,210 annual OCS practices, 6,184 annual GPAD practices, 6,210 annual
   denominator practices, 6,130 eligible before the final activity-total
   rule, 63 documented exclusions and 6,067 final practices.
   ============================================================ */

DROP TABLE IF EXISTS annual_population_denominator_audit;
CREATE TABLE annual_population_denominator_audit AS
WITH monthly AS (
    SELECT
        practice_code_standardised,
        reporting_month,
        registered_patients,
        LAG(registered_patients) OVER (
            PARTITION BY practice_code_standardised
            ORDER BY reporting_month
        ) AS previous_registered_patients
    FROM registered_population_by_practice_month
)
SELECT
    practice_code_standardised,
    COUNT(*) AS months_with_denominator,
    MIN(registered_patients) AS minimum_monthly_list_size,
    MAX(registered_patients) AS maximum_monthly_list_size,
    AVG(registered_patients) AS mean_monthly_list_size,
    SUM(registered_patients) AS annual_patient_month_exposure,
    MAX(ABS(registered_patients - previous_registered_patients)) AS maximum_absolute_monthly_change,
    MAX(
        CASE
            WHEN previous_registered_patients > 0
            THEN ABS(1.0 * (registered_patients - previous_registered_patients) / previous_registered_patients)
        END
    ) AS maximum_proportional_monthly_change,
    100.0 * MAX(
        CASE
            WHEN previous_registered_patients > 0
            THEN ABS(1.0 * (registered_patients - previous_registered_patients) / previous_registered_patients)
        END
    ) AS maximum_percentage_monthly_change,
    SUM(registered_patients IS NULL OR registered_patients <= 0) AS invalid_denominator_months,
    CASE
        WHEN SUM(registered_patients IS NULL OR registered_patients <= 0) > 0 THEN 1
        ELSE 0
    END AS implausible_denominator_flag
FROM monthly
GROUP BY practice_code_standardised;

CREATE UNIQUE INDEX ux_annual_population_denominator_audit
    ON annual_population_denominator_audit (practice_code_standardised);

DROP TABLE IF EXISTS annual_online_consultation_features;
CREATE TABLE annual_online_consultation_features AS
WITH monthly_0 AS (
    SELECT
        o.practice_code_standardised,
        o.reporting_month,
        o.ocs_total_submissions,
        o.ocs_clinical_submissions,
        o.ocs_administrative_submissions,
        o.ocs_other_unknown_submissions,
        d.registered_patients,
        CASE
            WHEN d.registered_patients > 0
            THEN 1000.0 * o.ocs_total_submissions / d.registered_patients
        END AS monthly_rate
    FROM online_consultation_practice_month AS o
    JOIN registered_population_by_practice_month AS d
        USING (practice_code_standardised, reporting_month)
),
monthly AS (
    SELECT
        *,
        LAG(monthly_rate) OVER (
            PARTITION BY practice_code_standardised
            ORDER BY reporting_month
        ) AS prior_rate
    FROM monthly_0
)
SELECT
    practice_code_standardised,
    COUNT(DISTINCT reporting_month) AS ocs_months_observed,
    SUM(ocs_total_submissions IS NOT NULL) AS ocs_total_metric_months,
    SUM(
        ocs_total_submissions IS NOT NULL
        AND ocs_clinical_submissions IS NOT NULL
        AND ocs_administrative_submissions IS NOT NULL
        AND ocs_other_unknown_submissions IS NOT NULL
    ) AS ocs_component_complete_months,
    SUM(ocs_total_submissions) AS ocs_annual_total_submissions,
    SUM(ocs_clinical_submissions) AS ocs_annual_clinical_submissions,
    SUM(ocs_administrative_submissions) AS ocs_annual_administrative_submissions,
    SUM(ocs_other_unknown_submissions) AS ocs_annual_other_unknown_submissions,
    SUM(registered_patients) AS annual_patient_month_exposure,
    AVG(registered_patients) AS mean_monthly_registered_patients,
    1000.0 * SUM(ocs_total_submissions) / NULLIF(SUM(registered_patients), 0)
        AS ocs_submissions_per_1000_patient_months,
    1.0 * SUM(ocs_clinical_submissions) / NULLIF(SUM(ocs_total_submissions), 0)
        AS ocs_clinical_share,
    1.0 * SUM(ocs_administrative_submissions) / NULLIF(SUM(ocs_total_submissions), 0)
        AS ocs_administrative_share,
    1.0 * SUM(ocs_other_unknown_submissions) / NULLIF(SUM(ocs_total_submissions), 0)
        AS ocs_other_unknown_share,
    SUM(ocs_clinical_submissions)
      + SUM(ocs_administrative_submissions)
      + SUM(ocs_other_unknown_submissions)
      - SUM(ocs_total_submissions) AS ocs_component_reconciliation_difference,
    AVG(ABS(monthly_rate - prior_rate)) AS ocs_mean_absolute_monthly_rate_change,
    SUM(registered_patients IS NULL OR registered_patients <= 0) AS ocs_invalid_denominator_months
FROM monthly
GROUP BY practice_code_standardised;

CREATE UNIQUE INDEX ux_annual_online_consultation_features
    ON annual_online_consultation_features (practice_code_standardised);

DROP TABLE IF EXISTS annual_appointment_features;
CREATE TABLE annual_appointment_features AS
WITH monthly_0 AS (
    SELECT
        g.*,
        d.registered_patients,
        CASE
            WHEN d.registered_patients > 0
            THEN 1000.0 * g.gpad_total_appointments / d.registered_patients
        END AS monthly_rate
    FROM appointment_activity_practice_month AS g
    JOIN registered_population_by_practice_month AS d
        USING (practice_code_standardised, reporting_month)
),
monthly AS (
    SELECT
        *,
        LAG(monthly_rate) OVER (
            PARTITION BY practice_code_standardised
            ORDER BY reporting_month
        ) AS prior_rate
    FROM monthly_0
)
SELECT
    practice_code_standardised,
    COUNT(DISTINCT reporting_month) AS gpad_months_observed,
    SUM(gpad_total_appointments IS NOT NULL) AS gpad_total_metric_months,
    SUM(null_appointment_count_rows) AS gpad_null_appointment_count_rows,
    SUM(gpad_total_appointments) AS gpad_annual_total_appointments,
    SUM(gpad_attended) AS gpad_annual_attended,
    SUM(gpad_dna) AS gpad_annual_dna,
    SUM(gpad_status_unknown) AS gpad_annual_status_unknown,
    SUM(gpad_face_to_face) AS gpad_annual_face_to_face,
    SUM(gpad_telephone) AS gpad_annual_telephone,
    SUM(gpad_video_online) AS gpad_annual_video_online,
    SUM(gpad_home_visit) AS gpad_annual_home_visit,
    SUM(gpad_mode_unknown) AS gpad_annual_mode_unknown,
    SUM(gpad_mode_other) AS gpad_annual_mode_other,
    SUM(gpad_same_day) AS gpad_annual_same_day,
    SUM(gpad_1_day) AS gpad_annual_1_day,
    SUM(gpad_2_to_7_days) AS gpad_annual_2_to_7_days,
    SUM(gpad_8_to_14_days) AS gpad_annual_8_to_14_days,
    SUM(gpad_15_to_21_days) AS gpad_annual_15_to_21_days,
    SUM(gpad_22_to_28_days) AS gpad_annual_22_to_28_days,
    SUM(gpad_over_28_days) AS gpad_annual_over_28_days,
    SUM(gpad_15_to_21_days) + SUM(gpad_22_to_28_days) + SUM(gpad_over_28_days)
        AS gpad_annual_over_14_days,
    SUM(gpad_booking_unknown) AS gpad_annual_booking_unknown,
    SUM(gpad_booking_other) AS gpad_annual_booking_other,
    SUM(registered_patients) AS annual_patient_month_exposure,
    1000.0 * SUM(gpad_total_appointments) / NULLIF(SUM(registered_patients), 0)
        AS gpad_appointments_per_1000_patient_months,
    1.0 * SUM(gpad_dna) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_dna_share,
    1.0 * SUM(gpad_face_to_face) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_face_to_face_share,
    1.0 * SUM(gpad_telephone) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_telephone_share,
    1.0 * SUM(gpad_same_day) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_same_day_share,
    1.0 * SUM(gpad_1_day) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_1_day_share,
    1.0 * SUM(gpad_2_to_7_days) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_2_to_7_days_share,
    (
        1.0 * SUM(gpad_1_day) / NULLIF(SUM(gpad_total_appointments), 0)
    ) + (
        1.0 * SUM(gpad_2_to_7_days) / NULLIF(SUM(gpad_total_appointments), 0)
    ) AS gpad_1_to_7_days_share,
    1.0 * SUM(gpad_8_to_14_days) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_8_to_14_days_share,
    1.0 * (SUM(gpad_same_day) + SUM(gpad_1_day) + SUM(gpad_2_to_7_days))
        / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_within_7_days_share,
    1.0 * (SUM(gpad_15_to_21_days) + SUM(gpad_22_to_28_days) + SUM(gpad_over_28_days))
        / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_over_14_days_share,
    SUM(gpad_attended) + SUM(gpad_dna) + SUM(gpad_status_unknown) - SUM(gpad_total_appointments)
        AS gpad_status_reconciliation_difference,
    SUM(gpad_face_to_face) + SUM(gpad_telephone) + SUM(gpad_video_online)
      + SUM(gpad_home_visit) + SUM(gpad_mode_unknown) + SUM(gpad_mode_other)
      - SUM(gpad_total_appointments) AS gpad_mode_reconciliation_difference,
    SUM(gpad_same_day) + SUM(gpad_1_day) + SUM(gpad_2_to_7_days)
      + SUM(gpad_8_to_14_days) + SUM(gpad_15_to_21_days)
      + SUM(gpad_22_to_28_days) + SUM(gpad_over_28_days)
      + SUM(gpad_booking_unknown) + SUM(gpad_booking_other)
      - SUM(gpad_total_appointments) AS gpad_booking_reconciliation_difference,
    AVG(ABS(monthly_rate - prior_rate)) AS gpad_mean_absolute_monthly_rate_change,
    SUM(registered_patients IS NULL OR registered_patients <= 0) AS gpad_invalid_denominator_months
FROM monthly
GROUP BY practice_code_standardised;

CREATE UNIQUE INDEX ux_annual_appointment_features
    ON annual_appointment_features (practice_code_standardised);

DROP TABLE IF EXISTS eligible_practices_before_activity_total_rule;
CREATE TABLE eligible_practices_before_activity_total_rule AS
SELECT o.practice_code_standardised
FROM annual_online_consultation_features AS o
JOIN annual_appointment_features AS g USING (practice_code_standardised)
JOIN annual_population_denominator_audit AS d USING (practice_code_standardised)
WHERE o.ocs_months_observed = 12
  AND o.ocs_total_metric_months = 12
  AND o.ocs_component_complete_months = 12
  AND ABS(o.ocs_component_reconciliation_difference) < 0.000001
  AND o.ocs_invalid_denominator_months = 0
  AND g.gpad_months_observed = 12
  AND g.gpad_total_metric_months = 12
  AND g.gpad_null_appointment_count_rows = 0
  AND g.gpad_status_reconciliation_difference = 0
  AND g.gpad_mode_reconciliation_difference = 0
  AND g.gpad_booking_reconciliation_difference = 0
  AND g.gpad_invalid_denominator_months = 0
  AND d.months_with_denominator = 12
  AND d.implausible_denominator_flag = 0;

CREATE UNIQUE INDEX ux_eligible_practices_before_activity_total_rule
    ON eligible_practices_before_activity_total_rule (practice_code_standardised);

DROP TABLE IF EXISTS candidate_annual_practice_features;
CREATE TABLE candidate_annual_practice_features AS
SELECT
    o.practice_code_standardised,
    o.ocs_months_observed,
    g.gpad_months_observed,
    d.months_with_denominator,
    d.annual_patient_month_exposure,
    d.mean_monthly_list_size,
    d.maximum_percentage_monthly_change,
    o.ocs_annual_total_submissions,
    o.ocs_annual_clinical_submissions,
    o.ocs_annual_administrative_submissions,
    o.ocs_annual_other_unknown_submissions,
    o.ocs_submissions_per_1000_patient_months,
    o.ocs_clinical_share,
    o.ocs_administrative_share,
    o.ocs_other_unknown_share,
    o.ocs_component_reconciliation_difference,
    o.ocs_mean_absolute_monthly_rate_change,
    g.gpad_annual_total_appointments,
    g.gpad_annual_attended,
    g.gpad_annual_dna,
    g.gpad_annual_status_unknown,
    g.gpad_annual_face_to_face,
    g.gpad_annual_telephone,
    g.gpad_annual_video_online,
    g.gpad_annual_home_visit,
    g.gpad_annual_mode_unknown,
    g.gpad_annual_mode_other,
    g.gpad_annual_same_day,
    g.gpad_annual_1_day,
    g.gpad_annual_2_to_7_days,
    g.gpad_annual_8_to_14_days,
    g.gpad_annual_15_to_21_days,
    g.gpad_annual_22_to_28_days,
    g.gpad_annual_over_28_days,
    g.gpad_annual_over_14_days,
    g.gpad_annual_booking_unknown,
    g.gpad_annual_booking_other,
    g.gpad_appointments_per_1000_patient_months,
    g.gpad_dna_share,
    g.gpad_face_to_face_share,
    g.gpad_telephone_share,
    g.gpad_same_day_share,
    g.gpad_1_day_share,
    g.gpad_2_to_7_days_share,
    g.gpad_1_to_7_days_share,
    g.gpad_8_to_14_days_share,
    g.gpad_within_7_days_share,
    g.gpad_over_14_days_share,
    g.gpad_mean_absolute_monthly_rate_change,
    g.gpad_status_reconciliation_difference,
    g.gpad_mode_reconciliation_difference,
    g.gpad_booking_reconciliation_difference
FROM eligible_practices_before_activity_total_rule AS e
JOIN annual_online_consultation_features AS o USING (practice_code_standardised)
JOIN annual_appointment_features AS g USING (practice_code_standardised)
JOIN annual_population_denominator_audit AS d USING (practice_code_standardised);

CREATE UNIQUE INDEX ux_candidate_annual_practice_features
    ON candidate_annual_practice_features (practice_code_standardised);

DROP TABLE IF EXISTS analytical_cohort_exclusion_audit;
CREATE TABLE analytical_cohort_exclusion_audit AS
SELECT
    practice_code_standardised,
    CASE
        WHEN ocs_annual_total_submissions IS NULL THEN 'NULL_OCS_ANNUAL_TOTAL'
        WHEN ocs_annual_total_submissions <= 0 THEN 'ZERO_OCS_ANNUAL_TOTAL'
        WHEN gpad_annual_total_appointments IS NULL THEN 'NULL_GPAD_ANNUAL_TOTAL'
        WHEN gpad_annual_total_appointments <= 0 THEN 'ZERO_GPAD_ANNUAL_TOTAL'
        ELSE 'NULL_REQUIRED_ANALYTICAL_FEATURE'
    END AS exclusion_reason
FROM candidate_annual_practice_features
WHERE ocs_annual_total_submissions IS NULL
   OR ocs_annual_total_submissions <= 0
   OR gpad_annual_total_appointments IS NULL
   OR gpad_annual_total_appointments <= 0
   OR ocs_submissions_per_1000_patient_months IS NULL
   OR ocs_clinical_share IS NULL
   OR ocs_administrative_share IS NULL
   OR ocs_mean_absolute_monthly_rate_change IS NULL
   OR gpad_appointments_per_1000_patient_months IS NULL
   OR gpad_dna_share IS NULL
   OR gpad_face_to_face_share IS NULL
   OR gpad_telephone_share IS NULL
   OR gpad_same_day_share IS NULL
   OR gpad_1_to_7_days_share IS NULL
   OR gpad_8_to_14_days_share IS NULL
   OR gpad_over_14_days_share IS NULL
   OR gpad_mean_absolute_monthly_rate_change IS NULL;

CREATE UNIQUE INDEX ux_analytical_cohort_exclusion_audit
    ON analytical_cohort_exclusion_audit (practice_code_standardised);

DROP TABLE IF EXISTS eligible_annual_practice_features;
CREATE TABLE eligible_annual_practice_features AS
SELECT c.*
FROM candidate_annual_practice_features AS c
LEFT JOIN analytical_cohort_exclusion_audit AS x USING (practice_code_standardised)
WHERE x.practice_code_standardised IS NULL;

CREATE UNIQUE INDEX ux_eligible_annual_practice_features
    ON eligible_annual_practice_features (practice_code_standardised);

DROP TABLE IF EXISTS annual_feature_internal_validation;
CREATE TABLE annual_feature_internal_validation (
    check_name TEXT PRIMARY KEY,
    expected_value INTEGER NOT NULL,
    actual_value INTEGER NOT NULL,
    result TEXT NOT NULL
);

INSERT INTO annual_feature_internal_validation
SELECT 'denominator_audit_duplicate_practices', 0,
       COUNT(*) - COUNT(DISTINCT practice_code_standardised),
       CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised) THEN 'PASS' ELSE 'FAIL' END
FROM annual_population_denominator_audit
UNION ALL
SELECT 'ocs_annual_duplicate_practices', 0,
       COUNT(*) - COUNT(DISTINCT practice_code_standardised),
       CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised) THEN 'PASS' ELSE 'FAIL' END
FROM annual_online_consultation_features
UNION ALL
SELECT 'gpad_annual_duplicate_practices', 0,
       COUNT(*) - COUNT(DISTINCT practice_code_standardised),
       CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised) THEN 'PASS' ELSE 'FAIL' END
FROM annual_appointment_features
UNION ALL
SELECT 'gpad_status_reconciliation_failures', 0, COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM annual_appointment_features WHERE gpad_status_reconciliation_difference <> 0
UNION ALL
SELECT 'gpad_mode_reconciliation_failures', 0, COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM annual_appointment_features WHERE gpad_mode_reconciliation_difference <> 0
UNION ALL
SELECT 'gpad_booking_reconciliation_failures', 0, COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM annual_appointment_features WHERE gpad_booking_reconciliation_difference <> 0
UNION ALL
SELECT 'eligible_vs_candidate_row_difference', 0,
       ABS((SELECT COUNT(*) FROM eligible_practices_before_activity_total_rule)
           - (SELECT COUNT(*) FROM candidate_annual_practice_features)),
       CASE WHEN (SELECT COUNT(*) FROM eligible_practices_before_activity_total_rule)
                    = (SELECT COUNT(*) FROM candidate_annual_practice_features)
            THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 'final_duplicate_practices', 0,
       COUNT(*) - COUNT(DISTINCT practice_code_standardised),
       CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised) THEN 'PASS' ELSE 'FAIL' END
FROM eligible_annual_practice_features
UNION ALL
SELECT 'final_zero_ocs_practices', 0, COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM eligible_annual_practice_features WHERE ocs_annual_total_submissions <= 0
UNION ALL
SELECT 'final_zero_gpad_practices', 0, COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM eligible_annual_practice_features WHERE gpad_annual_total_appointments <= 0;
