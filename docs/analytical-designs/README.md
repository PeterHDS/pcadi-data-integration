# Analytical design index

PCADI provides several joins because each analytical question has its own anchor population. Choose the question and retained population before selecting an output.

## Source-led and coverage views

### Online consultation records with appointment context

| Field | Specification |
|---|---|
| Question answered | What GPAD context is available for each OCS-reported practice-month? |
| Retained population | OCS-reported practice-month keys |
| Grain and join key | One row per `practice_code_standardised` and `reporting_month`; left join from OCS to GPAD |
| Required sources | Prepared OCS and GPAD practice-month tables |
| Output | `online_consultation_led_appointment_alignment` |
| Evidence contained | OCS activity, GPAD context and source-presence indicators |
| Main selection consideration | GPAD values are available where the same practice-month reports to GPAD |
| Validation | OCS key retention, unique output keys, source totals and row-multiplication factor |
| Detailed guide | [Online consultation records with appointment context](01-online-consultation-with-appointment-context.md) |

### Appointment records with online consultation context

| Field | Specification |
|---|---|
| Question answered | What OCS context is available for each GPAD-reported practice-month? |
| Retained population | GPAD-reported practice-month keys |
| Grain and join key | One row per `practice_code_standardised` and `reporting_month`; left join from GPAD to OCS |
| Required sources | Prepared GPAD and OCS practice-month tables |
| Output | `appointment_led_online_consultation_alignment` |
| Evidence contained | GPAD activity, OCS context and source-presence indicators |
| Main selection consideration | OCS values are available where the same practice-month reports to OCS |
| Validation | GPAD key retention, unique output keys, source totals and row-multiplication factor |
| Detailed guide | [Appointment records with online consultation context](02-appointments-with-online-consultation-context.md) |

### Coverage-preserving OCS, GPAD and CBT practice-month spine

| Field | Specification |
|---|---|
| Question answered | Where does each source report across the selected practice-month universe? |
| Retained population | Union of OCS, GPAD and CBT practice-month keys |
| Grain and join key | One row per `practice_code_standardised` and `reporting_month`; union spine followed by left joins |
| Required sources | Prepared OCS, GPAD and CBT practice-month tables |
| Output | `multichannel_practice_month_coverage` |
| Evidence contained | Source presence, separate source measures and preserved source-specific absence |
| Main selection consideration | The union population is designed for coverage audit and cross-source availability |
| Validation | Union-key completeness, unique output keys, presence counts and source-total reconciliation |
| Detailed guide | [Coverage-preserving multichannel spine](03-coverage-preserving-multichannel-spine.md) |

## Matched activity views

### Matched online consultation and appointment activity

| Field | Specification |
|---|---|
| Question answered | How do OCS and GPAD measures compare where both sources report? |
| Retained population | Common OCS-GPAD practice-month keys |
| Grain and join key | One row per `practice_code_standardised` and `reporting_month`; inner join |
| Required sources | Prepared OCS and GPAD practice-month tables |
| Output | `matched_online_and_scheduled_activity` |
| Evidence contained | Separate OCS and GPAD activity plus denominators and match evidence |
| Main selection consideration | The design answers a common-reporting question and excludes source-only keys |
| Validation | Matched-key count, unique output keys, source totals and row-multiplication factor |
| Detailed guide | [Matched online consultation and appointment activity](04-matched-online-and-appointment-activity.md) |

### Matched OCS, GPAD and valid CBT activity

| Field | Specification |
|---|---|
| Question answered | What separate activity evidence is available where OCS, GPAD and valid CBT reporting coincide? |
| Retained population | Common OCS-GPAD-CBT practice-month keys satisfying CBT integrity rules |
| Grain and join key | One row per `practice_code_standardised` and `reporting_month`; matched join |
| Required sources | Prepared OCS, GPAD and CBT practice-month tables |
| Output | `matched_multichannel_activity` |
| Evidence contained | Separate online-consultation, appointment and telephony measures |
| Main selection consideration | CBT participation, mapping and integrity conditions define the smaller population |
| Validation | Three-source matched keys, unique output keys, integrity flags and row-multiplication factor |
| Detailed guide | [Matched multichannel activity](05-matched-multichannel-activity.md) |

### OCS-GPAD comparison within the CBT-observed population

