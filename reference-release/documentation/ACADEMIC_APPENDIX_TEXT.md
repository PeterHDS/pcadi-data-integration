# Academic appendix text

## Reproducible SQL construction of the annual practice matrix

The primary annual practice-access matrix was reconstructed through a fully
specified SQL pipeline for 1 April 2025 to 31 March 2026. It combines separate
features from Online Consultation Systems (OCS) and General Practice
Appointment Data (GPAD). An online submission is not treated as an appointment,
and the two activity totals are never added. Rates use month-matched registered
practice-list exposure.

The tested implementation uses Python's standard-library SQLite interface and
twelve ordered SQL stages under `sql/core_pipeline/`. Python verifies and loads
the source files; SQL performs the substantive transformation, aggregation,
joining, eligibility and feature logic.

| Stage | Principal operation | Principal output |
|---|---|---|
| 1 | Create 21 text-preserving raw tables | Raw source staging |
| 2 | Standardise identifiers, months and numerical fields | Standardised OCS, GPAD and mapping data |
| 3 | Validate source integrity and coverage | Source audits |
| 4 | Construct monthly registered-list denominators | Unique practice-month denominators |
| 5 | Aggregate OCS independently | OCS practice-month table |
| 6 | Aggregate GPAD independently | GPAD practice-month table |
| 7 | Test prospective join cardinality | Join audit |
| 8 | Integrate unique practice-month blocks | Integrated monthly panel |
| 9 | Construct annual features and apply cohort rules | Eligible annual practice table |
| 10 | Select the thirteen modelling features | Primary matrix |
| 11 | Execute the validation framework | Thirty-six checks |
| 12 | Order, fingerprint and export | Deterministic output |

`reference-release/input_manifest.csv` records each source path, raw table,
encoding, delimiter, exact header, expected row count and SHA-256 checksum. Raw
fields are staged as text so import-time type inference cannot change blanks or
malformed values. Numerical conversion follows explicit validation.

OCS and GPAD are aggregated independently to one row per standardised practice
code and reporting month. This prevents supplier or appointment-detail rows
from multiplying each other. OCS, GPAD and the denominator are then joined on
both practice and month. The validated join has a row-multiplication factor of
1.0.

Annual rates use the sum of twelve monthly registered-patient counts as
patient-month exposure. Composition features are recalculated from annual
component totals rather than unweighted monthly percentages. Monthly change
uses eleven adjacent differences. No missing activity is imputed and no absent
record is converted to zero.

Eligibility requires twelve OCS months, twelve GPAD months, twelve positive and
unconflicted denominators, unique reconciled source categories, a positive
annual OCS total and complete valid features. The observed lineage is 6,210
annual OCS practices, 6,184 annual GPAD practices, 6,130 practices meeting the
complete monthly conditions, 63 exclusions with undefined OCS composition
ratios and 6,067 practices in the final matrix.

Validation covers source hashes and counts, month coverage, identifiers,
numeric conversion, duplicates, denominator conflicts, source uniqueness, join
cardinality, reconciliation, cohort lineage, missingness, retained zeros,
feature ranges, deterministic ordering, database integrity and exact canonical
fingerprint agreement. The clean-build result is recorded in
`reference-release/validation/CLEAN_BUILD_VALIDATION.md`.

The final repository export is
`outputs/primary_practice_access_clustering_matrix.csv`. It contains one
traceability identifier and thirteen numerical features for each of 6,067
practices. The identifier is not a modelling feature. No clustering is
executed by this repository.
