/* ============================================================
   STAGE 05 - AGGREGATE ONLINE-CONSULTATION ACTIVITY

   Purpose
   Aggregate OCS source-detail records to one practice-month while
   preserving reported totals, components, participation evidence and
   month-matched registered-patient counts.

   Inputs
   standardised_online_consultation_activity.

   Outputs
   online_consultation_practice_month.

   Analytical grain
   One row per practice per reporting month.

   Rationale
   Source-specific aggregation before joining prevents many-to-many row
   multiplication and keeps OCS activity distinct from appointment data.

   Key assumptions
   Submission measures are summed across supplier rows; registered patients
   use the audited practice-month denominator rule; absent metrics remain
   NULL and are not converted to zero.

   Validation gate
   Unique practice-month keys, fixed date coverage, and component-to-total
   reconciliation at the annual eligibility stage.

   Expected result
   74,195 rows and 74,195 unique practice-month keys.
   ============================================================ */

DROP TABLE IF EXISTS online_consultation_practice_month;
CREATE TABLE online_consultation_practice_month AS
SELECT
    practice_code_standardised,
    reporting_month,
    MAX(GP_NAME) AS practice_name,
    MAX(PCN_CODE) AS pcn_code,
    MAX(ICB_CODE) AS icb_code,
    MAX(REGION_CODE) AS region_code,
    GROUP_CONCAT(DISTINCT NULLIF(TRIM(SUPPLIER), '')) AS ocs_suppliers,
    MAX(CASE WHEN METRIC = 'OC_CAPABILITY' THEN value_numeric END) AS ocs_capability_flag,
    MAX(CASE WHEN METRIC = 'OC_PARTICIPATION' THEN value_numeric END) AS ocs_participation_flag,
    MAX(CASE WHEN METRIC = 'OC_SYSTEM_USAGE' THEN value_numeric END) AS ocs_system_usage_flag,
    SUM(CASE WHEN METRIC = 'OC_TOTAL_SUBMISSIONS' THEN value_numeric END) AS ocs_total_submissions,
    SUM(CASE WHEN METRIC = 'OC_SUBMISSION_TYPE_CLINICAL' THEN value_numeric END) AS ocs_clinical_submissions,
    SUM(CASE WHEN METRIC = 'OC_SUBMISSION_TYPE_ADMIN' THEN value_numeric END) AS ocs_administrative_submissions,
    SUM(CASE WHEN METRIC = 'OC_SUBMISSION_TYPE_OTHER' THEN value_numeric END) AS ocs_other_unknown_submissions,
    MAX(CASE WHEN METRIC = 'PATIENTS_REGISTERED' THEN value_numeric END) AS registered_patients,
    CASE
        WHEN MAX(CASE WHEN METRIC = 'PATIENTS_REGISTERED' THEN value_numeric END) > 0
        THEN 1000.0 * SUM(CASE WHEN METRIC = 'OC_TOTAL_SUBMISSIONS' THEN value_numeric END)
             / MAX(CASE WHEN METRIC = 'PATIENTS_REGISTERED' THEN value_numeric END)
    END AS ocs_monthly_rate,
    MAX(
        CASE
            WHEN UPPER(TRIM(COALESCE(SUPPLIER, ''))) IN ('', 'NONE', 'UNKNOWN', 'NONE/UNKNOWN')
            THEN 1 ELSE 0
        END
    ) AS ocs_unknown_supplier_flag,
    COUNT(*) AS source_row_count
FROM standardised_online_consultation_activity
WHERE practice_code_valid = 1
GROUP BY practice_code_standardised, reporting_month;

CREATE UNIQUE INDEX ux_online_consultation_practice_month
    ON online_consultation_practice_month (practice_code_standardised, reporting_month);

