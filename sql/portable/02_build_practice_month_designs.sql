/*
Purpose: integrate independently prepared OCS, GPAD and CBT source blocks.
Inputs: the three canonical source tables and pipeline_config.
Output grain: one row per practice code and reporting month.
Join rule: sources are attached to a UNION spine on practice code plus month.
Cardinality: each source must be unique before this block runs; no activity
measure is added across OCS, GPAD and CBT and absent records remain NULL.
*/

DROP VIEW IF EXISTS analysis_window;
CREATE VIEW analysis_window AS
SELECT
    MAX(CASE WHEN property_name = 'analysis_start_month' THEN property_value END) AS start_month,
    MAX(CASE WHEN property_name = 'analysis_end_month' THEN property_value END) AS end_month,
    CAST(MAX(CASE WHEN property_name = 'expected_months' THEN property_value END) AS INTEGER) AS expected_months,
    CASE WHEN LOWER(MAX(CASE WHEN property_name = 'annual_features' THEN property_value END)) = 'true'
         THEN 1 ELSE 0 END AS annual_features_enabled
FROM pipeline_config;

DROP TABLE IF EXISTS online_consultation_practice_month;
CREATE TABLE online_consultation_practice_month AS
SELECT
    o.*,
    CASE WHEN registered_patients > 0 AND total_submissions IS NOT NULL
         THEN 1000.0 * total_submissions / registered_patients END
         AS submissions_per_1000_registered_patients,
    CASE WHEN total_submissions IS NOT NULL
              AND clinical_submissions IS NOT NULL
              AND administrative_submissions IS NOT NULL
              AND other_unknown_submissions IS NOT NULL
         THEN total_submissions - clinical_submissions
              - administrative_submissions - other_unknown_submissions END
         AS component_reconciliation_difference
FROM online_consultation_source AS o, analysis_window AS w
WHERE o.reporting_month BETWEEN w.start_month AND w.end_month;

CREATE UNIQUE INDEX ux_online_consultation_practice_month
    ON online_consultation_practice_month (practice_code_standardised, reporting_month);

DROP TABLE IF EXISTS appointment_activity_practice_month;
CREATE TABLE appointment_activity_practice_month AS
SELECT
    g.*,
    CASE WHEN total_appointments IS NOT NULL
         THEN total_appointments - COALESCE(attended, 0) - COALESCE(dna, 0)
              - COALESCE(status_unknown, 0) END AS status_reconciliation_difference,
    CASE WHEN total_appointments IS NOT NULL
         THEN total_appointments - COALESCE(face_to_face, 0) - COALESCE(telephone, 0)
              - COALESCE(video_online, 0) - COALESCE(home_visit, 0)
              - COALESCE(mode_unknown, 0) - COALESCE(mode_other, 0) END
         AS mode_reconciliation_difference,
    CASE WHEN total_appointments IS NOT NULL
         THEN total_appointments - COALESCE(same_day, 0) - COALESCE(one_day, 0)
              - COALESCE(two_to_seven_days, 0) - COALESCE(eight_to_fourteen_days, 0)
              - COALESCE(fifteen_to_twenty_one_days, 0)
              - COALESCE(twenty_two_to_twenty_eight_days, 0)
              - COALESCE(more_than_twenty_eight_days, 0)
              - COALESCE(booking_unknown, 0) - COALESCE(booking_other, 0) END
         AS booking_reconciliation_difference
FROM appointment_activity_source AS g, analysis_window AS w
WHERE g.reporting_month BETWEEN w.start_month AND w.end_month;

CREATE UNIQUE INDEX ux_appointment_activity_practice_month
    ON appointment_activity_practice_month (practice_code_standardised, reporting_month);

DROP TABLE IF EXISTS cloud_telephony_practice_month;
CREATE TABLE cloud_telephony_practice_month AS
SELECT c.*
FROM cloud_telephony_source AS c, analysis_window AS w
WHERE c.reporting_month BETWEEN w.start_month AND w.end_month;

CREATE UNIQUE INDEX ux_cloud_telephony_practice_month
    ON cloud_telephony_practice_month (practice_code_standardised, reporting_month);

DROP TABLE IF EXISTS practice_month_union_spine;
CREATE TABLE practice_month_union_spine AS
SELECT practice_code_standardised, reporting_month FROM online_consultation_practice_month
UNION
SELECT practice_code_standardised, reporting_month FROM appointment_activity_practice_month
UNION
SELECT practice_code_standardised, reporting_month FROM cloud_telephony_practice_month;

CREATE UNIQUE INDEX ux_practice_month_union_spine
    ON practice_month_union_spine (practice_code_standardised, reporting_month);

