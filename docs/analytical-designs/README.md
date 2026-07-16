# Choose the table that answers the analytical question

Joining the same sources in different ways changes which practices and months
remain in the result. Choose the population before looking at the findings.
The names below describe the question and retained records directly.

| Analytical purpose | Output | Population retained |
|---|---|---|
| Audit reporting coverage | `multichannel_practice_month_coverage` | Every practice-month observed in at least one source |
| Add appointment context to OCS records | `online_consultation_cohort_with_appointment_context` | All OCS practice-months |
| Add OCS context to appointment records | `appointment_cohort_with_online_consultation_context` | All GPAD practice-months |
| Compare OCS and GPAD where both report | `matched_online_and_scheduled_activity` | OCS-GPAD matched practice-months |
| Compare three separately recorded activities | `matched_multichannel_activity` | OCS-GPAD-CBT matched practice-months |
| Test the CBT-observed subset | `telephony_observed_comparative_cohort` | OCS-GPAD matches with CBT evidence |
| Create a complete annual profile | `annual_practice_access_profiles` | Practices with twelve complete eligible months |
| Examine within-week patterns | Supplementary temporal workflow | Records with compatible validated day/time evidence |

## Reporting coverage across OCS, GPAD and CBT

**Question:** Where is OCS, GPAD or CBT evidence present, and where is a source
absent?

**Table:** `multichannel_practice_month_coverage`

**Population and grain:** One row for every practice-month observed in at least
one source. Source-presence flags distinguish an absent row from a reported
zero.

**Use:** Coverage assessment, provenance review, missingness analysis and the
starting point for question-specific cohorts. This is the broadest
coverage-preserving integration when retaining available evidence matters more
than complete-case comparison.

**Limit:** The three activities are not directly comparable events and are not
added together.

## Appointment context for the OCS reporting population

**Question:** For practice-months reporting OCS, what GPAD evidence is also
available?

**Table:** `online_consultation_cohort_with_appointment_context`

**Population and grain:** Every OCS practice-month, with GPAD and CBT fields
attached when available.

**Use:** Describe appointment context around the OCS reporting population.

**Limit:** GPAD-only practice-months are outside this population.

## OCS context for the GPAD reporting population

**Question:** For practice-months reporting GPAD, what OCS evidence is also
available?

**Table:** `appointment_cohort_with_online_consultation_context`

**Population and grain:** Every GPAD practice-month, with OCS and CBT fields
attached when available.

**Use:** Describe online-consultation context around the GPAD reporting
population.

**Limit:** OCS-only practice-months are outside this population.

## Matched OCS and GPAD activity

**Question:** How do separately recorded OCS and GPAD patterns compare where
both sources report the same practice and month?

**Table:** `matched_online_and_scheduled_activity`

**Population and grain:** One row per practice-month observed in both OCS and
GPAD.

**Use:** Descriptive association, rate comparison and feature engineering that
requires both online-submission and appointment evidence.

**Limit:** The complete-case population can differ systematically from
practices missing either source.

## Matched OCS, GPAD and CBT activity

**Question:** What do the three separately recorded activity patterns look like
where valid OCS, GPAD and CBT evidence all exist?

**Table:** `matched_multichannel_activity`

**Population and grain:** One row per practice-month with OCS, GPAD and validly
mapped CBT evidence.

**Use:** Three-source descriptive comparison.

**Limit:** CBT supplier participation and practice-account mapping can make
this population substantially narrower. Matching does not link individual
patients or events.

## OCS-GPAD comparison in the CBT-observed population

**Question:** Are OCS-GPAD conclusions similar within the subset for which CBT
is observed?

**Table:** `telephony_observed_comparative_cohort`

**Population and grain:** OCS-GPAD matched practice-months with CBT evidence.

**Use:** Sensitivity analysis for the effect of telephony data availability.

**Limit:** It describes a selected reporting population and cannot establish
channel substitution.

## Complete twelve-month practice profiles

**Question:** What is each practice's complete annual pattern across validated
OCS and GPAD features?

**Tables:** `annual_practice_access_profiles` and
`annual_practice_access_modelling_matrix`

**Population and grain:** One row per practice with exactly twelve OCS months,
twelve GPAD months and twelve valid positive monthly denominators. The matrix
contains thirteen numerical features plus a traceability identifier.

**Use:** A documented annual summary and an input for a later modelling stage.

**Limit:** This is available only when a twelve-month configuration explicitly
requests annual features. Proportions are recalculated from annual totals;
missing months are not filled with zero.

## Within-week temporal patterns

**Question:** How are OCS submissions and CBT calls distributed across weekday
and a defensible common time bucket?

**SQL:** `sql/build_within_week_temporal_access.sql`

**Population and grain:** Practice, reporting month, weekday and harmonised
time bucket, followed by a supplementary practice-level temporal summary.

**Use:** Temporal sensitivity analysis when official day/time files and bucket
definitions support the comparison.

**Limit:** This is a separate, evidence-dependent workflow. OCS and CBT time
buckets are harmonised only by aggregation to genuinely shared intervals. The
fixed reference output retains the documented April 2025 Y60 CBT integrity
gap.

All designs describe recorded reporting activity. They do not directly measure
access quality, total demand, unmet need or causal effects.
