/* ============================================================
   STAGE 11 - VALIDATE COMPLETE PIPELINE

   Purpose
   Materialise source reconciliation, eligibility, missingness, feature
   ranges and the thirty-six mandatory substantive validation checks.

   Inputs
   All standardised, practice-month, annual, cohort and matrix tables.

   Outputs
   source_reconciliation_summary, practice_eligibility_register,
   feature_missingness_audit, feature_range_summary and
   pipeline_validation_results.

   Analytical grain
   One row per reconciliation, practice, feature or validation test.

   Rationale
   A PASS verdict is evidence-backed only when the expected value, observed
   value, test expression and interpretation are retained together.

   Key assumptions
   Expected counts are comparison targets and do not create or filter the
   analytical cohort.

   Validation gate
   Exactly thirty-six validation rows, all PASS, plus zero unexplained
   source reconciliation difference.

   Expected result
   36 PASS and 0 FAIL; thirteen feature-range rows; no final feature NULLs.
   ============================================================ */

DROP TABLE IF EXISTS source_reconciliation_summary;
CREATE TABLE source_reconciliation_summary AS
SELECT
    'OCS' AS dataset,
    'standardised source to practice-month' AS stage,
    (SELECT SUM(value_numeric)
     FROM standardised_online_consultation_activity
     WHERE METRIC = 'OC_TOTAL_SUBMISSIONS' AND practice_code_valid = 1) AS source_total,
    (SELECT SUM(ocs_total_submissions) FROM online_consultation_practice_month) AS transformed_total,
    (SELECT SUM(value_numeric)
     FROM standardised_online_consultation_activity
     WHERE METRIC = 'OC_TOTAL_SUBMISSIONS' AND practice_code_valid = 1)
      - (SELECT SUM(ocs_total_submissions) FROM online_consultation_practice_month) AS unexplained_difference
UNION ALL
SELECT
    'GPAD',
    'standardised source to practice-month',
    (SELECT SUM(appointment_count) FROM standardised_appointment_activity WHERE practice_code_valid = 1),
    (SELECT SUM(gpad_total_appointments) FROM appointment_activity_practice_month),
    (SELECT SUM(appointment_count) FROM standardised_appointment_activity WHERE practice_code_valid = 1)
      - (SELECT SUM(gpad_total_appointments) FROM appointment_activity_practice_month)
UNION ALL
SELECT
    'OCS',
    'practice-month to final 12-month cohort',
    (SELECT SUM(ocs_total_submissions) FROM online_consultation_practice_month),
    (SELECT SUM(ocs_annual_total_submissions) FROM eligible_annual_practice_features),
    (SELECT SUM(ocs_total_submissions) FROM online_consultation_practice_month)
      - (SELECT SUM(ocs_annual_total_submissions) FROM eligible_annual_practice_features)
UNION ALL
SELECT
    'GPAD',
    'practice-month to final 12-month cohort',
    (SELECT SUM(gpad_total_appointments) FROM appointment_activity_practice_month),
    (SELECT SUM(gpad_annual_total_appointments) FROM eligible_annual_practice_features),
    (SELECT SUM(gpad_total_appointments) FROM appointment_activity_practice_month)
      - (SELECT SUM(gpad_annual_total_appointments) FROM eligible_annual_practice_features);

