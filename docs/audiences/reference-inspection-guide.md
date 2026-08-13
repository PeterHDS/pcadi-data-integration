# Reference-output inspection guide

This guide provides a concise route through the April 2025 to March 2026 reference application. It connects the published analytical contracts to their lineage, validation and reproducible build boundary.

## Short inspection route

1. Read the [research context](../research-context.md).
2. Review the [verified reference application](../reference-applications/apr2025-mar2026.md).
3. Inspect the [analytical contract and lineage](../audits/ANALYTICAL_CONTRACT_AND_LINEAGE.md).
4. Open the [national annual matrix](../../outputs/primary_practice_access_clustering_matrix.csv).
5. Run `RUN_REFERENCE_VALIDATION.cmd`.

The national matrix contains 6,067 practices, one traceability identifier and 14 complete numerical modelling features. The identifier must be excluded from the numerical feature matrix. The GPAD booking-delay features retain separate same-day, 1-day, 2-to-7-day, 8-to-14-day and over-14-day shares.

## What the validation establishes

The compact check confirms:

- all 14 registered reference outputs are present or restored from the verified period-labelled release asset;
- file size, schema, row count and checksum match the technical register;
- every annual matrix has one unique practice identifier per row;
- modelling values are complete, numeric and finite;
- the 3,020-practice CBT inbound cohort is nested inside the 6,067-practice matrix;
- the 1,456-practice CBT outcome-complete cohort is nested inside both; and
- shared parent values are inherited exactly.

Complete fingerprints are in the [authoritative output manifest](../../validation/authoritative_output_manifest.csv).

## Raw-source reconstruction boundary

`RUN_REFERENCE_BUILD.cmd` recreates the national annual OCS-GPAD matrix when the 21 exact registered OCS, GPAD and mapping CSVs are available. Raw NHS downloads and the working database are not stored in Git. The [reproduction guide](../../reference-release/documentation/REPRODUCTION_GUIDE.md) states the required inputs and sequence.

The restricted CBT matrices use separately validated prepared CBT evidence. The broader selected-release manifests retain CBT publication ownership and integrity exclusions, but the 21-file command is not a complete raw CBT reconstruction.

## Boundary

The repository validates data integration. It does not rerun downstream clustering or establish demand, access quality, safety, equity, value or patient outcomes.
