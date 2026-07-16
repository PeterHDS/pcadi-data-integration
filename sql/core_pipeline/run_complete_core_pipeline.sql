/* ============================================================
   PRIMARY PRACTICE-LEVEL DIGITAL ACCESS AND APPOINTMENT ACTIVITY PIPELINE

   Purpose
   Construct a reproducible twelve-month practice-level clustering matrix
   from Online Consultation System activity, General Practice Appointment
   Data and monthly registered-patient denominators in England.

   Study period
   April 2025 to March 2026 inclusive.

   Tested database engine
   SQLite 3.25 or later; the fresh release build records its exact version.

   Expected final cohort
   6,067 practices, arising from explicit coverage, denominator,
   reconciliation and activity-total rules rather than count-based filtering.

   Final modelling output
   primary_practice_access_clustering_matrix_ordered: one identifier and
   exactly thirteen numerical modelling features.

   Input dependency
   The automated runner imports the twenty-one files in input_manifest.csv
   after Stage 01 and before Stage 02.

   Validation requirement
   Thirty-six substantive validation checks must all PASS. Fresh-run output
   must be canonically reference-equivalent to the frozen validated matrix.

   Portability
   The analytical design is platform-independent; this executable script is
   SQLite-specific. See documentation/SQL_PORTABILITY_NOTES.md.
   ============================================================ */

-- >>> BEGIN STAGE 01_create_raw_source_tables.sql
/* ============================================================
   STAGE 01 - CREATE RAW SOURCE TABLES

   Purpose
   Create text-preserving staging tables for the 21 manifest inputs.

   Inputs
   input_manifest.csv (used by the automated runner after this stage).

   Outputs
   Two OCS activity tables, fourteen GPAD activity tables, five
   reference-only GPAD mapping tables, and pipeline_environment.

   Analytical grain
   Exact source-file rows. No analytical grain is asserted here.

   Rationale
   Raw values are retained as text so that numeric and date conversion
   can be audited explicitly in Stage 02 and Stage 03.

   Key assumptions
   The runner validates each header, checksum and row count against the
   input manifest before analytical transformations are executed.

   Validation gate
   Every required file imports to its named table with the manifest row
   count and declared source schema.

   Expected result
   Twenty-one populated raw tables after the runner imports the files.
   ============================================================ */

PRAGMA foreign_keys = ON;

CREATE TABLE pipeline_environment (
    property_name TEXT PRIMARY KEY,
    property_value TEXT NOT NULL
);

INSERT OR REPLACE INTO pipeline_environment VALUES
    ('study_start', '2025-04-01'),
    ('study_end_exclusive', '2026-04-01'),
    ('expected_months', '12'),
    ('analytical_unit', 'English GP practice'),
    ('practice_key', 'standardised ODS practice code'),
    ('intermediate_key', 'practice_code_standardised + reporting_month'),
    ('tested_database_engine', 'SQLite 3.25 or later');

CREATE TABLE raw_ocs_north (
    MONTH TEXT,
    GP_CODE TEXT,
    GP_NAME TEXT,
    PCN_CODE TEXT,
    PCN_NAME TEXT,
    SUB_ICB_LOCATION_CODE TEXT,
    SUB_ICB_LOCATION_NAME TEXT,
    ICB_CODE TEXT,
    ICB_NAME TEXT,
    REGION_CODE TEXT,
    REGION_NAME TEXT,
    SUPPLIER TEXT,
    METRIC TEXT,
    VALUE TEXT
);

CREATE TABLE raw_ocs_south AS
SELECT * FROM raw_ocs_north WHERE 0;

CREATE TABLE raw_gpad_feb_26 (
    APPOINTMENT_MONTH_START_DATE TEXT,
    GP_CODE TEXT,
    GP_NAME TEXT,
    SUPPLIER TEXT,
    PCN_CODE TEXT,
    PCN_NAME TEXT,
    SUB_ICB_LOCATION_CODE TEXT,
    SUB_ICB_LOCATION_NAME TEXT,
    HCP_TYPE TEXT,
    APPT_MODE TEXT,
    NATIONAL_CATEGORY TEXT,
    TIME_BETWEEN_BOOK_AND_APPT TEXT,
    COUNT_OF_APPOINTMENTS TEXT,
    APPT_STATUS TEXT
);

CREATE TABLE raw_gpad_mar_26_london_east_south AS SELECT * FROM raw_gpad_feb_26 WHERE 0;
CREATE TABLE raw_gpad_mar_26_midlands_north AS SELECT * FROM raw_gpad_feb_26 WHERE 0;
CREATE TABLE raw_gpad_oct_25_london_east_south AS SELECT * FROM raw_gpad_feb_26 WHERE 0;
CREATE TABLE raw_gpad_oct_25_midlands_north AS SELECT * FROM raw_gpad_feb_26 WHERE 0;
CREATE TABLE raw_gpad_nov_25 AS SELECT * FROM raw_gpad_feb_26 WHERE 0;
CREATE TABLE raw_gpad_dec_25 AS SELECT * FROM raw_gpad_feb_26 WHERE 0;
CREATE TABLE raw_gpad_jan_26 AS SELECT * FROM raw_gpad_feb_26 WHERE 0;
CREATE TABLE raw_gpad_apr_25 AS SELECT * FROM raw_gpad_feb_26 WHERE 0;
CREATE TABLE raw_gpad_jun_25 AS SELECT * FROM raw_gpad_feb_26 WHERE 0;
CREATE TABLE raw_gpad_may_25 AS SELECT * FROM raw_gpad_feb_26 WHERE 0;
CREATE TABLE raw_gpad_aug_25 AS SELECT * FROM raw_gpad_feb_26 WHERE 0;
CREATE TABLE raw_gpad_jul_25 AS SELECT * FROM raw_gpad_feb_26 WHERE 0;
CREATE TABLE raw_gpad_sep_25 AS SELECT * FROM raw_gpad_feb_26 WHERE 0;

CREATE TABLE raw_gpad_mapping_apr_26 (
    GP_CODE TEXT,
    GP_NAME TEXT,
    SUPPLIER TEXT,
    PCN_CODE TEXT,
    PCN_NAME TEXT,
    SUB_ICB_LOCATION_CODE TEXT,
    SUB_ICB_LOCATION_NAME TEXT,
    ICB_CODE TEXT,
    ICB_NAME TEXT,
    REGION_CODE TEXT,
    REGION_NAME TEXT
);

