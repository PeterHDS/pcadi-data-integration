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

