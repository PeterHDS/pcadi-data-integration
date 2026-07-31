/* ============================================================
   STAGE 04 - CONSTRUCT REGISTERED-POPULATION DENOMINATORS

   Purpose
   Construct one registered-patient denominator per practice-month and
   audit denominator conflicts and reference mapping coverage.

   Inputs
   standardised_online_consultation_activity and
   appointment_mapping_reference.

   Outputs
   registered_population_by_practice_month,
   registered_population_conflict_audit and identifier_reference_coverage.

   Analytical grain
   One row per practice per reporting month; reference coverage is one row
   per observed practice.

   Rationale
   Annual rates use the sum of twelve month-matched practice-list sizes,
   rather than a single annual or end-period denominator.

   Key assumptions
   MAX is applied only after auditing distinct reported denominator values
   at the practice-month grain.

   Validation gate
   Unique keys; no missing, non-positive or conflicting denominators in the
   eligible cohort; mapping evidence remains reference-only.

   Expected result
   74,195 unique practice-month denominators and 26 practices absent from
   all inspected mapping vintages without cohort filtering.
   ============================================================ */

DROP TABLE IF EXISTS registered_population_by_practice_month;
CREATE TABLE registered_population_by_practice_month AS
SELECT
    practice_code_standardised,
    reporting_month,
    MAX(CASE WHEN METRIC = 'PATIENTS_REGISTERED' THEN value_numeric END) AS registered_patients,
    COUNT(DISTINCT CASE WHEN METRIC = 'PATIENTS_REGISTERED' THEN value_numeric END)
        AS distinct_reported_denominator_values,
    COUNT(CASE WHEN METRIC = 'PATIENTS_REGISTERED' THEN 1 END)
        AS denominator_source_rows
FROM standardised_online_consultation_activity
WHERE practice_code_valid = 1
GROUP BY practice_code_standardised, reporting_month;

CREATE UNIQUE INDEX ux_registered_population_practice_month
    ON registered_population_by_practice_month (practice_code_standardised, reporting_month);

DROP TABLE IF EXISTS registered_population_conflict_audit;
CREATE TABLE registered_population_conflict_audit AS
SELECT
    COUNT(*) AS total_practice_months,
    SUM(registered_patients IS NULL) AS missing_denominators,
    SUM(registered_patients <= 0) AS nonpositive_denominators,
    SUM(denominator_source_rows = 0) AS no_reported_denominator_value,
    SUM(distinct_reported_denominator_values > 1) AS conflicting_denominator_values,
    SUM(denominator_source_rows > 1) AS multiple_denominator_source_rows
FROM registered_population_by_practice_month;

DROP TABLE IF EXISTS identifier_reference_coverage;
CREATE TABLE identifier_reference_coverage AS
WITH observed_practices AS (
    SELECT DISTINCT practice_code_standardised
    FROM standardised_online_consultation_activity
    WHERE practice_code_valid = 1
    UNION
    SELECT DISTINCT practice_code_standardised
    FROM standardised_appointment_activity
    WHERE practice_code_valid = 1
),
mapped_practices AS (
    SELECT DISTINCT practice_code_standardised
    FROM appointment_mapping_reference
)
SELECT
    observed_practices.practice_code_standardised,
    CASE WHEN mapped_practices.practice_code_standardised IS NOT NULL THEN 1 ELSE 0 END
        AS present_in_any_gpad_mapping,
    'Reference-only; never used to include or exclude a practice' AS analytical_treatment
FROM observed_practices
LEFT JOIN mapped_practices USING (practice_code_standardised);