CREATE TABLE raw_gpad_mapping_dec_25 AS SELECT * FROM raw_gpad_mapping_apr_26 WHERE 0;
CREATE TABLE raw_gpad_mapping_feb_26 AS SELECT * FROM raw_gpad_mapping_apr_26 WHERE 0;
CREATE TABLE raw_gpad_mapping_jun_25 AS SELECT * FROM raw_gpad_mapping_apr_26 WHERE 0;
CREATE TABLE raw_gpad_mapping_sep_25 AS SELECT * FROM raw_gpad_mapping_apr_26 WHERE 0;
-- <<< END STAGE 01_create_raw_source_tables.sql

-- >>> BEGIN STAGE 02_standardise_source_data.sql
/* ============================================================
   STAGE 02 - STANDARDISE SOURCE DATA

   Purpose
   Union the selected monthly source files, retain provenance, and
   standardise practice codes, reporting months and numeric values.

   Inputs
   All raw_ocs_*, raw_gpad_* and raw_gpad_mapping_* tables.

   Outputs
   standardised_online_consultation_activity,
   standardised_appointment_activity, appointment_mapping_reference.

   Analytical grain
   Source-detail rows; no aggregation is performed in this stage.

   Rationale
   Identifiers, dates and numeric values must be represented consistently
   before source-specific aggregation and integration.

   Key assumptions
   OCS dates use DD/MM/YYYY. GPAD dates use DDMMMYYYY. The fixed analytical
   window is April 2025 to March 2026 inclusive.

   Validation gate
   Twelve months per source, valid standardised practice codes and no
   non-empty numeric source value lost during conversion.

   Expected result
   667,755 OCS rows and 12,305,536 GPAD rows in the fixed window.
   ============================================================ */

DROP VIEW IF EXISTS raw_online_consultation_activity_all;
CREATE VIEW raw_online_consultation_activity_all AS
SELECT
    MONTH,
    GP_CODE,
    GP_NAME,
    PCN_CODE,
    PCN_NAME,
    SUB_ICB_LOCATION_CODE,
    SUB_ICB_LOCATION_NAME,
    ICB_CODE,
    ICB_NAME,
    REGION_CODE,
    REGION_NAME,
    SUPPLIER,
    METRIC,
    VALUE,
    'Submissions via OC Systems in General Practice - May 2026_north_regions.csv' AS source_file
FROM raw_ocs_north
UNION ALL
SELECT
    MONTH,
    GP_CODE,
    GP_NAME,
    PCN_CODE,
    PCN_NAME,
    SUB_ICB_LOCATION_CODE,
    SUB_ICB_LOCATION_NAME,
    ICB_CODE,
    ICB_NAME,
    REGION_CODE,
    REGION_NAME,
    SUPPLIER,
    METRIC,
    VALUE,
    'Submissions via OC Systems in General Practice - May 2026_south_regions.csv'
FROM raw_ocs_south;

DROP TABLE IF EXISTS standardised_online_consultation_activity;
CREATE TABLE standardised_online_consultation_activity AS
SELECT
    MONTH AS reporting_date_original,
    SUBSTR(MONTH, 7, 4) || '-' || SUBSTR(MONTH, 4, 2) || '-' || SUBSTR(MONTH, 1, 2)
        AS reporting_date_standardised,
    SUBSTR(MONTH, 7, 4) || '-' || SUBSTR(MONTH, 4, 2) AS reporting_month,
    GP_CODE AS practice_code_original,
    UPPER(TRIM(GP_CODE)) AS practice_code_standardised,
    CASE
        WHEN UPPER(TRIM(GP_CODE)) GLOB '[A-Z][0-9][0-9][0-9][0-9][0-9]' THEN 1
        ELSE 0
    END AS practice_code_valid,
    GP_NAME,
    PCN_CODE,
    PCN_NAME,
    SUB_ICB_LOCATION_CODE,
    SUB_ICB_LOCATION_NAME,
    ICB_CODE,
    ICB_NAME,
    REGION_CODE,
    REGION_NAME,
    SUPPLIER,
    METRIC,
    VALUE AS value_original,
    CAST(NULLIF(TRIM(VALUE), '') AS REAL) AS value_numeric,
    source_file
FROM raw_online_consultation_activity_all
WHERE LENGTH(TRIM(MONTH)) = 10
  AND SUBSTR(MONTH, 7, 4) || '-' || SUBSTR(MONTH, 4, 2) || '-' || SUBSTR(MONTH, 1, 2) >= '2025-04-01'
  AND SUBSTR(MONTH, 7, 4) || '-' || SUBSTR(MONTH, 4, 2) || '-' || SUBSTR(MONTH, 1, 2) < '2026-04-01'
  AND TRIM(COALESCE(METRIC, '')) <> '';

DROP VIEW IF EXISTS raw_appointment_activity_all;
CREATE VIEW raw_appointment_activity_all AS
SELECT *, 'Practice_Level_Crosstab_Apr_25.csv' AS source_file FROM raw_gpad_apr_25
UNION ALL SELECT *, 'Practice_Level_Crosstab_May_25.csv' FROM raw_gpad_may_25
UNION ALL SELECT *, 'Practice_Level_Crosstab_Jun_25.csv' FROM raw_gpad_jun_25
UNION ALL SELECT *, 'Practice_Level_Crosstab_Jul_25.csv' FROM raw_gpad_jul_25
UNION ALL SELECT *, 'Practice_Level_Crosstab_Aug_25.csv' FROM raw_gpad_aug_25
UNION ALL SELECT *, 'Practice_Level_Crosstab_Sep_25.csv' FROM raw_gpad_sep_25
UNION ALL SELECT *, 'Practice_Level_Crosstab_London_East_South_Oct_25.csv' FROM raw_gpad_oct_25_london_east_south
UNION ALL SELECT *, 'Practice_Level_Crosstab_Midlands_North_Oct_25.csv' FROM raw_gpad_oct_25_midlands_north
UNION ALL SELECT *, 'Practice_Level_Crosstab_Nov_25.csv' FROM raw_gpad_nov_25
UNION ALL SELECT *, 'Practice_Level_Crosstab_Dec_25.csv' FROM raw_gpad_dec_25
UNION ALL SELECT *, 'Practice_Level_Crosstab_Jan_26.csv' FROM raw_gpad_jan_26
UNION ALL SELECT *, 'Practice_Level_Crosstab_Feb_26.csv' FROM raw_gpad_feb_26
UNION ALL SELECT *, 'Practice_Level_Crosstab_London_East_South_Mar_26.csv' FROM raw_gpad_mar_26_london_east_south
UNION ALL SELECT *, 'Practice_Level_Crosstab_Midlands_North_Mar_26.csv' FROM raw_gpad_mar_26_midlands_north;

