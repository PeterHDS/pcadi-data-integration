/* ============================================================
   STAGE 03 - VALIDATE SOURCE INTEGRITY

   Purpose
   Materialise source coverage, numeric-conversion, duplicate and raw
   row-count evidence before any source is aggregated.

   Inputs
   Raw tables and both standardised source-detail tables.

   Outputs
   raw_source_row_count_validation, source_month_validation,
   numeric_conversion_audit, source_detail_duplicate_audit and
   natural_key_duplicate_audit.

   Analytical grain
   Summary evidence by file, source-month or source domain.

   Rationale
   Source defects must be visible before aggregation can conceal them.

   Key assumptions
   Manifest expected counts are comparison targets only; they do not
   filter source rows.

   Validation gate
   Every raw count passes; each source covers twelve fixed months; no
   invalid numeric conversion, exact duplicate or natural-key conflict.

   Expected result
   Twenty-one raw count PASS rows, twenty-four month rows and zero
   duplicate/conflict findings.
   ============================================================ */

DROP TABLE IF EXISTS raw_source_row_count_validation;
CREATE TABLE raw_source_row_count_validation (
    raw_table TEXT PRIMARY KEY,
    expected_rows INTEGER NOT NULL,
    observed_rows INTEGER NOT NULL,
    status TEXT NOT NULL
);

INSERT INTO raw_source_row_count_validation
SELECT 'raw_gpad_apr_25', 999442, COUNT(*), CASE WHEN COUNT(*) = 999442 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_apr_25
UNION ALL SELECT 'raw_gpad_aug_25', 974975, COUNT(*), CASE WHEN COUNT(*) = 974975 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_aug_25
UNION ALL SELECT 'raw_gpad_dec_25', 1027245, COUNT(*), CASE WHEN COUNT(*) = 1027245 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_dec_25
UNION ALL SELECT 'raw_gpad_feb_26', 1015913, COUNT(*), CASE WHEN COUNT(*) = 1015913 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_feb_26
UNION ALL SELECT 'raw_gpad_jan_26', 1047297, COUNT(*), CASE WHEN COUNT(*) = 1047297 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_jan_26
UNION ALL SELECT 'raw_gpad_jul_25', 1028563, COUNT(*), CASE WHEN COUNT(*) = 1028563 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_jul_25
UNION ALL SELECT 'raw_gpad_jun_25', 1003669, COUNT(*), CASE WHEN COUNT(*) = 1003669 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_jun_25
UNION ALL SELECT 'raw_gpad_mar_26_london_east_south', 384919, COUNT(*), CASE WHEN COUNT(*) = 384919 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_mar_26_london_east_south
UNION ALL SELECT 'raw_gpad_mar_26_midlands_north', 671155, COUNT(*), CASE WHEN COUNT(*) = 671155 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_mar_26_midlands_north
UNION ALL SELECT 'raw_gpad_may_25', 991897, COUNT(*), CASE WHEN COUNT(*) = 991897 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_may_25
UNION ALL SELECT 'raw_gpad_nov_25', 1038177, COUNT(*), CASE WHEN COUNT(*) = 1038177 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_nov_25
UNION ALL SELECT 'raw_gpad_oct_25_london_east_south', 393770, COUNT(*), CASE WHEN COUNT(*) = 393770 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_oct_25_london_east_south
UNION ALL SELECT 'raw_gpad_oct_25_midlands_north', 696049, COUNT(*), CASE WHEN COUNT(*) = 696049 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_oct_25_midlands_north
UNION ALL SELECT 'raw_gpad_sep_25', 1032465, COUNT(*), CASE WHEN COUNT(*) = 1032465 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_sep_25
UNION ALL SELECT 'raw_ocs_north', 532746, COUNT(*), CASE WHEN COUNT(*) = 532746 THEN 'PASS' ELSE 'FAIL' END FROM raw_ocs_north
UNION ALL SELECT 'raw_ocs_south', 525699, COUNT(*), CASE WHEN COUNT(*) = 525699 THEN 'PASS' ELSE 'FAIL' END FROM raw_ocs_south
UNION ALL SELECT 'raw_gpad_mapping_apr_26', 6181, COUNT(*), CASE WHEN COUNT(*) = 6181 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_mapping_apr_26
UNION ALL SELECT 'raw_gpad_mapping_dec_25', 6186, COUNT(*), CASE WHEN COUNT(*) = 6186 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_mapping_dec_25
UNION ALL SELECT 'raw_gpad_mapping_feb_26', 6182, COUNT(*), CASE WHEN COUNT(*) = 6182 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_mapping_feb_26
UNION ALL SELECT 'raw_gpad_mapping_jun_25', 6215, COUNT(*), CASE WHEN COUNT(*) = 6215 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_mapping_jun_25
UNION ALL SELECT 'raw_gpad_mapping_sep_25', 6190, COUNT(*), CASE WHEN COUNT(*) = 6190 THEN 'PASS' ELSE 'FAIL' END FROM raw_gpad_mapping_sep_25;

