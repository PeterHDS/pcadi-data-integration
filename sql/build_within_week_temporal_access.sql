/* ============================================================
   TEMPORAL ACCESS SENSITIVITY ANALYSIS

   Purpose
   Align recorded online-consultation submissions and cloud-telephony calls
   at a broad common day/time grain without adding activity across channels.

   Inputs
   ocs_day_time_parts, cbt_day_time_parts, ocs_monthly_denominator and
   cbt_april_y60_affected_practices.

   Analytical period
   April 2025 to March 2026 inclusive.

   Analytical grain
   practice code x reporting month x weekday x harmonised time bucket.

   Integrity rule
   The corrupted April 2025 Y60 cloud-telephony component remains missing.
   It is never converted to zero, repaired or inferred. Affected practices
   are flagged by joining the complete affected-practice register directly.
   ============================================================ */

DROP TABLE IF EXISTS online_consultation_day_time_clean;
CREATE TABLE online_consultation_day_time_clean AS
SELECT
    practice_code_standardised,
    reporting_month,
    weekday,
    harmonised_time_bucket,
    MAX(region_code) AS region_code,
    MAX(icb_code) AS icb_code,
    SUM(ocs_submissions) AS ocs_submissions,
    CASE WHEN COUNT(ocs_clinical_submissions) > 0
         THEN SUM(ocs_clinical_submissions) END AS ocs_clinical_submissions,
    CASE WHEN COUNT(ocs_administrative_submissions) > 0
         THEN SUM(ocs_administrative_submissions) END AS ocs_administrative_submissions,
    CASE WHEN COUNT(ocs_other_unknown_submissions) > 0
         THEN SUM(ocs_other_unknown_submissions) END AS ocs_other_unknown_submissions,
    COUNT(*) AS source_part_rows,
    GROUP_CONCAT(DISTINCT source_file) AS source_files
FROM ocs_day_time_parts
WHERE reporting_month BETWEEN '2025-04' AND '2026-03'
GROUP BY practice_code_standardised, reporting_month, weekday, harmonised_time_bucket;

CREATE UNIQUE INDEX ux_online_consultation_day_time_clean
    ON online_consultation_day_time_clean
       (practice_code_standardised, reporting_month, weekday, harmonised_time_bucket);

DROP TABLE IF EXISTS cloud_telephony_day_time_clean;
CREATE TABLE cloud_telephony_day_time_clean AS
SELECT
    practice_code_standardised,
    reporting_month,
    weekday,
    harmonised_time_bucket,
    MAX(region_code) AS region_code,
    MAX(icb_code) AS icb_code,
    SUM(cbt_inbound_calls) AS cbt_inbound_calls,
    SUM(cbt_ivr_exits) AS cbt_ivr_exits,
    SUM(cbt_answered_calls) AS cbt_answered_calls,
    SUM(cbt_missed_calls) AS cbt_missed_calls,
    SUM(cbt_callback_requests) AS cbt_callback_requests,
    COUNT(*) AS source_part_rows,
    GROUP_CONCAT(DISTINCT source_file) AS source_files
FROM cbt_day_time_parts
WHERE reporting_month BETWEEN '2025-04' AND '2026-03'
GROUP BY practice_code_standardised, reporting_month, weekday, harmonised_time_bucket;

CREATE UNIQUE INDEX ux_cloud_telephony_day_time_clean
    ON cloud_telephony_day_time_clean
       (practice_code_standardised, reporting_month, weekday, harmonised_time_bucket);

/* Coverage-preserving union spine. */
DROP TABLE IF EXISTS temporal_access_union_spine;
CREATE TABLE temporal_access_union_spine AS
SELECT practice_code_standardised, reporting_month, weekday, harmonised_time_bucket
FROM online_consultation_day_time_clean
UNION
SELECT practice_code_standardised, reporting_month, weekday, harmonised_time_bucket
FROM cloud_telephony_day_time_clean;

CREATE UNIQUE INDEX ux_temporal_access_union_spine
    ON temporal_access_union_spine
       (practice_code_standardised, reporting_month, weekday, harmonised_time_bucket);

/* Channel-specific measures remain separate; absent rows remain NULL. */
DROP TABLE IF EXISTS integrated_temporal_access_activity;
CREATE TABLE integrated_temporal_access_activity AS
SELECT
    s.*,
    CASE WHEN o.practice_code_standardised IS NOT NULL THEN 1 ELSE 0 END AS has_online_consultation,
    CASE WHEN c.practice_code_standardised IS NOT NULL THEN 1 ELSE 0 END AS has_cloud_telephony,
    o.ocs_submissions,
    o.ocs_clinical_submissions,
    o.ocs_administrative_submissions,
    o.ocs_other_unknown_submissions,
    c.cbt_inbound_calls,
    c.cbt_answered_calls,
    c.cbt_missed_calls,
    c.cbt_ivr_exits,
    c.cbt_callback_requests,
    COALESCE(o.region_code, c.region_code) AS region_code,
    COALESCE(o.icb_code, c.icb_code) AS icb_code,
    d.ocs_registered_patients,
    CASE WHEN d.ocs_registered_patients > 0
         THEN 1000.0 * o.ocs_submissions / d.ocs_registered_patients END
         AS ocs_submissions_per_1000_registered_patient_month,
    CASE WHEN d.ocs_registered_patients > 0
         THEN 1000.0 * c.cbt_inbound_calls / d.ocs_registered_patients END
         AS cbt_inbound_calls_per_1000_registered_patient_month,
    CASE WHEN i.practice_code_standardised IS NOT NULL
              AND s.reporting_month = '2025-04'
         THEN 1 ELSE 0 END AS cbt_april_y60_integrity_gap_flag
