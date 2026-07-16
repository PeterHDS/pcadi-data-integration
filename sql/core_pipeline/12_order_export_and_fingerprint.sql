/* ============================================================
   STAGE 12 - ORDER, EXPORT AND FINGERPRINT

   Purpose
   Create a deterministic ordered matrix and canonical full-precision lines
   for export and reference-equivalence testing.

   Inputs
   primary_practice_access_clustering_matrix and
   pipeline_validation_results.

   Outputs
   primary_practice_access_clustering_matrix_ordered,
   modelling_output_fingerprint and export_metadata.

   Analytical grain
   One ordered row and one canonical fingerprint line per eligible practice.

   Rationale
   Deterministic ordering and SQLite printf('%.17g') representations allow
   exact comparison across fresh executions without relying on CSV display
   rounding.

   Key assumptions
   Export uses the fixed feature order and practice code is traceability
   metadata, not a modelling feature.

   Validation gate
   All thirty-six validation rows PASS before release; ordered and unordered
   practice sets are identical; 6,067 canonical lines are generated.

   Expected result
   6,067 ordered rows and 6,067 unique canonical fingerprint lines.
   ============================================================ */

DROP TABLE IF EXISTS primary_practice_access_clustering_matrix_ordered;
CREATE TABLE primary_practice_access_clustering_matrix_ordered AS
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
FROM primary_practice_access_clustering_matrix
ORDER BY practice_code_standardised;

CREATE UNIQUE INDEX ux_primary_practice_access_clustering_matrix_ordered
    ON primary_practice_access_clustering_matrix_ordered (practice_code_standardised);

DROP TABLE IF EXISTS modelling_output_fingerprint;
CREATE TABLE modelling_output_fingerprint AS
SELECT
    practice_code_standardised,
    practice_code_standardised || '|'
      || printf('%.17g', ocs_submissions_per_1000_patient_months) || '|'
      || printf('%.17g', ocs_clinical_share) || '|'
      || printf('%.17g', ocs_administrative_share) || '|'
      || printf('%.17g', gpad_appointments_per_1000_patient_months) || '|'
      || printf('%.17g', gpad_dna_share) || '|'
      || printf('%.17g', gpad_face_to_face_share) || '|'
      || printf('%.17g', gpad_telephone_share) || '|'
      || printf('%.17g', gpad_same_day_share) || '|'
      || printf('%.17g', gpad_1_to_7_days_share) || '|'
      || printf('%.17g', gpad_8_to_14_days_share) || '|'
      || printf('%.17g', gpad_over_14_days_share) || '|'
      || printf('%.17g', ocs_mean_absolute_monthly_rate_change) || '|'
      || printf('%.17g', gpad_mean_absolute_monthly_rate_change)
        AS canonical_line
FROM primary_practice_access_clustering_matrix_ordered
ORDER BY practice_code_standardised;

CREATE UNIQUE INDEX ux_modelling_output_fingerprint
    ON modelling_output_fingerprint (practice_code_standardised);

DROP TABLE IF EXISTS export_metadata;
CREATE TABLE export_metadata AS
SELECT 'matrix_rows' AS property, CAST(COUNT(*) AS TEXT) AS value
FROM primary_practice_access_clustering_matrix_ordered
UNION ALL
SELECT 'matrix_columns', CAST(COUNT(*) AS TEXT)
FROM pragma_table_info('primary_practice_access_clustering_matrix_ordered')
UNION ALL
SELECT 'modelling_features', '13'
UNION ALL
SELECT 'numeric_export_precision', '17 significant digits'
UNION ALL
SELECT 'validation_passes', CAST(SUM(result = 'PASS') AS TEXT)
FROM pipeline_validation_results
UNION ALL
SELECT 'validation_failures', CAST(SUM(result <> 'PASS') AS TEXT)
FROM pipeline_validation_results;

