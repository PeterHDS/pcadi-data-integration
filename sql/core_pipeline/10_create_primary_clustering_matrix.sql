/* ============================================================
   STAGE 10 - CREATE PRIMARY CLUSTERING MATRIX

   Purpose
   Select the fixed modelling identifier and exactly thirteen validated
   numerical features from the eligible annual practice table.

   Inputs
   eligible_annual_practice_features.

   Outputs
   primary_practice_access_clustering_matrix.

   Analytical grain
   One row per eligible GP practice.

   Rationale
   The matrix is deliberately narrow and modelling-ready. The practice code
   is retained only for traceability and is not a modelling feature.

   Key assumptions
   The 1-to-7-day feature combines 1-day and 2-to-7-day appointments. OCS
   and GPAD remain separate activity domains and are never added together.

   Validation gate
   6,067 unique practices; fourteen columns; thirteen complete numerical
   features; no invalid shares, negative rates or undefined values.

   Expected result
   6,067 rows, 6,067 unique practice codes and thirteen modelling features.
   ============================================================ */

DROP TABLE IF EXISTS primary_practice_access_clustering_matrix;
CREATE TABLE primary_practice_access_clustering_matrix AS
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
FROM eligible_annual_practice_features;

CREATE UNIQUE INDEX ux_primary_practice_access_clustering_matrix
    ON primary_practice_access_clustering_matrix (practice_code_standardised);

