# Pipeline architecture

PCADI converts prepared official publication files into validated
practice-month tables and question-specific outputs.

![PCADI architecture from official publications through source contracts, practice-month tables and analytical outputs](../assets/pcadi-architecture.svg)

## Data flow

1. **Official publications** provide OCS, GPAD, CBT and registered-patient
   measures. ODS practice codes identify organisations.
2. **Source contracts and provenance** fix required columns, publication
   vintage, observation month and selected source ownership.
3. **Source tables** are validated and independently reduced to one row per
   standardised practice code and reporting month.
4. **The union spine** contains every eligible source key and preserves source
   presence or absence.
5. **Question-specific joins** retain source-led or matched populations.
6. **Annual matrices** are created only for exactly twelve complete eligible
   months.
7. **Validation** checks schemas, cardinality, source totals, missingness,
   numerical integrity and deterministic fingerprints.

The reusable pipeline can be configured for other consecutive periods when
compatible official source files are prepared. The repository includes a
verified April 2025 to March 2026 reference application.

## Identity and activity

`practice_code_standardised` is the linkage key. ODS practice codes support
organisational identity checks but do not supply activity. Activity measures
remain source-specific:

- OCS submissions are not GPAD appointments;
- GPAD appointments are not CBT calls; and
- no source is treated as total demand.

## Grain and cardinality

Each source must be one row per practice-month before integration. Every
practice-month join uses both practice code and reporting month. The union
spine prevents an inner join from hiding source-only reporting. Annual
aggregation occurs only after practice-month uniqueness and month completeness
have passed.

See [Grain and cardinality](../concepts/GRAIN_AND_CARDINALITY.md) and
[How the joins work](../HOW_THE_JOINS_WORK.md) for the detailed SQL reasoning.

## Reference application

The [April 2025 to March 2026 reference application](../reference-applications/apr2025-mar2026.md)
contains frozen output contracts and validation evidence. It demonstrates the
pipeline; it does not limit PCADI to that period.
