/*
Purpose: retain expected, observed and interpreted evidence for mandatory
source, grain, period, reconciliation, join-cardinality and annual-feature gates.
*/

DROP TABLE IF EXISTS pipeline_validation_results;
CREATE TABLE pipeline_validation_results (
    test_name TEXT PRIMARY KEY,
    test_sql TEXT NOT NULL,
    expected_result TEXT NOT NULL,
    observed_result TEXT NOT NULL,
    status TEXT NOT NULL,
    interpretation TEXT NOT NULL
);

INSERT INTO pipeline_validation_results
SELECT 'online_consultation_duplicate_keys',
       'rows minus distinct practice-month keys', '0',
       CAST(COUNT(*) - COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) AS TEXT),
       CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) THEN 'PASS' ELSE 'FAIL' END,
       'OCS must contain one record per practice-month before joining.'
FROM online_consultation_practice_month
UNION ALL
SELECT 'appointment_duplicate_keys', 'rows minus distinct practice-month keys', '0',
       CAST(COUNT(*) - COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) AS TEXT),
       CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) THEN 'PASS' ELSE 'FAIL' END,
       'GPAD must contain one record per practice-month before joining.'
FROM appointment_activity_practice_month
UNION ALL
SELECT 'cloud_telephony_duplicate_keys', 'rows minus distinct practice-month keys', '0',
       CAST(COUNT(*) - COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) AS TEXT),
       CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) THEN 'PASS' ELSE 'FAIL' END,
       'CBT must contain one record per practice-month before joining.'
FROM cloud_telephony_practice_month
UNION ALL
SELECT 'outside_window_rows', 'count source rows outside configured bounds', '0',
       CAST((SELECT COUNT(*) FROM online_consultation_source, analysis_window
             WHERE reporting_month < start_month OR reporting_month > end_month)
          + (SELECT COUNT(*) FROM appointment_activity_source, analysis_window
             WHERE reporting_month < start_month OR reporting_month > end_month)
          + (SELECT COUNT(*) FROM cloud_telephony_source, analysis_window
             WHERE reporting_month < start_month OR reporting_month > end_month) AS TEXT),
       CASE WHEN
          (SELECT COUNT(*) FROM online_consultation_source, analysis_window
           WHERE reporting_month < start_month OR reporting_month > end_month)
        + (SELECT COUNT(*) FROM appointment_activity_source, analysis_window
           WHERE reporting_month < start_month OR reporting_month > end_month)
        + (SELECT COUNT(*) FROM cloud_telephony_source, analysis_window
           WHERE reporting_month < start_month OR reporting_month > end_month) = 0
       THEN 'PASS' ELSE 'FAIL' END,
       'No observation outside the configured analytical period may enter the run.'
UNION ALL
SELECT 'invalid_practice_codes', 'six uppercase alphanumeric characters', '0', CAST(COUNT(*) AS TEXT),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
       'Canonical practice identifiers must satisfy the documented structural rule.'
FROM practice_month_union_spine
WHERE LENGTH(practice_code_standardised) <> 6
   OR practice_code_standardised <> UPPER(practice_code_standardised)
   OR practice_code_standardised GLOB '*[^A-Z0-9]*'
UNION ALL
SELECT 'appointment_status_reconciliation_failures', 'count non-zero status differences', '0', CAST(COUNT(*) AS TEXT),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
       'GPAD status components must reconcile to the independently reported total.'
FROM appointment_activity_practice_month
WHERE ABS(status_reconciliation_difference) > 0.0000001
UNION ALL
SELECT 'appointment_mode_reconciliation_failures', 'count non-zero mode differences', '0', CAST(COUNT(*) AS TEXT),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
       'GPAD mode components must reconcile to the independently reported total.'
FROM appointment_activity_practice_month
WHERE ABS(mode_reconciliation_difference) > 0.0000001
UNION ALL
SELECT 'appointment_booking_reconciliation_failures', 'count non-zero booking differences', '0', CAST(COUNT(*) AS TEXT),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
       'Each appointment contributes once to a mutually exclusive booking interval.'
