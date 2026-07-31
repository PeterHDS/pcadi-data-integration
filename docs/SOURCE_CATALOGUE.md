# Source catalogue

This catalogue explains what each source contributes to the integration. Official metadata and machine-readable contracts provide the corresponding field-level authority.

| Source | What it records | Grain used by the pipeline | Questions it supports | Additional evidence required for |
|---|---|---|---|---|
| Online Consultation Systems (OCS) | Submissions received through contributing online systems, including available clinical and administrative classifications | Practice and observation month after source-specific aggregation | Recorded online-submission volume, rates by registered list size, composition and reporting coverage | All requests to a practice, unique patients, access quality, unmet need or total demand |
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

## Select the observation period before the files

The analytical window is expressed in observation months. A publication issued later may contain revised historical observations. Exactly one selected source vintage owns every required dataset-component-observation-month after candidate releases are compared.

Use the [official data acquisition guide](get-official-nhs-data/README.md) for the collection workflow and the [publication-vintage guide](get-official-nhs-data/publication-vintage-selection.md) for overlap and supersession decisions.

## Keep source meaning visible in the result

OCS submissions, GPAD appointments and CBT calls are separate recorded activities. Matching them by practice and month creates a shared analytical context. Patient-level and event-level linkage require a different data design. Source-presence flags, missingness classes, denominators and integrity warnings remain visible when derived outputs are interpreted.
