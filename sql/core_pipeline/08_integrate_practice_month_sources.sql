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

