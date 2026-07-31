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

