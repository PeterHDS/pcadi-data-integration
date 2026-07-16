# Data sources

## Online Consultation Systems (OCS)

The selected source is the May 2026 publication vintage of NHS England's *Submissions via Online Consultation Systems in General Practice*. Two regional CSV members contain the historical practice-level evidence series used here. The analytical window is restricted to April 2025-March 2026; May 2026 is a publication vintage, not an observation month included in the model.

The pipeline uses `OC_TOTAL_SUBMISSIONS`, clinical, administrative and other/unknown submission measures plus the monthly `PATIENTS_REGISTERED` metric. Suppliers may revise retrospective data; therefore the input manifest freezes the chosen files by SHA-256.

OCS values are successful submissions received by participating practices through contributing systems. They are not unique patients, outcomes, all practice contacts or total demand. Supplier participation, system availability and classification practices affect coverage.

## Appointments in General Practice (GPAD)

Fourteen practice-level crosstab CSVs cover the 12 reporting months; March and October are supplied in two regional components. Detail dimensions include appointment status, mode, booking interval and related descriptors. Each detail row contributes once to the appointment total, while status, mode and booking categories are aggregated as parallel breakdown families rather than added to one another.

The pipeline classifies the exact observed booking labels into mutually exclusive bands: same day, 1 day, 2-7 days, 8-14 days, 15-21 days, 22-28 days, more than 28 days, unknown/data issue and other. The final 1-7-day share is the sum of the separately calculated 1-day and 2-7-day shares.

GPAD represents recorded scheduled/planned activity in participating appointment systems. It is not total workload, capacity, unmet need or demand. The time-between-booking measure uses calendar dates and does not measure time spent trying to contact a practice.

## Registered-patient denominator

The denominator is the month-matched `PATIENTS_REGISTERED` measure in the frozen OCS evidence series. For each practice-month, identical supplier copies are validated and one positive value is retained. Annual exposure is the sum of 12 monthly practice list sizes, expressed as registered patient-months.

This usage is consistent with the analytical role of NHS England's monthly registered-patient snapshots but does not eliminate known list inflation, under-coverage or organisational-change limitations.

## Identifier mapping references

Five GPAD mapping files provide independent reference evidence for standardised practice codes. Absence from these vintages is reported but never used to remove a practice. The analytical cohort is defined from validated activity, denominator and completeness rules.

## Frozen input contract

`input_manifest.csv` is authoritative for exact filenames, locations, schemas, encodings, row counts, destinations and SHA-256 checksums. Official publication links and interpretation references are in `documentation/OFFICIAL_SOURCE_REFERENCES.md`.