FROM appointment_activity_practice_month
WHERE ABS(booking_reconciliation_difference) > 0.0000001
UNION ALL
SELECT 'online_consultation_component_reconciliation_failures', 'count non-zero OCS component differences', '0', CAST(COUNT(*) AS TEXT),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
       'OCS clinical, administrative and other/unknown counts must reconcile to total submissions.'
FROM online_consultation_practice_month
WHERE ABS(component_reconciliation_difference) > 0.0000001
UNION ALL
SELECT 'union_spine_row_multiplication', 'integrated rows minus union-spine rows', '0',
       CAST((SELECT COUNT(*) FROM multichannel_practice_month_coverage)
          - (SELECT COUNT(*) FROM practice_month_union_spine) AS TEXT),
       CASE WHEN (SELECT COUNT(*) FROM multichannel_practice_month_coverage)
                    = (SELECT COUNT(*) FROM practice_month_union_spine)
            THEN 'PASS' ELSE 'FAIL' END,
       'A one-row-per-practice-month integration must have multiplication factor 1.0.'
UNION ALL
SELECT 'annual_stage_period_rule', 'annual output allowed only when requested for exactly twelve configured months', '0',
       CAST(CASE WHEN (SELECT expected_months FROM analysis_window) <> 12
                       OR (SELECT annual_features_enabled FROM analysis_window) <> 1
                 THEN (SELECT COUNT(*) FROM annual_practice_access_profiles) ELSE 0 END AS TEXT),
       CASE WHEN ((SELECT expected_months FROM analysis_window) = 12
                   AND (SELECT annual_features_enabled FROM analysis_window) = 1)
                  OR (SELECT COUNT(*) FROM annual_practice_access_profiles) = 0
            THEN 'PASS' ELSE 'FAIL' END,
       'Practice-month runs of any length remain separate from the optional twelve-month annual product.'
UNION ALL
SELECT 'annual_matrix_exact_schema', 'locked identifier and fourteen-feature order',
       'practice_code_standardised|ocs_submissions_per_1000_patient_months|ocs_clinical_share|ocs_administrative_share|gpad_appointments_per_1000_patient_months|gpad_dna_share|gpad_face_to_face_share|gpad_telephone_share|gpad_same_day_share|gpad_1_day_share|gpad_2_to_7_days_share|gpad_8_to_14_days_share|gpad_over_14_days_share|ocs_mean_absolute_monthly_rate_change|gpad_mean_absolute_monthly_rate_change',
       (SELECT GROUP_CONCAT(name, '|') FROM (SELECT name FROM pragma_table_info('annual_practice_access_modelling_matrix') ORDER BY cid)),
       CASE WHEN (SELECT GROUP_CONCAT(name, '|') FROM (SELECT name FROM pragma_table_info('annual_practice_access_modelling_matrix') ORDER BY cid))
              = 'practice_code_standardised|ocs_submissions_per_1000_patient_months|ocs_clinical_share|ocs_administrative_share|gpad_appointments_per_1000_patient_months|gpad_dna_share|gpad_face_to_face_share|gpad_telephone_share|gpad_same_day_share|gpad_1_day_share|gpad_2_to_7_days_share|gpad_8_to_14_days_share|gpad_over_14_days_share|ocs_mean_absolute_monthly_rate_change|gpad_mean_absolute_monthly_rate_change'
            THEN 'PASS' ELSE 'FAIL' END,
       'The identifier is retained for traceability and is not a modelling feature.'
UNION ALL
SELECT 'cbt_inbound_matrix_exact_schema', 'fourteen inherited fields plus three CBT inbound fields', '18 total columns',
       CAST((SELECT COUNT(*) FROM pragma_table_info('inbound_telephony_sensitivity_modelling_matrix')) AS TEXT),
       CASE WHEN (SELECT COUNT(*) FROM pragma_table_info('inbound_telephony_sensitivity_modelling_matrix')) = 18
            THEN 'PASS' ELSE 'FAIL' END,
       'The restricted inbound matrix contains seventeen numerical features.'
UNION ALL
SELECT 'cbt_outcome_matrix_exact_schema', 'seventeen inherited fields plus four CBT outcome fields', '22 total columns',
       CAST((SELECT COUNT(*) FROM pragma_table_info('telephony_outcome_sensitivity_modelling_matrix')) AS TEXT),
       CASE WHEN (SELECT COUNT(*) FROM pragma_table_info('telephony_outcome_sensitivity_modelling_matrix')) = 22
            THEN 'PASS' ELSE 'FAIL' END,
       'The raw outcome-complete matrix contains twenty-one numerical features.'
