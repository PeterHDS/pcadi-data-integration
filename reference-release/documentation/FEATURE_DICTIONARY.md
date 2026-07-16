# Feature dictionary

The practice identifier accompanies the matrix for traceability and is not a modelling feature. OCS and GPAD are separate activity domains and are never added. Full field-level definitions are also supplied in machine-readable form in `FEATURE_DICTIONARY.csv`.

| SQL feature | Public label | Definition | Unit / expected range | Principal caution |
|---|---|---|---|---|
| `ocs_submissions_per_1000_patient_months` | Recorded online submissions per 1,000 registered patient-months | `1000 * annual OCS total / sum(12 monthly registered patients)` | Non-negative rate | Not all practice demand; supplier and system availability affect coverage |
| `ocs_clinical_share` | Clinical share of online submissions | Annual clinical / annual OCS total | Proportion, 0-1 | Classification is not patient case mix or clinical need |
| `ocs_administrative_share` | Administrative share of online submissions | Annual administrative / annual OCS total | Proportion, 0-1 | Other/unknown remains a residual; not administrative workload |
| `gpad_appointments_per_1000_patient_months` | Recorded appointments per 1,000 registered patient-months | `1000 * annual GPAD total / sum(12 monthly registered patients)` | Non-negative rate | GPAD is scheduled/planned recorded activity, not total workload, capacity or demand |
| `gpad_dna_share` | Did-not-attend share | Annual DNA / annual GPAD total | Proportion, 0-1 | Recording and unknown status affect interpretation; not a quality score |
| `gpad_face_to_face_share` | Face-to-face share | Annual face-to-face / annual GPAD total | Proportion, 0-1 | Recorded/mapped mode may differ from actual care setting |
| `gpad_telephone_share` | Telephone share | Annual telephone / annual GPAD total | Proportion, 0-1 | Not all telephone contact; local list recording varies |
| `gpad_same_day_share` | Same-day booking share | Annual exact same-day band / annual GPAD total | Proportion, 0-1 | A booking interval does not independently measure service quality |
| `gpad_1_to_7_days_share` | One-to-seven-day booking share | Separately calculated 1-day share plus 2-to-7-day share | Proportion, 0-1 | Excludes same day; affected by urgency, availability and patient choice |
| `gpad_8_to_14_days_share` | Eight-to-fourteen-day booking share | Annual 8-14-day band / annual GPAD total | Proportion, 0-1 | Does not measure time spent trying to contact the practice |
| `gpad_over_14_days_share` | Over-fourteen-day booking share | Annual 15-21 + 22-28 + >28-day bands / annual GPAD total | Proportion, 0-1 | Planned/repeat appointments may be booked far ahead |
| `ocs_mean_absolute_monthly_rate_change` | Mean absolute monthly change in OCS rate | Mean of 11 adjacent absolute monthly OCS-rate differences | Non-negative rate-point change | Reflects recording, availability and seasonality as well as activity |
| `gpad_mean_absolute_monthly_rate_change` | Mean absolute monthly change in GPAD rate | Mean of 11 adjacent absolute monthly GPAD-rate differences | Non-negative rate-point change | Not workload or demand volatility alone |

## Missing-value and eligibility rule

No feature is imputed. A zero reported in a present record is retained. An undefined denominator remains NULL and fails eligibility. All retained practices have 12 OCS months, 12 GPAD months, 12 positive month-matched denominators, reconciled category totals, a positive annual OCS total and complete valid feature values.

## Interpretive boundary

Online submission activity does not independently establish improved access. Booking intervals do not independently measure service quality. GPAD is not a measure of total practice workload. Subsequent clustering can describe statistical similarity in these recorded features but cannot label a cluster as intrinsically good or bad without separate evidence and interpretation.

