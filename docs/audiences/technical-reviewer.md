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

The Python runner uses only the standard library. The executable SQL targets
SQLite; the analytical design is portable but dialect changes are required for
other database engines.