DROP TABLE IF EXISTS standardised_appointment_activity;
CREATE TABLE standardised_appointment_activity AS
WITH parsed AS (
    SELECT
        *,
        SUBSTR(TRIM(APPOINTMENT_MONTH_START_DATE), 6, 4) || '-' ||
        CASE UPPER(SUBSTR(TRIM(APPOINTMENT_MONTH_START_DATE), 3, 3))
            WHEN 'JAN' THEN '01' WHEN 'FEB' THEN '02' WHEN 'MAR' THEN '03'
            WHEN 'APR' THEN '04' WHEN 'MAY' THEN '05' WHEN 'JUN' THEN '06'
            WHEN 'JUL' THEN '07' WHEN 'AUG' THEN '08' WHEN 'SEP' THEN '09'
            WHEN 'OCT' THEN '10' WHEN 'NOV' THEN '11' WHEN 'DEC' THEN '12'
        END AS reporting_year_month
    FROM raw_appointment_activity_all
)
SELECT
    APPOINTMENT_MONTH_START_DATE AS reporting_date_original,
    reporting_year_month || '-01' AS reporting_date_standardised,
    reporting_year_month AS reporting_month,
    GP_CODE AS practice_code_original,
    UPPER(TRIM(GP_CODE)) AS practice_code_standardised,
    CASE
        WHEN UPPER(TRIM(GP_CODE)) GLOB '[A-Z][0-9][0-9][0-9][0-9][0-9]' THEN 1
        ELSE 0
    END AS practice_code_valid,
    GP_NAME,
    SUPPLIER,
    PCN_CODE,
    PCN_NAME,
    SUB_ICB_LOCATION_CODE,
    SUB_ICB_LOCATION_NAME,
    HCP_TYPE,
    APPT_MODE,
    NATIONAL_CATEGORY,
    TIME_BETWEEN_BOOK_AND_APPT,
    COUNT_OF_APPOINTMENTS AS appointment_count_original,
    CAST(NULLIF(TRIM(COUNT_OF_APPOINTMENTS), '') AS INTEGER) AS appointment_count,
    APPT_STATUS,
    source_file
FROM parsed
WHERE reporting_year_month BETWEEN '2025-04' AND '2026-03';

DROP VIEW IF EXISTS appointment_mapping_reference;
CREATE VIEW appointment_mapping_reference AS
SELECT UPPER(TRIM(GP_CODE)) AS practice_code_standardised, *, 'Apr_26' AS mapping_vintage
FROM raw_gpad_mapping_apr_26
UNION ALL SELECT UPPER(TRIM(GP_CODE)), *, 'Dec_25' FROM raw_gpad_mapping_dec_25
UNION ALL SELECT UPPER(TRIM(GP_CODE)), *, 'Feb_26' FROM raw_gpad_mapping_feb_26
UNION ALL SELECT UPPER(TRIM(GP_CODE)), *, 'Jun_25' FROM raw_gpad_mapping_jun_25
UNION ALL SELECT UPPER(TRIM(GP_CODE)), *, 'Sep_25' FROM raw_gpad_mapping_sep_25;

CREATE INDEX idx_standardised_ocs_practice_month
    ON standardised_online_consultation_activity (practice_code_standardised, reporting_month);

CREATE INDEX idx_standardised_gpad_practice_month
    ON standardised_appointment_activity (practice_code_standardised, reporting_month);
-- <<< END STAGE 02_standardise_source_data.sql

-- >>> BEGIN STAGE 03_validate_source_integrity.sql
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
-- <<< END STAGE 03_validate_source_integrity.sql

-- >>> BEGIN STAGE 04_construct_registered_population_denominators.sql
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
-- <<< END STAGE 04_construct_registered_population_denominators.sql

-- >>> BEGIN STAGE 05_aggregate_online_consultation_activity.sql
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
-- <<< END STAGE 05_aggregate_online_consultation_activity.sql

-- >>> BEGIN STAGE 06_aggregate_appointment_activity.sql
/* ============================================================
   STAGE 06 - AGGREGATE APPOINTMENT ACTIVITY

   Purpose
   Classify and aggregate GPAD source-detail records to one practice-month
   using mutually exclusive status, mode and booking-interval families.

   Inputs
   standardised_appointment_activity.

   Outputs
   appointment_activity_practice_month.

   Analytical grain
   One row per practice per reporting month.

   Rationale
   Each appointment count must contribute once to each independent
   classification family. Explicit booking labels prevent overlap between
   22-to-28-day and more-than-28-day categories.

   Key assumptions
   The official booking labels observed in the selected files are Same Day,
   1 Day, 2 to 7 Days, 8 to 14 Days, 15 to 21 Days, 22 to 28 Days,
   More than 28 Days and Unknown / Data Issue. Unrecognised labels are
   retained in Other rather than silently discarded.

   Validation gate
   Unique practice-month keys; status, mode and booking families each
   reconcile to total appointment counts; no null appointment count enters.

   Expected result
   73,833 rows and 73,833 unique practice-month keys.
   ============================================================ */

