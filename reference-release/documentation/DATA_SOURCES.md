# Data sources

## Online Consultation Systems (OCS)

The selected source is the May 2026 publication vintage of NHS England's *Submissions via Online Consultation Systems in General Practice*. Two regional CSV members contain the historical practice-level evidence series used here. The analytical window is restricted to April 2025-March 2026; May 2026 is a publication vintage, not an observation month included in the model.

The pipeline uses `OC_TOTAL_SUBMISSIONS`, `OC_SUBMISSION_TYPE_CLINICAL`, `OC_SUBMISSION_TYPE_ADMIN` and the explicitly published `OC_SUBMISSION_TYPE_OTHER` measure plus the monthly `PATIENTS_REGISTERED` metric. These parallel categories are retained through SQL preparation and reconciled to the total. Suppliers may revise retrospective data; therefore the input manifest freezes the chosen files by SHA-256.

OCS values are successful submissions received by participating practices through contributing systems. They are not unique patients, outcomes, all practice contacts or total demand. Supplier participation, system availability and classification practices affect coverage.

## Appointments in General Practice (GPAD)

Fourteen practice-level crosstab CSVs cover the 12 reporting months; March and October are supplied in two regional components. Detail dimensions include appointment status, mode, booking interval and related descriptors. Each detail row contributes once to the appointment total, while status, mode and booking categories are aggregated as parallel breakdown families rather than added to one another.

The pipeline classifies the exact observed booking labels into mutually exclusive bands: same day, 1 day, 2-7 days, 8-14 days, 15-21 days, 22-28 days, more than 28 days, unknown/data issue and other. The national 14-feature matrix retains separate 1-day and 2-to-7-day shares. A 1-to-7-day sum is retained only as an audit field outside the authoritative matrix.

GPAD represents scheduled/planned activity recorded in participating appointment systems. Workload, capacity, unmet need and demand require additional evidence. The time-between-booking measure uses calendar dates; contact-attempt duration sits outside this field's scope.

## Registered-patient denominator

The denominator is the month-matched `PATIENTS_REGISTERED` measure in the frozen OCS evidence series. For each practice-month, identical supplier copies are validated and one positive value is retained. Annual exposure is the sum of 12 monthly practice list sizes, expressed as registered patient-months.

This usage is consistent with the analytical role of NHS England's monthly registered-patient snapshots but does not eliminate known list inflation, under-coverage or organisational-change limitations.

## Identifier mapping references

Five GPAD mapping files provide independent reference evidence for standardised practice codes. Absence from these vintages is reported but never used to remove a practice. The analytical cohort is defined from validated activity, denominator and completeness rules.

## Cloud Based Telephony (CBT) evidence boundary

CBT is not part of the 21-file national raw-source build. The restricted 17- and 21-feature matrices use a separately validated prepared CBT evidence layer registered in the broader selected-release manifests. That register contains 192 CBT members: 190 selected members across day/time and duration families and two explicit integrity exclusions.

The excluded members are `Cloud Based Telephony By Day and Time - April 2025_Y60.csv` and `Cloud Based Telephony By Durations - June 2025_Y62.csv`. Their missing evidence is not zero-filled, repaired or inferred. Reconstructing CBT directly from official raw archives would require a distinct source-acquisition, mapping, integrity and reconciliation subsystem beyond the national OCS-GPAD build.

## Frozen input contract

`input_manifest.csv` is authoritative for the 21-file national OCS-GPAD raw-source build: exact filenames, locations, schemas, encodings, row counts, destinations and SHA-256 checksums. The broader publication-vintage evidence is registered in `manifests/selected_release_manifest.csv` and `manifests/source_month_ownership.csv`. Official publication links and interpretation references are in `documentation/OFFICIAL_SOURCE_REFERENCES.md`.