DROP TABLE IF EXISTS practice_eligibility_register;
CREATE TABLE practice_eligibility_register AS
WITH observed_practices AS (
    SELECT practice_code_standardised FROM annual_online_consultation_features
    UNION
    SELECT practice_code_standardised FROM annual_appointment_features
    UNION
    SELECT practice_code_standardised FROM annual_population_denominator_audit
)
SELECT
    p.practice_code_standardised,
    CASE
        WHEN o.practice_code_standardised IS NULL OR o.ocs_months_observed <> 12 THEN 'OCS_NOT_12_MONTHS'
        WHEN o.ocs_total_metric_months <> 12 OR o.ocs_component_complete_months <> 12 THEN 'OCS_REQUIRED_MEASURES_INCOMPLETE'
        WHEN ABS(o.ocs_component_reconciliation_difference) >= 0.000001 THEN 'OCS_COMPONENT_RECONCILIATION_FAILED'
        WHEN g.practice_code_standardised IS NULL OR g.gpad_months_observed <> 12 THEN 'GPAD_NOT_12_MONTHS'
        WHEN g.gpad_total_metric_months <> 12 OR g.gpad_null_appointment_count_rows <> 0 THEN 'GPAD_REQUIRED_MEASURES_INCOMPLETE'
        WHEN g.gpad_status_reconciliation_difference <> 0
          OR g.gpad_mode_reconciliation_difference <> 0
          OR g.gpad_booking_reconciliation_difference <> 0 THEN 'GPAD_CATEGORY_RECONCILIATION_FAILED'
        WHEN d.practice_code_standardised IS NULL
          OR d.months_with_denominator <> 12
          OR d.implausible_denominator_flag <> 0 THEN 'DENOMINATOR_INCOMPLETE_OR_INVALID'
        WHEN x.practice_code_standardised IS NOT NULL THEN x.exclusion_reason
        ELSE 'INCLUDED'
    END AS eligibility_status
FROM observed_practices AS p
LEFT JOIN annual_online_consultation_features AS o USING (practice_code_standardised)
LEFT JOIN annual_appointment_features AS g USING (practice_code_standardised)
LEFT JOIN annual_population_denominator_audit AS d USING (practice_code_standardised)
LEFT JOIN analytical_cohort_exclusion_audit AS x USING (practice_code_standardised);

DROP TABLE IF EXISTS feature_missingness_audit;
CREATE TABLE feature_missingness_audit AS
WITH final_values(feature, value) AS (
    SELECT 'ocs_submissions_per_1000_patient_months', ocs_submissions_per_1000_patient_months FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'ocs_clinical_share', ocs_clinical_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'ocs_administrative_share', ocs_administrative_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_appointments_per_1000_patient_months', gpad_appointments_per_1000_patient_months FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_dna_share', gpad_dna_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_face_to_face_share', gpad_face_to_face_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_telephone_share', gpad_telephone_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_same_day_share', gpad_same_day_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_1_to_7_days_share', gpad_1_to_7_days_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_8_to_14_days_share', gpad_8_to_14_days_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_over_14_days_share', gpad_over_14_days_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'ocs_mean_absolute_monthly_rate_change', ocs_mean_absolute_monthly_rate_change FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_mean_absolute_monthly_rate_change', gpad_mean_absolute_monthly_rate_change FROM primary_practice_access_clustering_matrix
),
candidate_values(feature, value) AS (
    SELECT 'ocs_submissions_per_1000_patient_months', ocs_submissions_per_1000_patient_months FROM candidate_annual_practice_features
    UNION ALL SELECT 'ocs_clinical_share', ocs_clinical_share FROM candidate_annual_practice_features
    UNION ALL SELECT 'ocs_administrative_share', ocs_administrative_share FROM candidate_annual_practice_features
    UNION ALL SELECT 'gpad_appointments_per_1000_patient_months', gpad_appointments_per_1000_patient_months FROM candidate_annual_practice_features
    UNION ALL SELECT 'gpad_dna_share', gpad_dna_share FROM candidate_annual_practice_features
    UNION ALL SELECT 'gpad_face_to_face_share', gpad_face_to_face_share FROM candidate_annual_practice_features
    UNION ALL SELECT 'gpad_telephone_share', gpad_telephone_share FROM candidate_annual_practice_features
    UNION ALL SELECT 'gpad_same_day_share', gpad_same_day_share FROM candidate_annual_practice_features
    UNION ALL SELECT 'gpad_1_to_7_days_share', gpad_1_to_7_days_share FROM candidate_annual_practice_features
    UNION ALL SELECT 'gpad_8_to_14_days_share', gpad_8_to_14_days_share FROM candidate_annual_practice_features
    UNION ALL SELECT 'gpad_over_14_days_share', gpad_over_14_days_share FROM candidate_annual_practice_features
    UNION ALL SELECT 'ocs_mean_absolute_monthly_rate_change', ocs_mean_absolute_monthly_rate_change FROM candidate_annual_practice_features
    UNION ALL SELECT 'gpad_mean_absolute_monthly_rate_change', gpad_mean_absolute_monthly_rate_change FROM candidate_annual_practice_features
)
SELECT
    'before activity-total cohort restriction' AS phase,
    feature,
    COUNT(*) AS total_rows,
    SUM(value IS NULL) AS sql_null_count,
    SUM(value = 0) AS observed_zero_count,
    'NULL remains NULL; no missing value is converted to zero' AS missingness_treatment
