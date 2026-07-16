/*
Purpose: add CBT sensitivity features to the validated twelve-month core without
changing its OCS or GPAD values. CBT remains a separate activity domain.
*/

DROP TABLE IF EXISTS annual_cloud_telephony_features;
CREATE TABLE annual_cloud_telephony_features AS
WITH monthly AS (
    SELECT
        c.*,
        LAG(inbound_calls) OVER (
            PARTITION BY practice_code_standardised ORDER BY reporting_month
        ) AS prior_inbound
    FROM cloud_telephony_practice_month AS c
),
annual AS (
    SELECT
        practice_code_standardised,
        COUNT(DISTINCT reporting_month) AS cbt_months,
        SUM(CASE WHEN mapping_valid = 1 THEN 1 ELSE 0 END) AS mapping_valid_months,
        SUM(CASE WHEN integrity_gap_flag = 1 THEN 1 ELSE 0 END) AS integrity_gap_months,
        SUM(inbound_calls) AS inbound_calls,
        SUM(answered_calls) AS answered_calls,
        SUM(missed_calls) AS missed_calls,
        SUM(ivr_exits) AS ivr_exits,
        SUM(callback_requests) AS callback_requests,
        AVG(CASE WHEN prior_inbound IS NOT NULL THEN ABS(inbound_calls - prior_inbound) END)
            AS mean_absolute_monthly_inbound_change,
        MAX(inbound_calls) - MIN(inbound_calls) AS inbound_range
    FROM monthly
    GROUP BY practice_code_standardised
)
SELECT * FROM annual;

CREATE UNIQUE INDEX ux_annual_cloud_telephony_features
    ON annual_cloud_telephony_features (practice_code_standardised);

DROP TABLE IF EXISTS annual_profiles_with_inbound_telephony_sensitivity;
CREATE TABLE annual_profiles_with_inbound_telephony_sensitivity AS
SELECT
    a.*,
    c.cbt_months,
    c.mapping_valid_months,
    c.integrity_gap_months,
    c.inbound_calls AS cbt_annual_inbound_calls,
    1000.0 * c.inbound_calls / NULLIF(a.patient_month_exposure, 0)
        AS cbt_inbound_calls_per_1000_patient_months,
    c.mean_absolute_monthly_inbound_change AS cbt_mean_absolute_monthly_call_change,
    c.inbound_range AS cbt_call_range
FROM annual_practice_access_profiles AS a
JOIN annual_cloud_telephony_features AS c USING (practice_code_standardised)
WHERE c.cbt_months = 12
  AND c.mapping_valid_months = 12
  AND c.integrity_gap_months = 0
  AND c.inbound_calls > 0;

CREATE UNIQUE INDEX ux_annual_profiles_with_inbound_telephony_sensitivity
    ON annual_profiles_with_inbound_telephony_sensitivity (practice_code_standardised);

DROP VIEW IF EXISTS inbound_telephony_sensitivity_modelling_matrix;
CREATE VIEW inbound_telephony_sensitivity_modelling_matrix AS
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
    gpad_mean_absolute_monthly_rate_change,
    cbt_inbound_calls_per_1000_patient_months,
    cbt_mean_absolute_monthly_call_change,
    cbt_call_range
FROM annual_profiles_with_inbound_telephony_sensitivity;

DROP TABLE IF EXISTS annual_profiles_with_telephony_outcome_sensitivity;
CREATE TABLE annual_profiles_with_telephony_outcome_sensitivity AS
SELECT
    a.*,
    c.answered_calls AS cbt_answered_calls,
    c.missed_calls AS cbt_missed_calls,
    c.ivr_exits AS cbt_ivr_exits,
    c.callback_requests AS cbt_callback_requests,
    1.0 * c.answered_calls / NULLIF(c.inbound_calls, 0) AS cbt_answered_share,
    1.0 * c.missed_calls / NULLIF(c.inbound_calls, 0) AS cbt_missed_share,
    1.0 * c.ivr_exits / NULLIF(c.inbound_calls, 0) AS cbt_ivr_share,
    1.0 * c.callback_requests / NULLIF(c.inbound_calls, 0) AS cbt_callback_request_share
FROM annual_profiles_with_inbound_telephony_sensitivity AS a
JOIN annual_cloud_telephony_features AS c USING (practice_code_standardised)
WHERE c.answered_calls IS NOT NULL
  AND c.missed_calls IS NOT NULL
  AND c.ivr_exits IS NOT NULL
  AND c.callback_requests IS NOT NULL
  AND ABS(c.inbound_calls - c.answered_calls - c.missed_calls
          - c.ivr_exits - c.callback_requests) < 0.0000001;

CREATE UNIQUE INDEX ux_annual_profiles_with_telephony_outcome_sensitivity
    ON annual_profiles_with_telephony_outcome_sensitivity (practice_code_standardised);

DROP VIEW IF EXISTS telephony_outcome_sensitivity_modelling_matrix;
CREATE VIEW telephony_outcome_sensitivity_modelling_matrix AS
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
    gpad_mean_absolute_monthly_rate_change,
    cbt_inbound_calls_per_1000_patient_months,
    cbt_mean_absolute_monthly_call_change,
    cbt_call_range,
    cbt_answered_share,
    cbt_missed_share,
    cbt_ivr_share,
    cbt_callback_request_share
FROM annual_profiles_with_telephony_outcome_sensitivity;
