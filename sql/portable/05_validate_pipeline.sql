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
SELECT 'annual_matrix_column_count', 'identifier plus thirteen modelling features when annual output exists', '14',
       CAST((SELECT COUNT(*) FROM pragma_table_info('annual_practice_access_modelling_matrix')) AS TEXT),
       CASE WHEN (SELECT COUNT(*) FROM pragma_table_info('annual_practice_access_modelling_matrix')) = 14
            THEN 'PASS' ELSE 'FAIL' END,
       'The identifier is retained for traceability and is not a modelling feature.';