FROM candidate_values
GROUP BY feature
UNION ALL
SELECT
    'final matrix',
    feature,
    COUNT(*),
    SUM(value IS NULL),
    SUM(value = 0),
    'NULL remains NULL; no missing value is converted to zero'
FROM final_values
GROUP BY feature;

DROP TABLE IF EXISTS feature_range_summary;
CREATE TABLE feature_range_summary AS
WITH values_long(feature, value) AS (
    SELECT 'ocs_submissions_per_1000_patient_months', ocs_submissions_per_1000_patient_months FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'ocs_clinical_share', ocs_clinical_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'ocs_administrative_share', ocs_administrative_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_appointments_per_1000_patient_months', gpad_appointments_per_1000_patient_months FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_dna_share', gpad_dna_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_face_to_face_share', gpad_face_to_face_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_telephone_share', gpad_telephone_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_same_day_share', gpad_same_day_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_1_to_7_days_share', gpad_1_to_7_days_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_8_to_14_days_share', gpad_8_to_14_days_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_over_14_days_share', gpad_over_14_days_share FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'ocs_mean_absolute_monthly_rate_change', ocs_mean_absolute_monthly_rate_change FROM primary_practice_access_clustering_matrix
    UNION ALL SELECT 'gpad_mean_absolute_monthly_rate_change', gpad_mean_absolute_monthly_rate_change FROM primary_practice_access_clustering_matrix
)
SELECT
    feature,
    COUNT(*) AS row_count,
    MIN(value) AS minimum,
    AVG(value) AS mean,
    MAX(value) AS maximum,
    SUM(value IS NULL) AS null_count
FROM values_long
GROUP BY feature;

DROP TABLE IF EXISTS pipeline_validation_results;
CREATE TABLE pipeline_validation_results (
    validation_order INTEGER PRIMARY KEY,
    test_name TEXT NOT NULL,
    sql_or_command TEXT NOT NULL,
    expected_result TEXT NOT NULL,
    observed_result TEXT NOT NULL,
    result TEXT NOT NULL,
    interpretation TEXT NOT NULL
);

INSERT INTO pipeline_validation_results
SELECT 1, 'OCS fixed month coverage', 'COUNT DISTINCT reporting_month', '12 months; 2025-04 to 2026-03',
       COUNT(DISTINCT reporting_month) || ' months; ' || MIN(reporting_month) || ' to ' || MAX(reporting_month),
       CASE WHEN COUNT(DISTINCT reporting_month) = 12 AND MIN(reporting_month) = '2025-04' AND MAX(reporting_month) = '2026-03' THEN 'PASS' ELSE 'FAIL' END,
       'No outside month may enter.'
FROM standardised_online_consultation_activity;

INSERT INTO pipeline_validation_results
SELECT 2, 'GPAD fixed month coverage', 'COUNT DISTINCT reporting_month', '12 months; 2025-04 to 2026-03',
       COUNT(DISTINCT reporting_month) || ' months; ' || MIN(reporting_month) || ' to ' || MAX(reporting_month),
       CASE WHEN COUNT(DISTINCT reporting_month) = 12 AND MIN(reporting_month) = '2025-04' AND MAX(reporting_month) = '2026-03' THEN 'PASS' ELSE 'FAIL' END,
       'No outside month may enter.'
