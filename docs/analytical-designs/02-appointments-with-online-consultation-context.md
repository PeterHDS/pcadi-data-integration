# Appointment records with online consultation context

**Question:** For each practice-month reporting GPAD activity, what OCS and CBT
evidence is also available?

**Output:** `appointment_cohort_with_online_consultation_context`

**Population and grain:** Every GPAD practice-month. The unique key is practice
code plus reporting month.

**Join:** GPAD defines the rows. OCS and CBT are left-joined on the shared key.

**Use:** Describe online-consultation and telephony context around the
appointment-reporting population.

**Main limitation:** OCS-only practice-months are outside this output.

**Validation:** GPAD row count is retained, keys remain unique, source totals
do not change and the multiplication factor is 1.0.
