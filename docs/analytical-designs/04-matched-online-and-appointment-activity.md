# Matched online consultation and appointment activity

**Question:** How do OCS and GPAD measures compare where both sources report
for the same practice and month?

**Output:** `matched_online_and_scheduled_activity`

**Population and grain:** Practice-months with both OCS and GPAD evidence.

**Join:** Filter the validated coverage spine to OCS present and GPAD present.
Activity values are inherited without recalculation.

**Use:** Descriptive association, rate comparison and annual feature
construction requiring both sources.

**Main limitation:** Complete-case restriction can select a population that
differs from practices missing either source.

**Validation:** Keys remain unique, inherited values match the source-led
tables and the output count equals the number of spine rows with both presence
flags.