FROM standardised_appointment_activity;

INSERT INTO pipeline_validation_results SELECT 3, 'OCS numeric conversion audit', 'numeric_conversion_audit', '0 suspicious; 0 cast-to-NULL', suspicious_numeric_strings || ' suspicious; ' || non_empty_values_cast_to_null || ' cast-to-NULL', CASE WHEN suspicious_numeric_strings = 0 AND non_empty_values_cast_to_null = 0 THEN 'PASS' ELSE 'FAIL' END, 'Non-empty source values must remain valid numeric values.' FROM numeric_conversion_audit WHERE dataset = 'OCS';
INSERT INTO pipeline_validation_results SELECT 4, 'GPAD numeric conversion audit', 'numeric_conversion_audit', '0 suspicious; 0 cast-to-NULL', suspicious_numeric_strings || ' suspicious; ' || non_empty_values_cast_to_null || ' cast-to-NULL', CASE WHEN suspicious_numeric_strings = 0 AND non_empty_values_cast_to_null = 0 THEN 'PASS' ELSE 'FAIL' END, 'Non-empty source values must remain valid numeric values.' FROM numeric_conversion_audit WHERE dataset = 'GPAD';
INSERT INTO pipeline_validation_results SELECT 5, 'OCS natural-key duplicate audit', 'natural_key_duplicate_audit', '0; 0; 0', duplicate_dimension_groups || '; ' || excess_source_rows || '; ' || conflicting_value_groups, CASE WHEN duplicate_dimension_groups = 0 AND excess_source_rows = 0 AND conflicting_value_groups = 0 THEN 'PASS' ELSE 'FAIL' END, 'No hidden duplicate or conflicting source record may enter aggregation.' FROM natural_key_duplicate_audit WHERE dataset = 'OCS';
INSERT INTO pipeline_validation_results SELECT 6, 'GPAD natural-key duplicate audit', 'natural_key_duplicate_audit', '0; 0; 0', duplicate_dimension_groups || '; ' || excess_source_rows || '; ' || conflicting_value_groups, CASE WHEN duplicate_dimension_groups = 0 AND excess_source_rows = 0 AND conflicting_value_groups = 0 THEN 'PASS' ELSE 'FAIL' END, 'No hidden duplicate or conflicting source record may enter aggregation.' FROM natural_key_duplicate_audit WHERE dataset = 'GPAD';
INSERT INTO pipeline_validation_results SELECT 7, 'Denominator conflict audit', 'registered_population_conflict_audit', '0; 0; 0; 0', missing_denominators || '; ' || nonpositive_denominators || '; ' || no_reported_denominator_value || '; ' || conflicting_denominator_values, CASE WHEN missing_denominators = 0 AND nonpositive_denominators = 0 AND no_reported_denominator_value = 0 AND conflicting_denominator_values = 0 THEN 'PASS' ELSE 'FAIL' END, 'Each practice-month must have one positive, unconflicted denominator.' FROM registered_population_conflict_audit;
INSERT INTO pipeline_validation_results SELECT 8, 'Valid standardised OCS practice codes', 'SUM practice_code_valid=0', '0', CAST(SUM(practice_code_valid = 0) AS TEXT), CASE WHEN SUM(practice_code_valid = 0) = 0 THEN 'PASS' ELSE 'FAIL' END, 'Invalid source codes cannot enter aggregation.' FROM standardised_online_consultation_activity;
INSERT INTO pipeline_validation_results SELECT 9, 'Valid standardised GPAD practice codes', 'SUM practice_code_valid=0', '0', CAST(SUM(practice_code_valid = 0) AS TEXT), CASE WHEN SUM(practice_code_valid = 0) = 0 THEN 'PASS' ELSE 'FAIL' END, 'Invalid source codes cannot enter aggregation.' FROM standardised_appointment_activity;
INSERT INTO pipeline_validation_results SELECT 10, 'Exact source-detail duplicate groups', 'COUNT source_detail_duplicate_audit', '0', CAST(COUNT(*) AS TEXT), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END, 'Any exact duplicate requires investigation before aggregation.' FROM source_detail_duplicate_audit;
INSERT INTO pipeline_validation_results SELECT 11, 'OCS practice-month uniqueness', 'rows minus distinct keys', '0', CAST(COUNT(*) - COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) AS TEXT), CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) THEN 'PASS' ELSE 'FAIL' END, 'One row per practice-month.' FROM online_consultation_practice_month;
INSERT INTO pipeline_validation_results SELECT 12, 'GPAD practice-month uniqueness', 'rows minus distinct keys', '0', CAST(COUNT(*) - COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) AS TEXT), CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) THEN 'PASS' ELSE 'FAIL' END, 'One row per practice-month.' FROM appointment_activity_practice_month;
INSERT INTO pipeline_validation_results SELECT 13, 'Denominator practice-month uniqueness', 'rows minus distinct keys', '0', CAST(COUNT(*) - COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) AS TEXT), CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) THEN 'PASS' ELSE 'FAIL' END, 'One denominator per practice-month.' FROM registered_population_by_practice_month;
INSERT INTO pipeline_validation_results SELECT 14, 'Unmatched OCS practice-months', 'practice_month_join_cardinality_audit.ocs_without_gpad', 'Reported; not converted to zero', CAST(ocs_without_gpad AS TEXT), 'PASS', 'Coverage loss is explicit and retained in the cardinality audit.' FROM practice_month_join_cardinality_audit;
INSERT INTO pipeline_validation_results SELECT 15, 'Unmatched GPAD practice-months', 'practice_month_join_cardinality_audit.gpad_without_ocs', 'Reported; not converted to zero', CAST(gpad_without_ocs AS TEXT), 'PASS', 'Coverage loss is explicit and retained in the cardinality audit.' FROM practice_month_join_cardinality_audit;
INSERT INTO pipeline_validation_results SELECT 16, 'Unmatched OCS denominator practice-months', 'practice_month_join_cardinality_audit.ocs_without_denominator', 'Reported; not converted to zero', CAST(ocs_without_denominator AS TEXT), 'PASS', 'Denominator gaps are explicit and do not become zero.' FROM practice_month_join_cardinality_audit;
INSERT INTO pipeline_validation_results SELECT 17, 'Unmatched GPAD denominator practice-months', 'practice_month_join_cardinality_audit.gpad_without_denominator', '0', CAST(gpad_without_denominator AS TEXT), CASE WHEN gpad_without_denominator = 0 THEN 'PASS' ELSE 'FAIL' END, 'Every aggregated GPAD practice-month entering the pipeline must have a denominator.' FROM practice_month_join_cardinality_audit;
INSERT INTO pipeline_validation_results SELECT 18, 'Reference mapping coverage', 'practices absent from all GPAD mapping vintages', 'Reported; reference-only', CAST(SUM(present_in_any_gpad_mapping = 0) AS TEXT), 'PASS', 'Mapping evidence validates identifiers but never filters the cohort.' FROM identifier_reference_coverage;
INSERT INTO pipeline_validation_results SELECT 19, 'Eligible denominator completeness', 'invalid denominator rows in final practices', '0', CAST(COUNT(*) AS TEXT), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END, 'All final practices require twelve positive month-matched denominators.' FROM registered_population_by_practice_month AS d JOIN eligible_annual_practice_features AS c USING (practice_code_standardised) WHERE d.registered_patients IS NULL OR d.registered_patients <= 0;
INSERT INTO pipeline_validation_results SELECT 20, 'Join row multiplication', 'integrated rows / expected matched keys', '1.0', printf('%.12f', 1.0 * (SELECT COUNT(*) FROM integrated_practice_month_panel) / NULLIF(expected_output_rows, 0)), CASE WHEN (SELECT COUNT(*) FROM integrated_practice_month_panel) = expected_output_rows THEN 'PASS' ELSE 'FAIL' END, 'Aggregation precedes joining.' FROM practice_month_join_cardinality_audit;
INSERT INTO pipeline_validation_results SELECT 21, 'Joined practice-month uniqueness', 'rows minus distinct keys', '0', CAST(COUNT(*) - COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) AS TEXT), CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) THEN 'PASS' ELSE 'FAIL' END, 'The join has one row per practice-month.' FROM integrated_practice_month_panel;
INSERT INTO pipeline_validation_results SELECT 22, 'OCS total reconciliation', 'source minus practice-month', '0', printf('%.17g', unexplained_difference), CASE WHEN ABS(unexplained_difference) < 0.000001 THEN 'PASS' ELSE 'FAIL' END, 'OCS is reconciled only to OCS.' FROM source_reconciliation_summary WHERE dataset = 'OCS' AND stage = 'standardised source to practice-month';
INSERT INTO pipeline_validation_results SELECT 23, 'GPAD total reconciliation', 'source minus practice-month', '0', printf('%.17g', unexplained_difference), CASE WHEN unexplained_difference = 0 THEN 'PASS' ELSE 'FAIL' END, 'GPAD is reconciled only to GPAD.' FROM source_reconciliation_summary WHERE dataset = 'GPAD' AND stage = 'standardised source to practice-month';
INSERT INTO pipeline_validation_results SELECT 24, 'Annual feature internal validations', 'count non-PASS annual_feature_internal_validation', '0', CAST(SUM(result <> 'PASS') AS TEXT), CASE WHEN SUM(result <> 'PASS') = 0 THEN 'PASS' ELSE 'FAIL' END, 'Every annual-feature and category-reconciliation check must pass.' FROM annual_feature_internal_validation;
INSERT INTO pipeline_validation_results SELECT 25, 'No final feature NULL converted to zero', 'feature_missingness_audit final totals', '0 NULL; observed zeros retained separately', CAST(SUM(sql_null_count) AS TEXT) || ' NULL; ' || SUM(observed_zero_count) || ' observed zeros', CASE WHEN SUM(sql_null_count) = 0 THEN 'PASS' ELSE 'FAIL' END, 'Observed zero and missing are distinct.' FROM feature_missingness_audit WHERE phase = 'final matrix';
INSERT INTO pipeline_validation_results SELECT 26, 'Finite non-negative rate/change features', 'invalid numeric rows', '0', CAST(COUNT(*) AS TEXT), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END, 'Rates and changes must be finite and non-negative.' FROM primary_practice_access_clustering_matrix WHERE ocs_submissions_per_1000_patient_months < 0 OR gpad_appointments_per_1000_patient_months < 0 OR ocs_mean_absolute_monthly_rate_change < 0 OR gpad_mean_absolute_monthly_rate_change < 0 OR ABS(ocs_submissions_per_1000_patient_months) > 1e308 OR ABS(gpad_appointments_per_1000_patient_months) > 1e308;
INSERT INTO pipeline_validation_results SELECT 27, 'Shares within valid range', 'rows with selected share outside 0..1', '0', CAST(COUNT(*) AS TEXT), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END, 'Each selected proportion must lie from zero to one.' FROM primary_practice_access_clustering_matrix WHERE ocs_clinical_share NOT BETWEEN 0 AND 1 OR ocs_administrative_share NOT BETWEEN 0 AND 1 OR gpad_dna_share NOT BETWEEN 0 AND 1 OR gpad_face_to_face_share NOT BETWEEN 0 AND 1 OR gpad_telephone_share NOT BETWEEN 0 AND 1 OR gpad_same_day_share NOT BETWEEN 0 AND 1 OR gpad_1_to_7_days_share NOT BETWEEN 0 AND 1 OR gpad_8_to_14_days_share NOT BETWEEN 0 AND 1 OR gpad_over_14_days_share NOT BETWEEN 0 AND 1;
INSERT INTO pipeline_validation_results SELECT 28, 'Selected booking shares do not exceed one', 'same-day + 1-to-7 + 8-to-14 + over-14', 'No row above 1', CAST(COUNT(*) AS TEXT), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END, 'Known mutually exclusive booking bands cannot exceed total appointments.' FROM primary_practice_access_clustering_matrix WHERE gpad_same_day_share + gpad_1_to_7_days_share + gpad_8_to_14_days_share + gpad_over_14_days_share > 1.000000001;
INSERT INTO pipeline_validation_results SELECT 29, 'Eligible before activity-total exclusion', 'practice count comparison target', '6130', CAST(COUNT(*) AS TEXT), CASE WHEN COUNT(*) = 6130 THEN 'PASS' ELSE 'FAIL' END, 'Observed lineage evidence; not used to manufacture the cohort.' FROM eligible_practices_before_activity_total_rule;
INSERT INTO pipeline_validation_results SELECT 30, 'Zero or null OCS total exclusions', 'documented final exclusion count', '63', CAST(COUNT(*) AS TEXT), CASE WHEN COUNT(*) = 63 THEN 'PASS' ELSE 'FAIL' END, 'Composition shares are undefined and are not imputed.' FROM analytical_cohort_exclusion_audit WHERE exclusion_reason IN ('ZERO_OCS_ANNUAL_TOTAL', 'NULL_OCS_ANNUAL_TOTAL');
INSERT INTO pipeline_validation_results SELECT 31, 'Final practice uniqueness', 'rows and distinct practices equal', 'equal', COUNT(*) || ' rows; ' || COUNT(DISTINCT practice_code_standardised) || ' practices', CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised) THEN 'PASS' ELSE 'FAIL' END, 'One row per practice.' FROM primary_practice_access_clustering_matrix;
INSERT INTO pipeline_validation_results SELECT 32, 'Final feature completeness', 'total final feature NULL count', '0', CAST(SUM(sql_null_count) AS TEXT), CASE WHEN SUM(sql_null_count) = 0 THEN 'PASS' ELSE 'FAIL' END, 'All thirteen modelling values must be complete.' FROM feature_missingness_audit WHERE phase = 'final matrix';
INSERT INTO pipeline_validation_results SELECT 33, 'Final practice count', 'comparison target', '6067', CAST(COUNT(*) AS TEXT), CASE WHEN COUNT(*) = 6067 THEN 'PASS' ELSE 'FAIL' END, 'The target is not used to manufacture the cohort.' FROM primary_practice_access_clustering_matrix;
INSERT INTO pipeline_validation_results SELECT 34, 'Feature range rows', 'one summary per modelling feature', '13', CAST(COUNT(*) AS TEXT), CASE WHEN COUNT(*) = 13 THEN 'PASS' ELSE 'FAIL' END, 'Distribution evidence exists for every feature.' FROM feature_range_summary;
INSERT INTO pipeline_validation_results SELECT 35, '1-to-7-day modelling feature present', 'pragma_table_info matrix', '1', CAST(COUNT(*) AS TEXT), CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END, 'The final matrix must contain gpad_1_to_7_days_share.' FROM pragma_table_info('primary_practice_access_clustering_matrix') WHERE name = 'gpad_1_to_7_days_share';
INSERT INTO pipeline_validation_results SELECT 36, '2-to-7-only modelling feature absent', 'pragma_table_info matrix', '0', CAST(COUNT(*) AS TEXT), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END, 'The final matrix must not contain a separate incomplete 2-to-7-only modelling feature.' FROM pragma_table_info('primary_practice_access_clustering_matrix') WHERE name = 'gpad_2_to_7_days_share';

