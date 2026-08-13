# Source catalogue

This catalogue explains what each source contributes to the integration. Official metadata and machine-readable contracts provide the corresponding field-level authority.

| Source | What it records | Grain used by the pipeline | Questions it supports | Additional evidence required for |
|---|---|---|---|---|
| Online Consultation Systems (OCS) | Submissions received through contributing online systems, including explicitly published clinical, administrative and other/unknown classifications | Practice and observation month after source-specific aggregation | Recorded online-submission volume, rates by registered list size, composition and reporting coverage | All requests to a practice, unique patients, access quality, unmet need or total demand |
| General Practice Appointment Data (GPAD) | Scheduled or planned appointment-system activity and published breakdowns such as status, mode and booking interval | Practice and appointment month after each breakdown family is handled separately | Appointment patterns, recorded modes and statuses, booking intervals and matched OCS-GPAD comparisons | Complete practice workload, capacity, patient effort, unmet demand or a direct equivalent of an OCS submission |
| Cloud Based Telephony (CBT) | Published call activity from participating cloud-telephony suppliers, subject to account-to-practice mapping | Practice and observation month after valid mapping and source-specific aggregation | Recorded inbound, answered, missed and other defined call measures; telephony-observed sensitivity populations | All telephone contact, patient-level linkage, national completeness where suppliers or mappings are absent, or causal channel substitution |
| Registered-patient denominator | Monthly registered list size used to normalise eligible practice activity | Practice and observation month | Separate OCS and CBT activity rates per 1,000 registered patient-months | The resident population, daily exposure, demand or access quality |
| ODS reference data | Organisation identifiers and relevant reference relationships | Organisation record, joined using a standardised practice code | Identifier validation, practice attribution and documented geography | Proof that a practice submitted to OCS, GPAD or CBT in a given month |

## Follow the source contract

Prepared files must satisfy the contracts in [`contracts/sources`](../contracts/sources):

- [`online_consultation_practice_month.json`](../contracts/sources/online_consultation_practice_month.json);
- [`appointment_activity_practice_month.json`](../contracts/sources/appointment_activity_practice_month.json);
- [`cloud_telephony_practice_month.json`](../contracts/sources/cloud_telephony_practice_month.json); and
- [`source_provenance.json`](../contracts/sources/source_provenance.json).

The contracts define the interface accepted by the portable pipeline. Reproducibility also retains original filenames, archive members, official metadata, publication vintages and source-specific reconciliation evidence.

## Reference evidence layers

The April 2025 to March 2026 application separates four evidence layers so that the scope of each reconstruction claim remains clear.

| Evidence layer | Registered contents | Role and boundary |
|---|---|---|
| National annual raw-source build | 21 input CSVs: 2 OCS regional evidence files, 14 GPAD practice-level crosstabs and 5 GPAD mapping references | Reconstructs the matched OCS-GPAD-denominator monthly panel and the 14-feature national annual matrix. It does not rebuild CBT from raw archives. |
| Broader selected-release evidence | 208 registered source members, of which 206 were selected: 2 OCS, 14 GPAD and 190 CBT members | Records publication-vintage ownership across the wider integration work. Two CBT members remain explicit integrity exclusions rather than selected inputs. |
| Prepared-source contracts | Canonical OCS, GPAD, CBT and provenance interfaces in `contracts/sources/` | Allow the portable pipeline to integrate validated practice-month inputs without claiming that the repository contains every raw publication archive. |
| Frozen reference outputs | 14 registered outputs in the authoritative output manifest | Provide compact deterministic validation of the published reference application, including the three annual analytical matrices. |

The two registered CBT integrity exclusions are `Cloud Based Telephony By Day and Time - April 2025_Y60.csv` and `Cloud Based Telephony By Durations - June 2025_Y62.csv`. Their source status remains documented; missing activity is not converted to zero.

## Select the observation period before the files

The analytical window is expressed in observation months. A publication issued later may contain revised historical observations. Exactly one selected source vintage owns every required dataset-component-observation-month after candidate releases are compared. The registered publication month therefore describes provenance, not automatic inclusion in the analytical period.

Use the [official data acquisition guide](get-official-nhs-data/README.md) for the collection workflow and the [publication-vintage guide](get-official-nhs-data/publication-vintage-selection.md) for overlap and supersession decisions.

## Keep source meaning visible in the result

OCS submissions, GPAD appointments and CBT calls are separate recorded activities. Matching them by practice and month creates a shared analytical context. Patient-level and event-level linkage require a different data design. Source-presence flags, missingness classes, denominators and integrity warnings remain visible when derived outputs are interpreted.
