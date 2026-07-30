# Analytical design index

PCADI creates several outputs because one join cannot preserve every source
population and answer every analytical question. Choose the retained population
before choosing the table.

## Coverage and source-led views

| Question | Retained population | Grain | Sources | Output | Principal limitation |
|---|---|---|---|---|---|
| What appointment context is available for OCS records? | OCS-reported keys | Practice-month | OCS, GPAD | `online_consultation_led_appointment_alignment` | GPAD may be absent |
| What OCS context is available for appointment records? | GPAD-reported keys | Practice-month | GPAD, OCS | `appointment_led_online_consultation_alignment` | OCS may be absent |
| Where does each activity source report or remain absent? | Union of OCS, GPAD and CBT keys | Practice-month | OCS, GPAD, CBT | `multichannel_practice_month_coverage` | Presence is not activity |

- [Online consultation records with appointment context](01-online-consultation-with-appointment-context.md)
- [Appointment records with online consultation context](02-appointments-with-online-consultation-context.md)
- [Coverage-preserving OCS, GPAD and CBT practice-month spine](03-coverage-preserving-multichannel-spine.md)

## Matched activity views

| Question | Retained population | Grain | Sources | Output | Principal limitation |
|---|---|---|---|---|---|
| How do OCS and GPAD compare where both report? | Matched OCS-GPAD keys | Practice-month | OCS, GPAD | `matched_online_and_scheduled_activity` | Excludes unmatched reporting |
| What evidence is available where all three sources match? | Matched OCS-GPAD keys with valid CBT | Practice-month | OCS, GPAD, CBT | `matched_multichannel_activity` | CBT reporting narrows coverage |
| How do OCS-GPAD patterns look within the CBT-observed population? | CBT-observed matched keys | Practice-month | OCS, GPAD, CBT | `telephony_observed_comparative_cohort` | Restricted population |

- [Matched online consultation and appointment activity](04-matched-online-and-appointment-activity.md)
- [Matched OCS, GPAD and valid CBT activity](05-matched-multichannel-activity.md)
- [OCS-GPAD comparison within the CBT-observed population](06-cbt-observed-comparison.md)

## Annual practice-level matrices

These designs require exactly twelve complete eligible months under the current
contract.

| Question | Retained population | Grain | Sources | Output | Principal limitation |
|---|---|---|---|---|---|
| What is each eligible practice's annual OCS-GPAD activity profile? | 6,067 eligible practices in the reference application | Practice | OCS, GPAD, registered patients | `primary_practice_access_clustering_matrix.csv` | Strict annual completeness |
| What CBT inbound evidence can extend the annual profile? | 3,020 nested practices with valid CBT inbound evidence | Practice | OCS, GPAD, CBT | `cbt_inbound_sensitivity_clustering_matrix_17_features.csv` | Restricted evidence cohort |
| What complete CBT outcomes can extend the annual profile? | 1,456 nested practices with complete CBT outcomes | Practice | OCS, GPAD, CBT | `cbt_outcomes_sensitivity_clustering_matrix_21_features.csv` | Smallest evidence cohort |

- [National annual OCS-GPAD access-activity matrix](07-national-annual-profile.md)
- [CBT inbound restricted-cohort matrix](08-cbt-inbound-restricted-profile.md)
- [CBT outcome-complete restricted-cohort matrix](09-cbt-outcome-complete-profile.md)

## Supplementary timing view

| Question | Retained population | Grain | Sources | Output | Principal limitation |
|---|---|---|---|---|---|
| How are OCS and CBT records distributed within the week? | Eligible timing records | Practice and timing bucket | OCS, CBT | Supplementary temporal outputs | Source bucket definitions limit alignment |

- [Within-week online consultation and telephony timing](10-within-week-timing.md)

## Selection rule

Use a coverage view to study reporting presence, a matched view to compare
measures on common keys, and an annual matrix only when the twelve-month
eligibility contract matches the research question. A smaller retained
population reflects a different evidence requirement, not automatically a
better or worse dataset.
