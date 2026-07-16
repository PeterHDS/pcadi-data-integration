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