UNION ALL
SELECT 'cbt_inbound_parent_inheritance', 'child rows absent from parent or with changed shared values', '0',
       CAST(COUNT(*) AS TEXT), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
       'Every shared OCS-GPAD value must be inherited exactly by practice code.'
FROM inbound_telephony_sensitivity_modelling_matrix AS c
LEFT JOIN annual_practice_access_modelling_matrix AS p USING (practice_code_standardised)
WHERE p.practice_code_standardised IS NULL
   OR c.ocs_submissions_per_1000_patient_months IS NOT p.ocs_submissions_per_1000_patient_months
   OR c.ocs_clinical_share IS NOT p.ocs_clinical_share
   OR c.ocs_administrative_share IS NOT p.ocs_administrative_share
   OR c.gpad_appointments_per_1000_patient_months IS NOT p.gpad_appointments_per_1000_patient_months
   OR c.gpad_dna_share IS NOT p.gpad_dna_share
   OR c.gpad_face_to_face_share IS NOT p.gpad_face_to_face_share
   OR c.gpad_telephone_share IS NOT p.gpad_telephone_share
   OR c.gpad_same_day_share IS NOT p.gpad_same_day_share
   OR c.gpad_1_day_share IS NOT p.gpad_1_day_share
   OR c.gpad_2_to_7_days_share IS NOT p.gpad_2_to_7_days_share
   OR c.gpad_8_to_14_days_share IS NOT p.gpad_8_to_14_days_share
   OR c.gpad_over_14_days_share IS NOT p.gpad_over_14_days_share
   OR c.ocs_mean_absolute_monthly_rate_change IS NOT p.ocs_mean_absolute_monthly_rate_change
   OR c.gpad_mean_absolute_monthly_rate_change IS NOT p.gpad_mean_absolute_monthly_rate_change
UNION ALL
SELECT 'cbt_outcome_parent_inheritance', 'child rows absent from parent or with changed shared values', '0',
       CAST(COUNT(*) AS TEXT), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
       'Every shared core and inbound value must be inherited exactly by practice code.'
FROM telephony_outcome_sensitivity_modelling_matrix AS c
LEFT JOIN inbound_telephony_sensitivity_modelling_matrix AS p USING (practice_code_standardised)
WHERE p.practice_code_standardised IS NULL
   OR c.ocs_submissions_per_1000_patient_months IS NOT p.ocs_submissions_per_1000_patient_months
   OR c.ocs_clinical_share IS NOT p.ocs_clinical_share
   OR c.ocs_administrative_share IS NOT p.ocs_administrative_share
   OR c.gpad_appointments_per_1000_patient_months IS NOT p.gpad_appointments_per_1000_patient_months
   OR c.gpad_dna_share IS NOT p.gpad_dna_share
   OR c.gpad_face_to_face_share IS NOT p.gpad_face_to_face_share
   OR c.gpad_telephone_share IS NOT p.gpad_telephone_share
   OR c.gpad_same_day_share IS NOT p.gpad_same_day_share
   OR c.gpad_1_day_share IS NOT p.gpad_1_day_share
   OR c.gpad_2_to_7_days_share IS NOT p.gpad_2_to_7_days_share
   OR c.gpad_8_to_14_days_share IS NOT p.gpad_8_to_14_days_share
   OR c.gpad_over_14_days_share IS NOT p.gpad_over_14_days_share
   OR c.ocs_mean_absolute_monthly_rate_change IS NOT p.ocs_mean_absolute_monthly_rate_change
   OR c.gpad_mean_absolute_monthly_rate_change IS NOT p.gpad_mean_absolute_monthly_rate_change
   OR c.cbt_inbound_calls_per_1000_patient_months IS NOT p.cbt_inbound_calls_per_1000_patient_months
   OR c.cbt_mean_absolute_monthly_call_rate_change IS NOT p.cbt_mean_absolute_monthly_call_rate_change
   OR c.cbt_call_rate_range IS NOT p.cbt_call_rate_range;