DROP TABLE IF EXISTS multichannel_practice_month_coverage;
CREATE TABLE multichannel_practice_month_coverage AS
SELECT
    s.practice_code_standardised,
    s.reporting_month,
    CASE WHEN o.practice_code_standardised IS NOT NULL THEN 1 ELSE 0 END AS has_online_consultation,
    CASE WHEN g.practice_code_standardised IS NOT NULL THEN 1 ELSE 0 END AS has_appointment_activity,
    CASE WHEN c.practice_code_standardised IS NOT NULL THEN 1 ELSE 0 END AS has_cloud_telephony,
    o.registered_patients,
    o.total_submissions AS ocs_total_submissions,
    o.clinical_submissions AS ocs_clinical_submissions,
    o.administrative_submissions AS ocs_administrative_submissions,
    o.other_unknown_submissions AS ocs_other_unknown_submissions,
    o.submissions_per_1000_registered_patients AS ocs_submissions_per_1000,
    o.participation_flag AS ocs_participation_flag,
    o.unknown_supplier_flag AS ocs_unknown_supplier_flag,
    o.component_reconciliation_difference AS ocs_component_reconciliation_difference,
    g.total_appointments AS gpad_total_appointments,
    g.attended AS gpad_attended,
    g.dna AS gpad_dna,
    g.status_unknown AS gpad_status_unknown,
    g.face_to_face AS gpad_face_to_face,
    g.telephone AS gpad_telephone,
    g.video_online AS gpad_video_online,
    g.home_visit AS gpad_home_visit,
    g.mode_unknown AS gpad_mode_unknown,
    g.mode_other AS gpad_mode_other,
    g.same_day AS gpad_same_day,
    g.one_day AS gpad_one_day,
    g.two_to_seven_days AS gpad_two_to_seven_days,
    g.eight_to_fourteen_days AS gpad_eight_to_fourteen_days,
    g.fifteen_to_twenty_one_days AS gpad_fifteen_to_twenty_one_days,
    g.twenty_two_to_twenty_eight_days AS gpad_twenty_two_to_twenty_eight_days,
    g.more_than_twenty_eight_days AS gpad_more_than_twenty_eight_days,
    g.booking_unknown AS gpad_booking_unknown,
    g.booking_other AS gpad_booking_other,
    g.status_reconciliation_difference AS gpad_status_reconciliation_difference,
    g.mode_reconciliation_difference AS gpad_mode_reconciliation_difference,
    g.booking_reconciliation_difference AS gpad_booking_reconciliation_difference,
    c.inbound_calls AS cbt_inbound_calls,
    c.answered_calls AS cbt_answered_calls,
    c.missed_calls AS cbt_missed_calls,
    c.ivr_exits AS cbt_ivr_exits,
    c.callback_requests AS cbt_callback_requests,
    c.mapping_valid AS cbt_mapping_valid,
    c.integrity_gap_flag AS cbt_integrity_gap_flag
FROM practice_month_union_spine AS s
LEFT JOIN online_consultation_practice_month AS o
  USING (practice_code_standardised, reporting_month)
LEFT JOIN appointment_activity_practice_month AS g
  USING (practice_code_standardised, reporting_month)
LEFT JOIN cloud_telephony_practice_month AS c
  USING (practice_code_standardised, reporting_month);

CREATE UNIQUE INDEX ux_multichannel_practice_month_coverage
    ON multichannel_practice_month_coverage (practice_code_standardised, reporting_month);

DROP VIEW IF EXISTS online_consultation_cohort_with_appointment_context;
CREATE VIEW online_consultation_cohort_with_appointment_context AS
SELECT * FROM multichannel_practice_month_coverage WHERE has_online_consultation = 1;

DROP VIEW IF EXISTS appointment_cohort_with_online_consultation_context;
CREATE VIEW appointment_cohort_with_online_consultation_context AS
SELECT * FROM multichannel_practice_month_coverage WHERE has_appointment_activity = 1;

DROP VIEW IF EXISTS matched_online_and_scheduled_activity;
CREATE VIEW matched_online_and_scheduled_activity AS
SELECT * FROM multichannel_practice_month_coverage
WHERE has_online_consultation = 1 AND has_appointment_activity = 1;

DROP VIEW IF EXISTS matched_multichannel_activity;
CREATE VIEW matched_multichannel_activity AS
SELECT * FROM multichannel_practice_month_coverage
WHERE has_online_consultation = 1
  AND has_appointment_activity = 1
  AND has_cloud_telephony = 1
  AND cbt_mapping_valid = 1;

DROP VIEW IF EXISTS telephony_observed_comparative_cohort;
CREATE VIEW telephony_observed_comparative_cohort AS
SELECT * FROM matched_online_and_scheduled_activity
WHERE has_cloud_telephony = 1;