DROP TABLE IF EXISTS appointment_activity_practice_month;
CREATE TABLE appointment_activity_practice_month AS
WITH normalised AS (
    SELECT
        practice_code_standardised,
        reporting_month,
        GP_NAME,
        SUPPLIER,
        PCN_CODE,
        SUB_ICB_LOCATION_CODE,
        appointment_count,
        UPPER(TRIM(COALESCE(APPT_STATUS, ''))) AS appointment_status_normalised,
        UPPER(TRIM(COALESCE(APPT_MODE, ''))) AS appointment_mode_normalised,
        UPPER(TRIM(COALESCE(TIME_BETWEEN_BOOK_AND_APPT, ''))) AS booking_interval_normalised
    FROM standardised_appointment_activity
    WHERE practice_code_valid = 1
),
classified AS (
    SELECT
        *,
        CASE
            WHEN appointment_status_normalised = 'ATTENDED' THEN 'ATTENDED'
            WHEN appointment_status_normalised = 'DNA' THEN 'DNA'
            ELSE 'UNKNOWN_OR_OTHER'
        END AS status_group,
        CASE
            WHEN appointment_mode_normalised = 'FACE-TO-FACE' THEN 'FACE_TO_FACE'
            WHEN appointment_mode_normalised = 'TELEPHONE' THEN 'TELEPHONE'
            WHEN appointment_mode_normalised = 'VIDEO CONFERENCE/ONLINE' THEN 'VIDEO_ONLINE'
            WHEN appointment_mode_normalised = 'HOME VISIT' THEN 'HOME_VISIT'
            WHEN appointment_mode_normalised = '' OR appointment_mode_normalised LIKE '%UNKNOWN%' THEN 'UNKNOWN'
            ELSE 'OTHER'
        END AS mode_group,
        CASE
            WHEN booking_interval_normalised = 'SAME DAY' THEN 'SAME_DAY'
            WHEN booking_interval_normalised = '1 DAY' THEN 'ONE_DAY'
            WHEN booking_interval_normalised = '2 TO 7 DAYS' THEN 'TWO_TO_SEVEN_DAYS'
            WHEN booking_interval_normalised = '8  TO 14 DAYS' THEN 'EIGHT_TO_FOURTEEN_DAYS'
            WHEN booking_interval_normalised = '15  TO 21 DAYS' THEN 'FIFTEEN_TO_TWENTY_ONE_DAYS'
            WHEN booking_interval_normalised = '22  TO 28 DAYS' THEN 'TWENTY_TWO_TO_TWENTY_EIGHT_DAYS'
            WHEN booking_interval_normalised = 'MORE THAN 28 DAYS' THEN 'MORE_THAN_TWENTY_EIGHT_DAYS'
            WHEN booking_interval_normalised = '' OR booking_interval_normalised LIKE '%UNKNOWN%' THEN 'UNKNOWN'
            ELSE 'OTHER'
        END AS booking_group
    FROM normalised
)
SELECT
    practice_code_standardised,
    reporting_month,
    MAX(GP_NAME) AS practice_name,
    MAX(PCN_CODE) AS pcn_code,
    MAX(SUB_ICB_LOCATION_CODE) AS sub_icb_code,
    GROUP_CONCAT(DISTINCT SUPPLIER) AS gpad_suppliers,
    COUNT(*) AS source_row_count,
    SUM(appointment_count IS NULL) AS null_appointment_count_rows,
    SUM(appointment_count) AS gpad_total_appointments,
    SUM(CASE WHEN status_group = 'ATTENDED' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_attended,
    SUM(CASE WHEN status_group = 'DNA' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_dna,
    SUM(CASE WHEN status_group = 'UNKNOWN_OR_OTHER' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_status_unknown,
    SUM(CASE WHEN mode_group = 'FACE_TO_FACE' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_face_to_face,
    SUM(CASE WHEN mode_group = 'TELEPHONE' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_telephone,
    SUM(CASE WHEN mode_group = 'VIDEO_ONLINE' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_video_online,
    SUM(CASE WHEN mode_group = 'HOME_VISIT' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_home_visit,
    SUM(CASE WHEN mode_group = 'UNKNOWN' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_mode_unknown,
    SUM(CASE WHEN mode_group = 'OTHER' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_mode_other,
    SUM(CASE WHEN booking_group = 'SAME_DAY' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_same_day,
    SUM(CASE WHEN booking_group = 'ONE_DAY' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_1_day,
    SUM(CASE WHEN booking_group = 'TWO_TO_SEVEN_DAYS' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_2_to_7_days,
    SUM(CASE WHEN booking_group = 'EIGHT_TO_FOURTEEN_DAYS' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_8_to_14_days,
    SUM(CASE WHEN booking_group = 'FIFTEEN_TO_TWENTY_ONE_DAYS' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_15_to_21_days,
    SUM(CASE WHEN booking_group = 'TWENTY_TWO_TO_TWENTY_EIGHT_DAYS' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_22_to_28_days,
    SUM(CASE WHEN booking_group = 'MORE_THAN_TWENTY_EIGHT_DAYS' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_over_28_days,
    SUM(CASE WHEN booking_group = 'UNKNOWN' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_booking_unknown,
    SUM(CASE WHEN booking_group = 'OTHER' THEN COALESCE(appointment_count, 0) ELSE 0 END) AS gpad_booking_other,
    SUM(CASE WHEN status_group = 'ATTENDED' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN status_group = 'DNA' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN status_group = 'UNKNOWN_OR_OTHER' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      - SUM(appointment_count) AS status_reconciliation_difference,
    SUM(CASE WHEN mode_group = 'FACE_TO_FACE' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN mode_group = 'TELEPHONE' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN mode_group = 'VIDEO_ONLINE' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN mode_group = 'HOME_VISIT' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN mode_group = 'UNKNOWN' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN mode_group = 'OTHER' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      - SUM(appointment_count) AS mode_reconciliation_difference,
    SUM(CASE WHEN booking_group = 'SAME_DAY' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN booking_group = 'ONE_DAY' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN booking_group = 'TWO_TO_SEVEN_DAYS' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN booking_group = 'EIGHT_TO_FOURTEEN_DAYS' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN booking_group = 'FIFTEEN_TO_TWENTY_ONE_DAYS' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN booking_group = 'TWENTY_TWO_TO_TWENTY_EIGHT_DAYS' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN booking_group = 'MORE_THAN_TWENTY_EIGHT_DAYS' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN booking_group = 'UNKNOWN' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      + SUM(CASE WHEN booking_group = 'OTHER' THEN COALESCE(appointment_count, 0) ELSE 0 END)
      - SUM(appointment_count) AS booking_reconciliation_difference
FROM classified
GROUP BY practice_code_standardised, reporting_month;

CREATE UNIQUE INDEX ux_appointment_activity_practice_month
    ON appointment_activity_practice_month (practice_code_standardised, reporting_month);
-- <<< END STAGE 06_aggregate_appointment_activity.sql

-- >>> BEGIN STAGE 07_validate_join_cardinality.sql
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
-- <<< END STAGE 07_validate_join_cardinality.sql

-- >>> BEGIN STAGE 08_integrate_practice_month_sources.sql
/* ============================================================
   STAGE 08 - INTEGRATE PRACTICE-MONTH SOURCES

   Purpose
   Combine online-consultation activity, appointment activity and
   registered-patient denominators at practice-month level.

   Inputs
   online_consultation_practice_month,
   appointment_activity_practice_month,
   registered_population_by_practice_month.

   Outputs
   integrated_practice_month_panel.

   Analytical grain
   One row per practice per reporting month.

   Rationale
   Every source is aggregated to its final practice-month grain before
   joining. This prevents many-to-many row multiplication.

   Key assumptions
   The validated inner join retains only observed keys in all three required
   source blocks. Missing source rows are not converted to zero.

   Validation gate
   Unique practice-month keys, no row multiplication, explicit unmatched
   counts and valid month-matched denominators.

   Expected result
   73,833 rows, equal to the matched-key count in Stage 07.
   ============================================================ */

DROP TABLE IF EXISTS integrated_practice_month_panel;
CREATE TABLE integrated_practice_month_panel AS
SELECT
    o.practice_code_standardised,
    o.reporting_month,
    o.practice_name,
    o.pcn_code,
    o.icb_code,
    o.region_code,
    o.ocs_total_submissions,
    o.ocs_clinical_submissions,
    o.ocs_administrative_submissions,
    o.ocs_other_unknown_submissions,
    d.registered_patients,
    CASE WHEN d.registered_patients > 0
         THEN 1000.0 * o.ocs_total_submissions / d.registered_patients END AS ocs_monthly_rate,
    g.gpad_total_appointments,
    g.gpad_attended,
    g.gpad_dna,
    g.gpad_status_unknown,
    g.gpad_face_to_face,
    g.gpad_telephone,
    g.gpad_video_online,
    g.gpad_home_visit,
    g.gpad_mode_unknown,
    g.gpad_mode_other,
    g.gpad_same_day,
    g.gpad_1_day,
    g.gpad_2_to_7_days,
    g.gpad_8_to_14_days,
    g.gpad_15_to_21_days,
    g.gpad_22_to_28_days,
    g.gpad_over_28_days,
    g.gpad_booking_unknown,
    g.gpad_booking_other,
    CASE WHEN d.registered_patients > 0
         THEN 1000.0 * g.gpad_total_appointments / d.registered_patients END AS gpad_monthly_rate
FROM online_consultation_practice_month AS o
JOIN appointment_activity_practice_month AS g
    USING (practice_code_standardised, reporting_month)
JOIN registered_population_by_practice_month AS d
    USING (practice_code_standardised, reporting_month);

CREATE UNIQUE INDEX ux_integrated_practice_month_panel
    ON integrated_practice_month_panel (practice_code_standardised, reporting_month);
-- <<< END STAGE 08_integrate_practice_month_sources.sql

-- >>> BEGIN STAGE 09_construct_annual_features_and_cohort.sql
/* ============================================================
   STAGE 09 - CONSTRUCT ANNUAL FEATURES AND COHORT

   Purpose
   Convert monthly OCS, GPAD and registered-population data into audited
   twelve-month practice features and apply explicit eligibility rules.

   Inputs
   online_consultation_practice_month,
   appointment_activity_practice_month,
   registered_population_by_practice_month.

   Outputs
   annual_population_denominator_audit,
   annual_online_consultation_features,
   annual_appointment_features,
   eligible_practices_before_activity_total_rule,
   candidate_annual_practice_features,
   analytical_cohort_exclusion_audit,
   eligible_annual_practice_features and
   annual_feature_internal_validation.

   Analytical grain
   One row per practice.

   Rationale
   Annual counts are summed from observed monthly counts. Annual rates use
   twelve month-matched registered-patient denominators (patient-months).
   Shares are ratios of annual component totals, not unweighted averages of
   monthly shares. Monthly-rate change uses consecutive observed months.

   Key assumptions
   Eligible practices require twelve OCS months, twelve GPAD months and
   twelve positive, unconflicted denominators. Source component families
   must reconcile. Zero annual OCS activity is retained in an exclusion
   audit because OCS composition shares are undefined; it is not imputed.

   Validation gate
   Unique annual practice keys; complete months; positive denominators;
   OCS, GPAD status, mode and booking reconciliation; complete finite
   analytical features after the documented activity-total rule.

   Expected result
   6,210 annual OCS practices, 6,184 annual GPAD practices, 6,210 annual
   denominator practices, 6,130 eligible before the final activity-total
   rule, 63 documented exclusions and 6,067 final practices.
   ============================================================ */

DROP TABLE IF EXISTS annual_population_denominator_audit;
CREATE TABLE annual_population_denominator_audit AS
WITH monthly AS (
    SELECT
        practice_code_standardised,
        reporting_month,
        registered_patients,
        LAG(registered_patients) OVER (
            PARTITION BY practice_code_standardised
            ORDER BY reporting_month
        ) AS previous_registered_patients
    FROM registered_population_by_practice_month
)
SELECT
    practice_code_standardised,
    COUNT(*) AS months_with_denominator,
    MIN(registered_patients) AS minimum_monthly_list_size,
    MAX(registered_patients) AS maximum_monthly_list_size,
    AVG(registered_patients) AS mean_monthly_list_size,
    SUM(registered_patients) AS annual_patient_month_exposure,
    MAX(ABS(registered_patients - previous_registered_patients)) AS maximum_absolute_monthly_change,
    MAX(
        CASE
            WHEN previous_registered_patients > 0
            THEN ABS(1.0 * (registered_patients - previous_registered_patients) / previous_registered_patients)
        END
    ) AS maximum_proportional_monthly_change,
    100.0 * MAX(
        CASE
            WHEN previous_registered_patients > 0
            THEN ABS(1.0 * (registered_patients - previous_registered_patients) / previous_registered_patients)
        END
    ) AS maximum_percentage_monthly_change,
    SUM(registered_patients IS NULL OR registered_patients <= 0) AS invalid_denominator_months,
    CASE
        WHEN SUM(registered_patients IS NULL OR registered_patients <= 0) > 0 THEN 1
        ELSE 0
    END AS implausible_denominator_flag
FROM monthly
GROUP BY practice_code_standardised;

CREATE UNIQUE INDEX ux_annual_population_denominator_audit
    ON annual_population_denominator_audit (practice_code_standardised);

DROP TABLE IF EXISTS annual_online_consultation_features;
CREATE TABLE annual_online_consultation_features AS
WITH monthly_0 AS (
    SELECT
        o.practice_code_standardised,
        o.reporting_month,
        o.ocs_total_submissions,
        o.ocs_clinical_submissions,
        o.ocs_administrative_submissions,
        o.ocs_other_unknown_submissions,
        d.registered_patients,
        CASE
            WHEN d.registered_patients > 0
            THEN 1000.0 * o.ocs_total_submissions / d.registered_patients
        END AS monthly_rate
    FROM online_consultation_practice_month AS o
    JOIN registered_population_by_practice_month AS d
        USING (practice_code_standardised, reporting_month)
),
monthly AS (
    SELECT
        *,
        LAG(monthly_rate) OVER (
            PARTITION BY practice_code_standardised
            ORDER BY reporting_month
        ) AS prior_rate
    FROM monthly_0
)
SELECT
    practice_code_standardised,
    COUNT(DISTINCT reporting_month) AS ocs_months_observed,
    SUM(ocs_total_submissions IS NOT NULL) AS ocs_total_metric_months,
    SUM(
        ocs_total_submissions IS NOT NULL
        AND ocs_clinical_submissions IS NOT NULL
        AND ocs_administrative_submissions IS NOT NULL
        AND ocs_other_unknown_submissions IS NOT NULL
    ) AS ocs_component_complete_months,
    SUM(ocs_total_submissions) AS ocs_annual_total_submissions,
    SUM(ocs_clinical_submissions) AS ocs_annual_clinical_submissions,
    SUM(ocs_administrative_submissions) AS ocs_annual_administrative_submissions,
    SUM(ocs_other_unknown_submissions) AS ocs_annual_other_unknown_submissions,
    SUM(registered_patients) AS annual_patient_month_exposure,
    AVG(registered_patients) AS mean_monthly_registered_patients,
    1000.0 * SUM(ocs_total_submissions) / NULLIF(SUM(registered_patients), 0)
        AS ocs_submissions_per_1000_patient_months,
    1.0 * SUM(ocs_clinical_submissions) / NULLIF(SUM(ocs_total_submissions), 0)
        AS ocs_clinical_share,
    1.0 * SUM(ocs_administrative_submissions) / NULLIF(SUM(ocs_total_submissions), 0)
        AS ocs_administrative_share,
    1.0 * SUM(ocs_other_unknown_submissions) / NULLIF(SUM(ocs_total_submissions), 0)
        AS ocs_other_unknown_share,
    SUM(ocs_clinical_submissions)
      + SUM(ocs_administrative_submissions)
      + SUM(ocs_other_unknown_submissions)
      - SUM(ocs_total_submissions) AS ocs_component_reconciliation_difference,
    AVG(ABS(monthly_rate - prior_rate)) AS ocs_mean_absolute_monthly_rate_change,
    SUM(registered_patients IS NULL OR registered_patients <= 0) AS ocs_invalid_denominator_months
FROM monthly
GROUP BY practice_code_standardised;

CREATE UNIQUE INDEX ux_annual_online_consultation_features
    ON annual_online_consultation_features (practice_code_standardised);

DROP TABLE IF EXISTS annual_appointment_features;
CREATE TABLE annual_appointment_features AS
WITH monthly_0 AS (
    SELECT
        g.*,
        d.registered_patients,
        CASE
            WHEN d.registered_patients > 0
            THEN 1000.0 * g.gpad_total_appointments / d.registered_patients
        END AS monthly_rate
    FROM appointment_activity_practice_month AS g
    JOIN registered_population_by_practice_month AS d
        USING (practice_code_standardised, reporting_month)
),
monthly AS (
    SELECT
        *,
        LAG(monthly_rate) OVER (
            PARTITION BY practice_code_standardised
            ORDER BY reporting_month
        ) AS prior_rate
    FROM monthly_0
)
SELECT
    practice_code_standardised,
    COUNT(DISTINCT reporting_month) AS gpad_months_observed,
    SUM(gpad_total_appointments IS NOT NULL) AS gpad_total_metric_months,
    SUM(null_appointment_count_rows) AS gpad_null_appointment_count_rows,
    SUM(gpad_total_appointments) AS gpad_annual_total_appointments,
    SUM(gpad_attended) AS gpad_annual_attended,
    SUM(gpad_dna) AS gpad_annual_dna,
    SUM(gpad_status_unknown) AS gpad_annual_status_unknown,
    SUM(gpad_face_to_face) AS gpad_annual_face_to_face,
    SUM(gpad_telephone) AS gpad_annual_telephone,
    SUM(gpad_video_online) AS gpad_annual_video_online,
    SUM(gpad_home_visit) AS gpad_annual_home_visit,
    SUM(gpad_mode_unknown) AS gpad_annual_mode_unknown,
    SUM(gpad_mode_other) AS gpad_annual_mode_other,
    SUM(gpad_same_day) AS gpad_annual_same_day,
    SUM(gpad_1_day) AS gpad_annual_1_day,
    SUM(gpad_2_to_7_days) AS gpad_annual_2_to_7_days,
    SUM(gpad_8_to_14_days) AS gpad_annual_8_to_14_days,
    SUM(gpad_15_to_21_days) AS gpad_annual_15_to_21_days,
    SUM(gpad_22_to_28_days) AS gpad_annual_22_to_28_days,
    SUM(gpad_over_28_days) AS gpad_annual_over_28_days,
    SUM(gpad_15_to_21_days) + SUM(gpad_22_to_28_days) + SUM(gpad_over_28_days)
        AS gpad_annual_over_14_days,
    SUM(gpad_booking_unknown) AS gpad_annual_booking_unknown,
    SUM(gpad_booking_other) AS gpad_annual_booking_other,
    SUM(registered_patients) AS annual_patient_month_exposure,
    1000.0 * SUM(gpad_total_appointments) / NULLIF(SUM(registered_patients), 0)
        AS gpad_appointments_per_1000_patient_months,
    1.0 * SUM(gpad_dna) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_dna_share,
    1.0 * SUM(gpad_face_to_face) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_face_to_face_share,
    1.0 * SUM(gpad_telephone) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_telephone_share,
    1.0 * SUM(gpad_same_day) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_same_day_share,
    1.0 * SUM(gpad_1_day) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_1_day_share,
    1.0 * SUM(gpad_2_to_7_days) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_2_to_7_days_share,
    (
        1.0 * SUM(gpad_1_day) / NULLIF(SUM(gpad_total_appointments), 0)
    ) + (
        1.0 * SUM(gpad_2_to_7_days) / NULLIF(SUM(gpad_total_appointments), 0)
    ) AS gpad_1_to_7_days_share,
    1.0 * SUM(gpad_8_to_14_days) / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_8_to_14_days_share,
    1.0 * (SUM(gpad_same_day) + SUM(gpad_1_day) + SUM(gpad_2_to_7_days))
        / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_within_7_days_share,
    1.0 * (SUM(gpad_15_to_21_days) + SUM(gpad_22_to_28_days) + SUM(gpad_over_28_days))
        / NULLIF(SUM(gpad_total_appointments), 0) AS gpad_over_14_days_share,
    SUM(gpad_attended) + SUM(gpad_dna) + SUM(gpad_status_unknown) - SUM(gpad_total_appointments)
        AS gpad_status_reconciliation_difference,
    SUM(gpad_face_to_face) + SUM(gpad_telephone) + SUM(gpad_video_online)
      + SUM(gpad_home_visit) + SUM(gpad_mode_unknown) + SUM(gpad_mode_other)
      - SUM(gpad_total_appointments) AS gpad_mode_reconciliation_difference,
    SUM(gpad_same_day) + SUM(gpad_1_day) + SUM(gpad_2_to_7_days)
      + SUM(gpad_8_to_14_days) + SUM(gpad_15_to_21_days)
      + SUM(gpad_22_to_28_days) + SUM(gpad_over_28_days)
      + SUM(gpad_booking_unknown) + SUM(gpad_booking_other)
      - SUM(gpad_total_appointments) AS gpad_booking_reconciliation_difference,
    AVG(ABS(monthly_rate - prior_rate)) AS gpad_mean_absolute_monthly_rate_change,
    SUM(registered_patients IS NULL OR registered_patients <= 0) AS gpad_invalid_denominator_months
FROM monthly
GROUP BY practice_code_standardised;

CREATE UNIQUE INDEX ux_annual_appointment_features
    ON annual_appointment_features (practice_code_standardised);

DROP TABLE IF EXISTS eligible_practices_before_activity_total_rule;
CREATE TABLE eligible_practices_before_activity_total_rule AS
SELECT o.practice_code_standardised
FROM annual_online_consultation_features AS o
JOIN annual_appointment_features AS g USING (practice_code_standardised)
JOIN annual_population_denominator_audit AS d USING (practice_code_standardised)
WHERE o.ocs_months_observed = 12
  AND o.ocs_total_metric_months = 12
  AND o.ocs_component_complete_months = 12
  AND ABS(o.ocs_component_reconciliation_difference) < 0.000001
  AND o.ocs_invalid_denominator_months = 0
  AND g.gpad_months_observed = 12
  AND g.gpad_total_metric_months = 12
  AND g.gpad_null_appointment_count_rows = 0
  AND g.gpad_status_reconciliation_difference = 0
  AND g.gpad_mode_reconciliation_difference = 0
  AND g.gpad_booking_reconciliation_difference = 0
  AND g.gpad_invalid_denominator_months = 0
  AND d.months_with_denominator = 12
  AND d.implausible_denominator_flag = 0;

CREATE UNIQUE INDEX ux_eligible_practices_before_activity_total_rule
    ON eligible_practices_before_activity_total_rule (practice_code_standardised);

DROP TABLE IF EXISTS candidate_annual_practice_features;
CREATE TABLE candidate_annual_practice_features AS
SELECT
    o.practice_code_standardised,
    o.ocs_months_observed,
    g.gpad_months_observed,
    d.months_with_denominator,
    d.annual_patient_month_exposure,
    d.mean_monthly_list_size,
    d.maximum_percentage_monthly_change,
    o.ocs_annual_total_submissions,
    o.ocs_annual_clinical_submissions,
    o.ocs_annual_administrative_submissions,
    o.ocs_annual_other_unknown_submissions,
    o.ocs_submissions_per_1000_patient_months,
    o.ocs_clinical_share,
    o.ocs_administrative_share,
    o.ocs_other_unknown_share,
    o.ocs_component_reconciliation_difference,
    o.ocs_mean_absolute_monthly_rate_change,
    g.gpad_annual_total_appointments,
    g.gpad_annual_attended,
    g.gpad_annual_dna,
    g.gpad_annual_status_unknown,
    g.gpad_annual_face_to_face,
    g.gpad_annual_telephone,
    g.gpad_annual_video_online,
    g.gpad_annual_home_visit,
    g.gpad_annual_mode_unknown,
    g.gpad_annual_mode_other,
    g.gpad_annual_same_day,
    g.gpad_annual_1_day,
    g.gpad_annual_2_to_7_days,
    g.gpad_annual_8_to_14_days,
    g.gpad_annual_15_to_21_days,
    g.gpad_annual_22_to_28_days,
    g.gpad_annual_over_28_days,
    g.gpad_annual_over_14_days,
    g.gpad_annual_booking_unknown,
    g.gpad_annual_booking_other,
    g.gpad_appointments_per_1000_patient_months,
    g.gpad_dna_share,
    g.gpad_face_to_face_share,
    g.gpad_telephone_share,
    g.gpad_same_day_share,
    g.gpad_1_day_share,
    g.gpad_2_to_7_days_share,
    g.gpad_1_to_7_days_share,
    g.gpad_8_to_14_days_share,
    g.gpad_within_7_days_share,
    g.gpad_over_14_days_share,
    g.gpad_mean_absolute_monthly_rate_change,
    g.gpad_status_reconciliation_difference,
    g.gpad_mode_reconciliation_difference,
    g.gpad_booking_reconciliation_difference
FROM eligible_practices_before_activity_total_rule AS e
JOIN annual_online_consultation_features AS o USING (practice_code_standardised)
JOIN annual_appointment_features AS g USING (practice_code_standardised)
JOIN annual_population_denominator_audit AS d USING (practice_code_standardised);

CREATE UNIQUE INDEX ux_candidate_annual_practice_features
    ON candidate_annual_practice_features (practice_code_standardised);

DROP TABLE IF EXISTS analytical_cohort_exclusion_audit;
CREATE TABLE analytical_cohort_exclusion_audit AS
SELECT
    practice_code_standardised,
    CASE
        WHEN ocs_annual_total_submissions IS NULL THEN 'NULL_OCS_ANNUAL_TOTAL'
        WHEN ocs_annual_total_submissions <= 0 THEN 'ZERO_OCS_ANNUAL_TOTAL'
        WHEN gpad_annual_total_appointments IS NULL THEN 'NULL_GPAD_ANNUAL_TOTAL'
        WHEN gpad_annual_total_appointments <= 0 THEN 'ZERO_GPAD_ANNUAL_TOTAL'
        ELSE 'NULL_REQUIRED_ANALYTICAL_FEATURE'
    END AS exclusion_reason
FROM candidate_annual_practice_features
WHERE ocs_annual_total_submissions IS NULL
   OR ocs_annual_total_submissions <= 0
   OR gpad_annual_total_appointments IS NULL
   OR gpad_annual_total_appointments <= 0
   OR ocs_submissions_per_1000_patient_months IS NULL
   OR ocs_clinical_share IS NULL
   OR ocs_administrative_share IS NULL
   OR ocs_mean_absolute_monthly_rate_change IS NULL
   OR gpad_appointments_per_1000_patient_months IS NULL
   OR gpad_dna_share IS NULL
   OR gpad_face_to_face_share IS NULL
   OR gpad_telephone_share IS NULL
   OR gpad_same_day_share IS NULL
   OR gpad_1_to_7_days_share IS NULL
   OR gpad_8_to_14_days_share IS NULL
   OR gpad_over_14_days_share IS NULL
   OR gpad_mean_absolute_monthly_rate_change IS NULL;

CREATE UNIQUE INDEX ux_analytical_cohort_exclusion_audit
    ON analytical_cohort_exclusion_audit (practice_code_standardised);

DROP TABLE IF EXISTS eligible_annual_practice_features;
CREATE TABLE eligible_annual_practice_features AS
SELECT c.*
FROM candidate_annual_practice_features AS c
LEFT JOIN analytical_cohort_exclusion_audit AS x USING (practice_code_standardised)
WHERE x.practice_code_standardised IS NULL;

CREATE UNIQUE INDEX ux_eligible_annual_practice_features
    ON eligible_annual_practice_features (practice_code_standardised);

DROP TABLE IF EXISTS annual_feature_internal_validation;
CREATE TABLE annual_feature_internal_validation (
    check_name TEXT PRIMARY KEY,
    expected_value INTEGER NOT NULL,
    actual_value INTEGER NOT NULL,
    result TEXT NOT NULL
);

INSERT INTO annual_feature_internal_validation
SELECT 'denominator_audit_duplicate_practices', 0,
       COUNT(*) - COUNT(DISTINCT practice_code_standardised),
       CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised) THEN 'PASS' ELSE 'FAIL' END
FROM annual_population_denominator_audit
UNION ALL
SELECT 'ocs_annual_duplicate_practices', 0,
       COUNT(*) - COUNT(DISTINCT practice_code_standardised),
       CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised) THEN 'PASS' ELSE 'FAIL' END
FROM annual_online_consultation_features
UNION ALL
SELECT 'gpad_annual_duplicate_practices', 0,
       COUNT(*) - COUNT(DISTINCT practice_code_standardised),
       CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised) THEN 'PASS' ELSE 'FAIL' END
FROM annual_appointment_features
UNION ALL
SELECT 'gpad_status_reconciliation_failures', 0, COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM annual_appointment_features WHERE gpad_status_reconciliation_difference <> 0
UNION ALL
SELECT 'gpad_mode_reconciliation_failures', 0, COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM annual_appointment_features WHERE gpad_mode_reconciliation_difference <> 0
UNION ALL
SELECT 'gpad_booking_reconciliation_failures', 0, COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM annual_appointment_features WHERE gpad_booking_reconciliation_difference <> 0
UNION ALL
SELECT 'eligible_vs_candidate_row_difference', 0,
       ABS((SELECT COUNT(*) FROM eligible_practices_before_activity_total_rule)
           - (SELECT COUNT(*) FROM candidate_annual_practice_features)),
       CASE WHEN (SELECT COUNT(*) FROM eligible_practices_before_activity_total_rule)
                    = (SELECT COUNT(*) FROM candidate_annual_practice_features)
            THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 'final_duplicate_practices', 0,
       COUNT(*) - COUNT(DISTINCT practice_code_standardised),
       CASE WHEN COUNT(*) = COUNT(DISTINCT practice_code_standardised) THEN 'PASS' ELSE 'FAIL' END
FROM eligible_annual_practice_features
UNION ALL
SELECT 'final_zero_ocs_practices', 0, COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM eligible_annual_practice_features WHERE ocs_annual_total_submissions <= 0
UNION ALL
SELECT 'final_zero_gpad_practices', 0, COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM eligible_annual_practice_features WHERE gpad_annual_total_appointments <= 0;
-- <<< END STAGE 09_construct_annual_features_and_cohort.sql

-- >>> BEGIN STAGE 10_create_primary_clustering_matrix.sql
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
-- <<< END STAGE 10_create_primary_clustering_matrix.sql

-- >>> BEGIN STAGE 11_validate_complete_pipeline.sql
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
-- <<< END STAGE 11_validate_complete_pipeline.sql

-- >>> BEGIN STAGE 12_order_export_and_fingerprint.sql
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
-- <<< END STAGE 12_order_export_and_fingerprint.sql

