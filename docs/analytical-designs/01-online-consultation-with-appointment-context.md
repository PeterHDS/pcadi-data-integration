# Online consultation records with appointment context

**Question:** For each practice-month reporting OCS activity, what GPAD and CBT
evidence is also available?

**Output:** `online_consultation_cohort_with_appointment_context`

**Population and grain:** Every OCS practice-month. The unique key is
`practice_code_standardised + reporting_month`.

**Join:** OCS defines the rows. GPAD and CBT are left-joined on practice code
plus month.

**Use:** Describe appointment and telephony context around the OCS-reporting
population and audit attached-source availability.

**Main limitation:** GPAD-only practice-months are outside this output. A blank
attached field means no matched source evidence, not zero activity.

**Validation:** OCS row count is retained, keys remain unique, source totals do
not change and the join-multiplication factor is 1.0.