| Field | Specification |
|---|---|
| Question answered | How do matched OCS-GPAD patterns look among practices with observed CBT evidence? |
| Retained population | CBT-observed practice-month keys with matched OCS and GPAD |
| Grain and join key | One row per `practice_code_standardised` and `reporting_month`; CBT-observed key restriction |
| Required sources | Prepared OCS, GPAD and CBT practice-month tables |
| Output | `telephony_observed_comparative_cohort` |
| Evidence contained | OCS-GPAD comparison measures plus CBT availability context |
| Main selection consideration | The output describes the CBT-observed reporting population |
| Validation | CBT observation rule, matched-key count, unique output keys and source reconciliation |
| Detailed guide | [CBT-observed comparison](06-cbt-observed-comparison.md) |

## Annual practice matrices

These designs use exactly twelve complete eligible months under the annual contract.

### National annual OCS-GPAD access-activity matrix

| Field | Specification |
|---|---|
| Question answered | What annual recorded OCS-GPAD activity configuration describes each eligible practice? |
| Retained population | Practices with twelve eligible matched months and complete finite annual features; 6,067 practices in the reference application |
| Grain and join key | One row per `practice_code_standardised`; annual aggregation from matched practice-month keys |
| Required sources | Prepared OCS, GPAD, registered-patient and provenance tables |
| Output | `primary_practice_access_clustering_matrix.csv` |
| Evidence contained | Fourteen numerical features with separate GPAD `1 day` and `2 to 7 days` shares |
| Main selection consideration | Strict annual completeness establishes a stable common observation window |
| Validation | Twelve-month eligibility, unique practices, finite values, feature contract and checksum |
| Detailed guide | [National annual profile](07-national-annual-profile.md) |

### CBT inbound restricted-cohort matrix

| Field | Specification |
|---|---|
| Question answered | What inbound telephony evidence extends the annual activity profile? |
| Retained population | Nested practices with valid CBT inbound evidence; 3,020 practices in the reference application |
| Grain and join key | One row per `practice_code_standardised`; left inheritance from the eligible annual parent followed by CBT evidence eligibility |
| Required sources | National annual parent matrix and prepared CBT inbound measures |
| Output | `cbt_inbound_sensitivity_clustering_matrix_17_features.csv` |
| Evidence contained | Every parent feature plus three documented CBT inbound features |
| Main selection consideration | CBT evidence availability defines the restricted cohort |
| Validation | Parent nesting, inherited-value equality, CBT validity, finite values and checksum |
| Detailed guide | [CBT inbound restricted profile](08-cbt-inbound-restricted-profile.md) |

### CBT outcome-complete restricted-cohort matrix

| Field | Specification |
|---|---|
| Question answered | What supported CBT outcome composition extends the annual activity profile? |
| Retained population | Nested practices with complete supported CBT outcome evidence; 1,456 practices in the reference application |
| Grain and join key | One row per `practice_code_standardised`; restriction within the CBT inbound parent cohort |
| Required sources | CBT inbound parent matrix and supported CBT outcome measures |
| Output | `cbt_outcomes_sensitivity_clustering_matrix_21_features.csv` |
| Evidence contained | Every inbound-parent feature plus four supported CBT outcome features |
| Main selection consideration | Complete outcome evidence defines the smallest nested cohort |
| Validation | Two-level nesting, inherited-value equality, outcome composition, finite values and checksum |
| Detailed guide | [CBT outcome-complete profile](09-cbt-outcome-complete-profile.md) |

## Supplementary timing view

### Within-week online consultation and telephony timing

| Field | Specification |
|---|---|
| Question answered | How are separate OCS and CBT records distributed across defensibly aligned weekday and time buckets? |
| Retained population | Eligible practice-month-day-time records under source integrity and bucket-mapping rules |
| Grain and join key | Practice, reporting month, weekday and harmonised time bucket; union-spine integration |
| Required sources | OCS day/time, CBT day/time, mapping evidence and registered-patient denominators where rates are used |
| Output | Supplementary temporal clean tables, spine, integrated table and practice features |
| Evidence contained | Separate source activity, original and harmonised buckets, coverage and integrity flags |
| Main selection consideration | Common buckets use only the precision supported by both official source definitions |
| Validation | Monthly coverage, unique temporal keys, source reconciliation, cardinality and integrity-impact audit |
| Detailed guide | [Within-week timing](10-within-week-timing.md) |

## Selection rule

Use a coverage design for reporting presence, a source-led design when one publication family anchors the question, a matched design for common-key comparison and an annual matrix when the twelve-month eligibility contract matches the research question. Every output carries the population and evidence needed to interpret its size and scope.
