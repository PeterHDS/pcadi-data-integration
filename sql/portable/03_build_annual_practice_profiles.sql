/*
Purpose: construct one practice-level profile only when the configured period
contains exactly twelve months and each practice has complete OCS, GPAD and
positive denominator evidence. Shares use annual component totals. Monthly
missingness is never treated as zero.
*/

DROP TABLE IF EXISTS annual_practice_access_profiles;
CREATE TABLE annual_practice_access_profiles AS
WITH monthly AS (
    SELECT
        m.*,
        1000.0 * gpad_total_appointments / NULLIF(registered_patients, 0) AS gpad_rate,
        LAG(ocs_submissions_per_1000) OVER (
            PARTITION BY practice_code_standardised ORDER BY reporting_month
        ) AS prior_ocs_rate,
        LAG(1000.0 * gpad_total_appointments / NULLIF(registered_patients, 0)) OVER (
            PARTITION BY practice_code_standardised ORDER BY reporting_month
        ) AS prior_gpad_rate
    FROM multichannel_practice_month_coverage AS m
    WHERE has_online_consultation = 1 AND has_appointment_activity = 1
),
annual AS (
    SELECT
        practice_code_standardised,
        COUNT(DISTINCT reporting_month) AS matched_months,
        COUNT(DISTINCT CASE WHEN registered_patients > 0 THEN reporting_month END) AS denominator_months,
        SUM(registered_patients) AS patient_month_exposure,
        SUM(ocs_total_submissions) AS ocs_total,
        SUM(ocs_clinical_submissions) AS ocs_clinical,
        SUM(ocs_administrative_submissions) AS ocs_administrative,
        SUM(gpad_total_appointments) AS gpad_total,
        SUM(gpad_dna) AS gpad_dna,
        SUM(gpad_face_to_face) AS gpad_face_to_face,
        SUM(gpad_telephone) AS gpad_telephone,
        SUM(gpad_same_day) AS gpad_same_day,
        SUM(gpad_one_day) AS gpad_one_day,
        SUM(gpad_two_to_seven_days) AS gpad_two_to_seven_days,
        SUM(gpad_eight_to_fourteen_days) AS gpad_eight_to_fourteen_days,
        SUM(gpad_fifteen_to_twenty_one_days) AS gpad_fifteen_to_twenty_one_days,
        SUM(gpad_twenty_two_to_twenty_eight_days) AS gpad_twenty_two_to_twenty_eight_days,
        SUM(gpad_more_than_twenty_eight_days) AS gpad_more_than_twenty_eight_days,
        AVG(CASE WHEN prior_ocs_rate IS NOT NULL
                 THEN ABS(ocs_submissions_per_1000 - prior_ocs_rate) END)
            AS ocs_mean_absolute_monthly_rate_change,
        AVG(CASE WHEN prior_gpad_rate IS NOT NULL
                 THEN ABS(gpad_rate - prior_gpad_rate) END)
            AS gpad_mean_absolute_monthly_rate_change,
        MAX(ABS(COALESCE(ocs_component_reconciliation_difference, 0))) AS max_ocs_reconciliation_difference,
        MAX(ABS(COALESCE(gpad_status_reconciliation_difference, 0))) AS max_gpad_status_difference,
        MAX(ABS(COALESCE(gpad_mode_reconciliation_difference, 0))) AS max_gpad_mode_difference,
        MAX(ABS(COALESCE(gpad_booking_reconciliation_difference, 0))) AS max_gpad_booking_difference
    FROM monthly
    GROUP BY practice_code_standardised
),
settings AS (SELECT expected_months, annual_features_enabled FROM analysis_window)
SELECT
    a.practice_code_standardised,
    a.matched_months,
    a.denominator_months,
    a.patient_month_exposure,
    1000.0 * a.ocs_total / NULLIF(a.patient_month_exposure, 0) AS ocs_submissions_per_1000_patient_months,
    1.0 * a.ocs_clinical / NULLIF(a.ocs_total, 0) AS ocs_clinical_share,
    1.0 * a.ocs_administrative / NULLIF(a.ocs_total, 0) AS ocs_administrative_share,
    1000.0 * a.gpad_total / NULLIF(a.patient_month_exposure, 0) AS gpad_appointments_per_1000_patient_months,
    1.0 * a.gpad_dna / NULLIF(a.gpad_total, 0) AS gpad_dna_share,
    1.0 * a.gpad_face_to_face / NULLIF(a.gpad_total, 0) AS gpad_face_to_face_share,
    1.0 * a.gpad_telephone / NULLIF(a.gpad_total, 0) AS gpad_telephone_share,
    1.0 * a.gpad_same_day / NULLIF(a.gpad_total, 0) AS gpad_same_day_share,
    1.0 * (a.gpad_one_day + a.gpad_two_to_seven_days) / NULLIF(a.gpad_total, 0)
        AS gpad_1_to_7_days_share,
    1.0 * a.gpad_eight_to_fourteen_days / NULLIF(a.gpad_total, 0)
        AS gpad_8_to_14_days_share,
    1.0 * (a.gpad_fifteen_to_twenty_one_days
           + a.gpad_twenty_two_to_twenty_eight_days
           + a.gpad_more_than_twenty_eight_days) / NULLIF(a.gpad_total, 0)
        AS gpad_over_14_days_share,
    a.ocs_mean_absolute_monthly_rate_change,
    a.gpad_mean_absolute_monthly_rate_change
FROM annual AS a, settings AS s
WHERE s.annual_features_enabled = 1
  AND s.expected_months = 12
  AND a.matched_months = 12
  AND a.denominator_months = 12
  AND a.patient_month_exposure > 0
  AND a.ocs_total > 0
  AND a.gpad_total > 0
  AND a.max_ocs_reconciliation_difference = 0
  AND a.max_gpad_status_difference = 0
  AND a.max_gpad_mode_difference = 0
  AND a.max_gpad_booking_difference = 0;

CREATE UNIQUE INDEX ux_annual_practice_access_profiles
    ON annual_practice_access_profiles (practice_code_standardised);

DROP VIEW IF EXISTS annual_practice_access_modelling_matrix;
CREATE VIEW annual_practice_access_modelling_matrix AS
SELECT
    practice_code_standardised,
    ocs_submissions_per_1000_patient_months,
    ocs_clinical_share,
    ocs_administrative_share,
    gpad_appointments_per_1000_patient_months,
    gpad_dna_share,
    gpad_face_to_face_share,
    gpad_telephone_share,
    gpad_same_day_share,
    gpad_1_to_7_days_share,
    gpad_8_to_14_days_share,
    gpad_over_14_days_share,
    ocs_mean_absolute_monthly_rate_change,
    gpad_mean_absolute_monthly_rate_change
FROM annual_practice_access_profiles;