FROM temporal_access_union_spine AS s
LEFT JOIN online_consultation_day_time_clean AS o
  USING (practice_code_standardised, reporting_month, weekday, harmonised_time_bucket)
LEFT JOIN cloud_telephony_day_time_clean AS c
  USING (practice_code_standardised, reporting_month, weekday, harmonised_time_bucket)
LEFT JOIN ocs_monthly_denominator AS d
  USING (practice_code_standardised, reporting_month)
LEFT JOIN cbt_april_y60_affected_practices AS i
  USING (practice_code_standardised);

CREATE UNIQUE INDEX ux_integrated_temporal_access_activity
    ON integrated_temporal_access_activity
       (practice_code_standardised, reporting_month, weekday, harmonised_time_bucket);

/* Limited practice-level sensitivity features. */
DROP TABLE IF EXISTS practice_temporal_access_sensitivity_features;
CREATE TABLE practice_temporal_access_sensitivity_features AS
WITH denominator AS (
    SELECT
        practice_code_standardised,
        COUNT(*) AS denominator_months,
        SUM(ocs_registered_patients) AS patient_month_exposure
    FROM ocs_monthly_denominator
    WHERE reporting_month BETWEEN '2025-04' AND '2026-03'
      AND ocs_registered_patients > 0
    GROUP BY practice_code_standardised
),
online_consultation AS (
    SELECT
        practice_code_standardised,
        COUNT(DISTINCT reporting_month) AS ocs_months,
        SUM(ocs_submissions) AS ocs_total,
        SUM(CASE WHEN harmonised_time_bucket IN ('08:00-09:59', '10:00-11:59')
                 THEN ocs_submissions ELSE 0 END) AS ocs_morning,
        SUM(CASE WHEN harmonised_time_bucket IN ('00:00-05:59', '06:00-07:59', '18:00-23:59')
                 THEN ocs_submissions ELSE 0 END) AS ocs_out_of_hours
    FROM online_consultation_day_time_clean
    GROUP BY practice_code_standardised
),
cloud_telephony AS (
    SELECT
        practice_code_standardised,
        COUNT(DISTINCT reporting_month) AS cbt_months,
        SUM(cbt_inbound_calls) AS cbt_total,
        SUM(CASE WHEN harmonised_time_bucket IN ('08:00-09:59', '10:00-11:59')
                 THEN cbt_inbound_calls ELSE 0 END) AS cbt_morning,
        SUM(CASE WHEN harmonised_time_bucket IN ('00:00-05:59', '06:00-07:59', '18:00-23:59')
                 THEN cbt_inbound_calls ELSE 0 END) AS cbt_out_of_hours
    FROM cloud_telephony_day_time_clean
    GROUP BY practice_code_standardised
),
practice_spine AS (
    SELECT practice_code_standardised FROM online_consultation
    UNION
    SELECT practice_code_standardised FROM cloud_telephony
)
SELECT
    p.practice_code_standardised,
    o.ocs_months,
    c.cbt_months,
    d.denominator_months,
    d.patient_month_exposure,
    o.ocs_total,
    c.cbt_total,
    CASE WHEN d.patient_month_exposure > 0
         THEN 1000.0 * o.ocs_total / d.patient_month_exposure END
         AS ocs_submissions_per_1000_patient_months,
    CASE WHEN d.patient_month_exposure > 0
         THEN 1000.0 * c.cbt_total / d.patient_month_exposure END
         AS cbt_inbound_calls_per_1000_patient_months,
    1.0 * o.ocs_morning / NULLIF(o.ocs_total, 0) AS ocs_morning_share,
    1.0 * c.cbt_morning / NULLIF(c.cbt_total, 0) AS cbt_morning_share,
    1.0 * o.ocs_out_of_hours / NULLIF(o.ocs_total, 0) AS ocs_out_of_hours_share,
    1.0 * c.cbt_out_of_hours / NULLIF(c.cbt_total, 0) AS cbt_out_of_hours_share,
    CASE WHEN i.practice_code_standardised IS NOT NULL THEN 1 ELSE 0 END
         AS cbt_april_y60_integrity_gap_flag
FROM practice_spine AS p
LEFT JOIN online_consultation AS o USING (practice_code_standardised)
LEFT JOIN cloud_telephony AS c USING (practice_code_standardised)
LEFT JOIN denominator AS d USING (practice_code_standardised)
LEFT JOIN cbt_april_y60_affected_practices AS i USING (practice_code_standardised);

CREATE UNIQUE INDEX ux_practice_temporal_access_sensitivity_features
    ON practice_temporal_access_sensitivity_features (practice_code_standardised);
