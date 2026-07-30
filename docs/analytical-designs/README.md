# Choose an analytical design

Each design answers a different question because it retains a different
population. Select the population before interpreting measures.

| Analytical design | Grain | Population retained |
|---|---|---|
| [Online consultation records with appointment context](01-online-consultation-with-appointment-context.md) | practice-month | all OCS records |
| [Appointment records with online consultation context](02-appointments-with-online-consultation-context.md) | practice-month | all GPAD records |
| [Coverage-preserving OCS, GPAD and CBT practice-month spine](03-coverage-preserving-multichannel-spine.md) | practice-month | union of observed source keys |
| [Matched online consultation and appointment activity](04-matched-online-and-appointment-activity.md) | practice-month | OCS and GPAD both observed |
| [Matched OCS, GPAD and valid CBT activity](05-matched-multichannel-activity.md) | practice-month | all three sources validly observed |
| [OCS-GPAD comparison within the CBT-observed population](06-cbt-observed-comparison.md) | practice-month | OCS-GPAD matches with CBT evidence |
| [National annual OCS-GPAD access-activity profile matrix](07-national-annual-profile.md) | practice | 6,067 complete annual practices |
| [CBT inbound restricted-cohort access-profile matrix](08-cbt-inbound-restricted-profile.md) | practice | 3,020 CBT inbound-complete practices |
| [CBT outcome-complete restricted-cohort access-profile matrix](09-cbt-outcome-complete-profile.md) | practice | 1,456 CBT outcome-complete practices |
| [Within-week online consultation and telephony timing](10-within-week-timing.md) | practice-month-weekday-time bucket | compatible OCS and CBT day/time evidence |

The [join guide](../HOW_THE_JOINS_WORK.md) explains the shared key,
cardinality controls and annual calculation rules.