DROP TABLE IF EXISTS source_month_validation;
CREATE TABLE source_month_validation AS
SELECT
    'OCS' AS dataset,
    reporting_month,
    COUNT(*) AS source_rows,
    COUNT(DISTINCT practice_code_standardised) AS practices,
    SUM(practice_code_valid = 0) AS invalid_practice_codes,
    SUM(value_numeric IS NULL) AS null_numeric_values
FROM standardised_online_consultation_activity
GROUP BY reporting_month
UNION ALL
SELECT
    'GPAD',
    reporting_month,
    COUNT(*),
    COUNT(DISTINCT practice_code_standardised),
    SUM(practice_code_valid = 0),
    SUM(appointment_count IS NULL)
FROM standardised_appointment_activity
GROUP BY reporting_month;

DROP TABLE IF EXISTS numeric_conversion_audit;
CREATE TABLE numeric_conversion_audit AS
SELECT
    'OCS' AS dataset,
    SUM(TRIM(COALESCE(value_original, '')) <> '') AS non_empty_numeric_strings,
    SUM(TRIM(COALESCE(value_original, '')) <> '' AND TRIM(value_original) GLOB '*[^0-9.eE+-]*')
        AS suspicious_numeric_strings,
    SUM(TRIM(COALESCE(value_original, '')) <> '' AND value_numeric IS NULL)
        AS non_empty_values_cast_to_null
FROM standardised_online_consultation_activity
UNION ALL
SELECT
    'GPAD',
    SUM(TRIM(COALESCE(appointment_count_original, '')) <> ''),
    SUM(TRIM(COALESCE(appointment_count_original, '')) <> '' AND TRIM(appointment_count_original) GLOB '*[^0-9+-]*'),
    SUM(TRIM(COALESCE(appointment_count_original, '')) <> '' AND appointment_count IS NULL)
FROM standardised_appointment_activity;

DROP TABLE IF EXISTS source_detail_duplicate_audit;
CREATE TABLE source_detail_duplicate_audit AS
SELECT
    'OCS' AS dataset,
    practice_code_standardised,
    reporting_month,
    source_file,
    COUNT(*) AS duplicate_count
FROM standardised_online_consultation_activity
GROUP BY
    practice_code_standardised,
    reporting_month,
    source_file,
    SUPPLIER,
    METRIC,
    value_original
HAVING COUNT(*) > 1
UNION ALL
SELECT
    'GPAD',
    practice_code_standardised,
    reporting_month,
    source_file,
    COUNT(*)
FROM standardised_appointment_activity
GROUP BY
    practice_code_standardised,
    reporting_month,
    source_file,
    GP_NAME,
    SUPPLIER,
    PCN_CODE,
    SUB_ICB_LOCATION_CODE,
    HCP_TYPE,
    APPT_MODE,
    NATIONAL_CATEGORY,
    TIME_BETWEEN_BOOK_AND_APPT,
    appointment_count_original,
    APPT_STATUS
HAVING COUNT(*) > 1;

DROP TABLE IF EXISTS natural_key_duplicate_audit;
CREATE TABLE natural_key_duplicate_audit AS
WITH ocs_groups AS (
    SELECT
        practice_code_standardised,
        reporting_month,
        source_file,
        SUPPLIER,
        METRIC,
        COUNT(*) AS row_count,
        COUNT(DISTINCT value_original) AS value_count
    FROM standardised_online_consultation_activity
    GROUP BY practice_code_standardised, reporting_month, source_file, SUPPLIER, METRIC
),
gpad_groups AS (
    SELECT
        practice_code_standardised,
        reporting_month,
        source_file,
        GP_NAME,
        SUPPLIER,
        PCN_CODE,
        SUB_ICB_LOCATION_CODE,
        HCP_TYPE,
        APPT_MODE,
        NATIONAL_CATEGORY,
        TIME_BETWEEN_BOOK_AND_APPT,
        APPT_STATUS,
        COUNT(*) AS row_count,
        COUNT(DISTINCT appointment_count_original) AS value_count
    FROM standardised_appointment_activity
    GROUP BY
        practice_code_standardised,
        reporting_month,
        source_file,
        GP_NAME,
        SUPPLIER,
        PCN_CODE,
        SUB_ICB_LOCATION_CODE,
        HCP_TYPE,
        APPT_MODE,
        NATIONAL_CATEGORY,
        TIME_BETWEEN_BOOK_AND_APPT,
        APPT_STATUS
)
SELECT
    'OCS' AS dataset,
    SUM(row_count > 1) AS duplicate_dimension_groups,
    SUM(CASE WHEN row_count > 1 THEN row_count - 1 ELSE 0 END) AS excess_source_rows,
    SUM(value_count > 1) AS conflicting_value_groups
FROM ocs_groups
UNION ALL
SELECT
    'GPAD',
    SUM(row_count > 1),
    SUM(CASE WHEN row_count > 1 THEN row_count - 1 ELSE 0 END),
    SUM(value_count > 1)
FROM gpad_groups;

