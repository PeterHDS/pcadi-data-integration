# Evidence base and references

This page records the official definitions, research influences and professional design input used to shape PCADI. Repository manifests remain the authority for the exact files, publication vintages and checksums used in the reference application.

## A. Official data and technical documentation

### Online Consultation Systems in General Practice

| Field | Record |
|---|---|
| Publisher and family | NHS England, [Submissions via Online Consultation Systems in General Practice](https://digital.nhs.uk/data-and-information/publications/statistical/submissions-via-online-consultation-systems-in-general-practice) |
| Role in PCADI | Practice-month online-consultation submissions, registered-patient denominators in the selected evidence series and supplementary day/time activity |
| Source grain | Published practice, reporting period, request type and relevant supplier or timing dimensions |
| Principal categories | Clinical, administrative and other/unknown submission classification; day and time fields where the temporal component is selected |
| Period alignment | Observation month is derived from the source reporting field; one selected publication vintage owns each component-month |
| Supporting information | [OCS supporting information](https://digital.nhs.uk/data-and-information/publications/statistical/submissions-via-online-consultation-systems-in-general-practice/submissions-via-online-consultation-systems-in-general-practice-supporting-information) |
| Interpretation scope | Recorded submissions through participating online-consultation systems and their reporting coverage |
| Repository provenance | `reference-release/manifests/selected_release_manifest.csv`, `source_month_ownership.csv` and `primary_annual_raw_input_manifest.csv` |

### General Practice Appointments Data

| Field | Record |
|---|---|
| Publisher and family | NHS England, [Appointments in General Practice](https://digital.nhs.uk/data-and-information/publications/statistical/appointments-in-general-practice) |
| Role in PCADI | Practice-month recorded appointments and annual appointment activity, mode, booking interval and healthcare-professional features |
| Source grain | Practice, appointment month and one published breakdown family at a time |
| Denominator or rate role | Monthly registered-patient counts support per-1,000 patient-month rates; classified appointment totals support within-family shares |
| Principal categories | Appointment status, mode, booking interval, national category, SDS role group and actual duration where selected |
| Period alignment | Appointment month controls analytical inclusion; publication release month records source vintage |
| Supporting information | [GPAD supporting information](https://digital.nhs.uk/data-and-information/publications/statistical/appointments-in-general-practice/appointments-in-general-practice-supporting-information) and [time-between-booking data quality](https://digital.nhs.uk/data-and-information/publications/statistical/appointments-in-general-practice/improving-data-quality) |
| Interpretation scope | Recorded scheduled and planned activity held in participating appointment systems |
| Repository provenance | `reference-release/manifests/primary_annual_raw_input_manifest.csv`, `input_manifest.csv` and source-month manifests |

### Cloud Based Telephony Data in General Practice

| Field | Record |
|---|---|
| Publisher and family | NHS England, [Cloud Based Telephony Data in General Practice](https://digital.nhs.uk/data-and-information/publications/statistical/cloud-based-telephony-data-in-general-practice) |
| Role in PCADI | Practice-month inbound-call evidence, restricted answered/missed/IVR/callback outcomes and supplementary day/time activity |
| Source grain | Telephony account or mapped practice, reporting month and published measure or timing dimension |
| Denominator or rate role | Inbound calls support documented within-CBT outcome shares; monthly registered patients support per-1,000 rates where specified |
| Principal categories | Inbound, answered, missed, IVR exit, callback and participation/mapping fields supported by the selected component |
| Period alignment | Reporting month remains within the configured analytical period; integrity exclusions retain their source-specific status |
| Supporting information | [CBT supporting information](https://digital.nhs.uk/data-and-information/publications/statistical/cloud-based-telephony-data-in-general-practice/support-information) |
| Interpretation scope | Recorded cloud-telephony activity for mapped and participating reporting accounts |
| Repository provenance | `reference-release/manifests/selected_release_manifest.csv`, temporal download manifest, exclusion register and validation reports |

### Patients Registered at a GP Practice

| Field | Record |
|---|---|
| Publisher and family | NHS England, [Patients Registered at a GP Practice](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice) |
| Role in PCADI | Month-matched practice-size denominator and independent denominator validation |
| Source grain | GP practice and monthly snapshot for all-person totals |
| Denominator or rate role | Sum of twelve monthly registered-patient values forms registered patient-month denominators for annual rates |
| Period alignment | Snapshot/reference month is matched to the activity reporting month |
| Supporting information | [CSV metadata](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice/metadata) and [data quality statement](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice/data-quality-statement) |
| Interpretation scope | Registered list size at the published snapshot date |
| Repository provenance | OCS denominator lineage, `primary_annual_raw_input_manifest.csv`, table dictionary and denominator-validation evidence |

### Organisation Data Service reference information

| Field | Record |
|---|---|
| Publisher and family | NHS England Organisation Data Service, including the EPRACCUR GP-practice reference file and published practice mapping fields |
| Role in PCADI | Practice-code validation, organisation identity and documented reference geography |
| Source grain | One organisational record per practice-code reference row at the selected snapshot |
| Linkage role | `practice_code_standardised` is the common practice identifier used in PCADI joins |
| Period alignment | Reference snapshots are recorded with their extraction or publication date; they support identity checks rather than activity-month ownership |
| Supporting information | [ODS data search and export](https://www.odsdatasearchandexport.nhs.uk/) and the [registered-patient CSV metadata](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice/metadata) for practice mapping fields |
| Interpretation scope | Organisation identity, name, status and relevant published relationships |
| Repository provenance | `reference-release/manifests/primary_annual_raw_input_manifest.csv` and source contracts |

## B. Research and reproducibility influences

These sources are present in the project methodology or directly informed the repository design.

| Source | Contribution to PCADI reasoning |
|---|---|
| Burch, Whittaker and Lau (2025), *Relationship between the volume and type of appointments in general practice and patient experience*, [doi:10.3399/BJGP.2024.0276](https://doi.org/10.3399/BJGP.2024.0276) | Supports careful separation between recorded appointment characteristics and patient-experience evidence |
| Campbell et al. (2014), *Telephone triage for management of same-day consultation requests in general practice*, [doi:10.1016/S0140-6736(14)61058-8](https://doi.org/10.1016/S0140-6736(14)61058-8) | Demonstrates that activity can redistribute across contact types, motivating source-specific measures |
| Eccles et al. (2024), *Access systems in general practice: a systematic scoping review*, [doi:10.3399/BJGP.2023.0149](https://doi.org/10.3399/BJGP.2023.0149) | Informs the distinction between observable access-system activity and the wider access pathway |
| Ge et al. (2024), *The use of online consultation systems and patient experience of primary care*, [doi:10.2196/51272](https://doi.org/10.2196/51272) | Supports practice-level comparison while keeping patient experience as separate evidence |
| Salisbury, Murphy and Duncan (2020), *The impact of digital-first consultations on workload in general practice*, [doi:10.2196/18203](https://doi.org/10.2196/18203) | Supports careful interpretation of digital activity and workload claims |
| Scuffell and Durbaba (2025), *Patterns in GP appointment systems*, [doi:10.3399/BJGP.2024.0556](https://doi.org/10.3399/BJGP.2024.0556) | Informs practice-level profile construction and the importance of mapping, annotation and plausibility controls |
| Benchimol et al. (2015), RECORD statement, [doi:10.1371/journal.pmed.1001885](https://doi.org/10.1371/journal.pmed.1001885) | Supports transparent reporting of studies using routinely collected health data |
| Kahn et al. (2016), harmonised data-quality framework, [doi:10.13063/2327-9214.1244](https://doi.org/10.13063/2327-9214.1244) | Informs explicit completeness, conformance and plausibility evidence |
| [HSSIB: Digital tools for online consultation in general practice](https://www.hssib.org.uk/patient-safety-investigations/digital-tools-for-online-consultation-in-general-practice/) | Informs the responsible interpretation of online-contact records within wider service workflows |
| [NHS Reproducible Analytical Pipelines Community of Practice](https://nhsdigital.github.io/rap-community-of-practice/) | Informs version control, configuration, modular stages, automated testing, open documentation and synthetic demonstrations |
| [Bennett Institute: Open code](https://www.bennett.ox.ac.uk/code/) | Informs the use of executable analytical code as a precise, reviewable method record |
| [OpenSAFELY documentation](https://docs.opensafely.org/) and [QOF utilities](https://github.com/opensafely/qof-utilities) | Informs action-led guidance, explicit task files and reusable analytical definitions |

The SQL feature contracts preserve separate published GPAD `1 day` and `2 to 7 days` booking bands. Downstream compositional methods, model selection and sensitivity analysis remain governed by the later analytical specification rather than by the integration pipeline.

## C. Professional design input

Informal, non-attributable discussions with professionals working in Integrated Care Board and NHS England settings informed the operational questions considered during development. Their perspectives sharpened the treatment of workforce context, deprivation, seasonality, supplier coverage, geography, reporting behaviour and responsible interpretation. All published numerical outputs derive from the documented public datasets.

This design input represents contextual advice. Project authorship, numerical validation and methodological accountability remain with the maintainer and the documented pipeline.

## D. Citation and reuse

A user should cite:

1. PCADI using [`CITATION.cff`](../CITATION.cff).
2. The exact official source publications and supporting information used for the selected observation period.
3. The downstream analytical method applied to the validated outputs.
4. The associated study when its findings, interpretations or figures are reused.

For the April 2025 to March 2026 application, the exact source members, selected vintages, checksums and ownership rules are recorded in `reference-release/manifests/`. The reference-output checksums are recorded in `validation/authoritative_output_manifest.csv`.
