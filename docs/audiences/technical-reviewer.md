# Technical reviewer overview

The architecture uses a narrow orchestration layer and an authoritative SQL
transformation layer. JSON contracts control CSV headers and types. A provenance
table enforces one selected release per dataset-component-observation-month.
Each source reaches practice-month grain independently before a union spine is
constructed.

Key engineering controls include:

- read-before-write source validation;
- deterministic imports and exports;
- primary and unique keys at asserted grains;
- explicit expected and observed validation evidence;
- source-family reconciliation;
- row-multiplication checks;
- schema-drift failure rather than guessed mappings;
- ignored work databases and source downloads;
- synthetic CI with no external data dependency;
- frozen reference checksums.

The release-level contract gates assert:

- 6,067 rows by 15 total columns for the national matrix;
- 3,020 rows by 18 total columns for the CBT inbound matrix;
- 1,456 rows by 22 total columns for the raw CBT outcome matrix;
- exact column order and deterministic practice ordering;
- no blank, duplicate, missing, non-numeric or non-finite values;
- valid share and non-negative rate ranges;
- exact cohort nesting;
- exact fourteen-field inheritance into the inbound matrix;
- exact seventeen-field inheritance into the outcome matrix.

The Python runner uses only the standard library. The executable SQL targets
SQLite; the analytical design is portable but dialect changes are required for
other database engines.

Use the [source-of-truth audit](../audits/PCADI_V2_SOURCE_OF_TRUTH.md),
[dependency graph](../audits/PCADI_V2_DEPENDENCY_GRAPH.md) and
[`validation/pcadi_v2_repository_rebuild_gate.csv`](../../validation/pcadi_v2_repository_rebuild_gate.csv)
for release review.
