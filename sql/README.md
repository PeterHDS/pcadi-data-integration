# SQL organisation

`portable/` is the configurable pipeline for one month, twelve months, twenty-four months or any other positive contiguous period. It starts from validated canonical practice-month contracts, builds tables for distinct analytical populations and records mandatory evidence.

`core_pipeline/` is the complete ordered OCS/GPAD raw-source reconstruction for the verified reference application. It preserves the exact known source schemas, expected counts and twelve-month annual feature rules. Its 21 registered inputs cover the national annual OCS-GPAD branch; CBT enters the restricted reference matrices through separately validated prepared evidence.

The top-level temporal script is retained as reference-release SQL evidence for the separate day/time analysis. New users should begin with `portable/` and use `core_pipeline/` when reproducing the period-specific raw-source build.

Execution order is encoded in filenames. Numerical prefixes describe SQL stage order, not analytical-design names.

## Core pipeline stage map

| Stage | Analytical purpose | Principal input | Grain | Principal output | Validation or control |
|---|---|---|---|---|---|
| 01 | Create text-preserving raw tables | Input-manifest definitions | Source row | Raw OCS, GPAD and mapping tables | Explicit schemas prevent silent type inference |
| 02 | Standardise source fields | Raw source tables | Source-specific detail row | Standardised OCS, GPAD and mapping tables | Identifier, month and numeric-text validity |
| 03 | Verify source integrity | Standardised detail | Source and natural key | Source audit tables | File count, month coverage, duplicates and conflicts |
| 04 | Build monthly population exposure | OCS registered-patient measures | Practice-month | Registered-patient denominator table | Positive, unique and supplier-consistent values |
| 05 | Prepare OCS activity | Valid OCS metric rows | Practice-month | OCS practice-month table | Explicit total, clinical, administrative and other/unknown reconciliation |
| 06 | Prepare GPAD activity | Valid appointment-detail rows | Practice-month | GPAD practice-month table | Parallel families and mutually exclusive booking bands reconcile |
| 07 | Establish intended matched cardinality | Unique OCS, GPAD and denominator tables | Practice-month key | Join-cardinality audit | Expected matched keys and multiplication factor 1.0 |
| 08 | Construct the national monthly panel | Three validated practice-month tables | Practice-month | Integrated OCS-GPAD-denominator panel | Inner join on practice and month; no manufactured rows |
| 09 | Build annual features and eligibility | Integrated panel and complete source series | Practice | Annual feature, eligibility and exclusion tables | Twelve months, valid denominators, reconciled components and finite features |
| 10 | Select the national analytical contract | Eligible annual features | Practice | Identifier plus 14 numerical features | Fixed schema, ranges, completeness and unique practices |
| 11 | Validate complete lineage | Raw, prepared, monthly and annual tables | Test record | Validation reports | Reconciliation, missingness, range, lineage and integrity gates |
| 12 | Order, fingerprint and export | Validated national matrix | Practice | Deterministic export and fingerprints | Stable ordering and canonical reference equivalence |

The detailed stage specification is in [`reference-release/documentation/PIPELINE_METHODOLOGY.md`](../reference-release/documentation/PIPELINE_METHODOLOGY.md).
