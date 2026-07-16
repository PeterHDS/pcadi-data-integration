# Official source references

Accessed 15 July 2026. These primary sources support interpretation and reproducibility practice. The frozen file schemas and values remain the operational source specification; external documentation was not used to retrofit different definitions.

## NHS England / NHS Digital

1. [Submissions via Online Consultation Systems in General Practice, May 2026](https://digital.nhs.uk/data-and-information/publications/statistical/submissions-via-online-consultation-systems-in-general-practice/may-2026). Official selected OCS publication vintage. The page records the publication date, coverage period, practice-level resources and an incomplete-May-2026 notice. The analytical window in this package stops at March 2026.
2. [Submissions via Online Consultation Systems in General Practice: Supporting Information](https://digital.nhs.uk/data-and-information/publications/statistical/submissions-via-online-consultation-systems-in-general-practice/submissions-via-online-consultation-systems-in-general-practice-supporting-information). Defines submissions, clinical/administrative/other classification, supplier coverage, retrospective updates, practice-level content and limitations. It states that the collection is not all demand and cannot establish unique patient use or resulting appointments.
3. [Appointments in General Practice: Supporting Information](https://digital.nhs.uk/data-and-information/publications/statistical/appointments-in-general-practice/appointments-in-general-practice-supporting-information). Defines the scope as recorded scheduled/planned appointment-system activity and describes practice-level breakdowns, status, mode and time between booking and appointment. It states that the publication is not complete workload, demand or capacity and warns against combining its counts with OCS submissions because overlap is unknown.
4. [Improving data quality: Time between booking and appointment](https://digital.nhs.uk/data-and-information/publications/statistical/appointments-in-general-practice/improving-data-quality). Explains that the measure is elapsed days between booked date and appointment date, grouped into bands including same day, next day and 2-7 days, with unknown and negative values treated as data-quality flags.
5. [Patients Registered at a GP Practice](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice). Monthly official series describing registered counts on the first day of each month and practice-level granularity.
6. [Patients Registered at a GP Practice: Data Quality Statement](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice/data-quality-statement). Documents the monthly snapshot, PDS source, list inflation, under-coverage, live-system change and geography comparability cautions.
7. [Patients Registered at a GP Practice, April 2026](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice/april-2026). Example period-adjacent publication confirming practice totals, PDS snapshot basis, CSV resources, metadata and data-quality links.
8. [Cloud Based Telephony Data in General Practice](https://digital.nhs.uk/data-and-information/publications/statistical/cloud-based-telephony-data-in-general-practice). Official monthly publication series containing practice-level day/time, duration, participation and metadata resources.
9. [Cloud Based Telephony in General Practice: Supporting Information](https://digital.nhs.uk/data-and-information/publications/statistical/cloud-based-telephony-data-in-general-practice/support-information). Documents phased supplier coverage, account-to-practice mapping, unassigned accounts, participation and data-quality limitations.

### Interpretation applied

- OCS and GPAD are kept as separate domains and are never combined into a total.
- OCS submissions are successful received online requests in participating systems, not unique patients or outcomes.
- GPAD is recorded scheduled/planned activity, not total workload, capacity, access quality or demand.
- Booking-interval features describe recorded elapsed time and do not independently measure service quality.
- List-size-normalised rates describe recorded activity per registered patient-month; list-size quality limitations remain.

## UK Data Service

10. [Guidance for depositing syntax/code](https://ukdataservice.ac.uk/help/deposit-data/sharing-syntax/). Recommends a README explaining purpose, execution and prerequisites; commented code; dependency/software versions; source citation and acquisition instructions; and removal of confidential information.
11. [Prepare your data collection for deposit](https://ukdataservice.ac.uk/help/deposit-data/prepare-your-data-for-deposit/). Recommends a README for multi-file/complex collections and documentation of relationships, sources and inclusion rules.

### Reproducibility practice applied

This package supplies landing and quick-start documentation, explicit prerequisites, a 21-file manifest, complete annotated SQL, file-relationship and cohort documentation, source citations, checksums and dependency/version records.

## SQLite

12. [PRAGMA statements](https://www.sqlite.org/pragma.html). Official definition of `integrity_check`, `foreign_key_check` and related database checks.
13. [CREATE TABLE](https://www.sqlite.org/lang_createtable.html). Official definition of table creation and `CREATE TABLE AS SELECT`, including its constraint behaviour.
14. [Datatypes in SQLite](https://www.sqlite.org/datatype3.html). Official description of dynamic typing, storage classes and type affinity; this supports text-preserving raw staging and explicit conversion.
15. [Built-in scalar SQL functions](https://www.sqlite.org/lang_corefunc.html). Official definitions of `printf`/`format`, `typeof`, `trim` and related functions used in validation and canonicalisation.
16. [SQL language expressions](https://www.sqlite.org/lang_expr.html). Official expression and `GLOB` behaviour used for identifier pattern validation.
17. [SQLite command-line shell](https://www.sqlite.org/cli.html). Official `.import` and CSV export behaviour referenced by the manual execution route.

## Local structural documentation

The exact OCS column and metric codes used by the frozen CSVs are additionally documented by the locally retained official metadata workbook `OCVC_Metadata_2024.xlsx` in the wider reproducibility workspace. Its location and source hash are preserved in the workspace inventory. The import contract records the exact source headers, and the SQL documents every selected metric.
