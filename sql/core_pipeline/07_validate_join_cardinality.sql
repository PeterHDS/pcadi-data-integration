/* ============================================================
   STAGE 07 - VALIDATE JOIN CARDINALITY

   Purpose
   Measure key coverage and expected output cardinality before integrating
   the independently aggregated practice-month tables.

   Inputs
   online_consultation_practice_month,
   appointment_activity_practice_month,
   registered_population_by_practice_month.

   Outputs
   practice_month_join_cardinality_audit.

   Analytical grain
   One summary row for the proposed practice-month inner join.

   Rationale
   Explicit pre-join counts demonstrate that the join cannot multiply rows
   and that unmatched source observations are not manufactured as zeros.

   Key assumptions
   Each input must already be unique by practice and reporting month.

   Validation gate
   Zero duplicate keys; expected matched keys equal the eventual integrated
   row count; unmatched counts are reported separately.

   Expected result
   74,195 OCS rows, 73,833 GPAD rows, 74,195 denominator rows,
   73,833 matched keys, 362 OCS-only keys and no GPAD-only key.
   ============================================================ */

DROP TABLE IF EXISTS practice_month_join_cardinality_audit;
CREATE TABLE practice_month_join_cardinality_audit AS
WITH o AS (
    SELECT practice_code_standardised, reporting_month
    FROM online_consultation_practice_month
),
g AS (
    SELECT practice_code_standardised, reporting_month
    FROM appointment_activity_practice_month
),
d AS (
    SELECT practice_code_standardised, reporting_month
    FROM registered_population_by_practice_month
),
matched AS (
    SELECT o.practice_code_standardised, o.reporting_month
    FROM o
    JOIN g USING (practice_code_standardised, reporting_month)
    JOIN d USING (practice_code_standardised, reporting_month)
)
SELECT
    'OCS_GPAD_DENOMINATOR_INNER_JOIN' AS audit_name,
    (SELECT COUNT(*) FROM o) AS ocs_rows,
    (SELECT COUNT(*) FROM g) AS gpad_rows,
    (SELECT COUNT(*) FROM d) AS denominator_rows,
    (SELECT COUNT(*) FROM matched) AS expected_output_rows,
    (SELECT COUNT(*) FROM o LEFT JOIN g USING (practice_code_standardised, reporting_month)
        WHERE g.practice_code_standardised IS NULL) AS ocs_without_gpad,
    (SELECT COUNT(*) FROM g LEFT JOIN o USING (practice_code_standardised, reporting_month)
        WHERE o.practice_code_standardised IS NULL) AS gpad_without_ocs,
    (SELECT COUNT(*) FROM o LEFT JOIN d USING (practice_code_standardised, reporting_month)
        WHERE d.practice_code_standardised IS NULL) AS ocs_without_denominator,
    (SELECT COUNT(*) FROM g LEFT JOIN d USING (practice_code_standardised, reporting_month)
        WHERE d.practice_code_standardised IS NULL) AS gpad_without_denominator,
    (SELECT COUNT(*) FROM o) - (SELECT COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) FROM o)
        AS ocs_duplicate_keys,
    (SELECT COUNT(*) FROM g) - (SELECT COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) FROM g)
        AS gpad_duplicate_keys,
    (SELECT COUNT(*) FROM d) - (SELECT COUNT(DISTINCT practice_code_standardised || '|' || reporting_month) FROM d)
        AS denominator_duplicate_keys;

