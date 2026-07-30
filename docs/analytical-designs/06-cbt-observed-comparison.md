# OCS-GPAD comparison within the CBT-observed population

**Question:** Are OCS-GPAD patterns similar in the subset for which valid
telephony evidence is observed?

**Output:** `telephony_observed_comparative_cohort`

**Population and grain:** OCS-GPAD matched practice-months with CBT evidence.

**Join:** Retain the same OCS and GPAD values as the matched two-source table,
then restrict the population using CBT presence and validity.

**Use:** Coverage and selection sensitivity for telephony availability.

**Main limitation:** This selected reporting population does not establish
channel substitution, call-to-appointment conversion or causal effects.

**Validation:** Shared OCS and GPAD values match exactly after alignment by the
practice-month key.
