# Project architecture

PCADI is the data-integration layer between official primary-care activity publications and independently governed downstream analysis.

![PCADI architecture from official publications through source contracts, practice-month tables, analytical outputs and validation](assets/pcadi-architecture.svg)

## Responsibility and data flow

```text
Official publications
  -> source contracts and provenance
  -> validated practice-month source tables
       |-> coverage/provenance union spine -> purpose-led practice-month views
       `-> matched OCS-GPAD-denominator panel -> annual national matrix
                                                    `-> nested prepared-CBT matrices
  -> validation and reference outputs
```

1. **Official publications** supply OCS, GPAD, CBT and registered-patient measures. ODS practice codes identify organisations.
2. **Source contracts and provenance** specify required columns, observation months, publication vintages and one selected source owner for each dataset-component-month.
3. **Practice-month preparation** standardises identifiers and dates, validates source integrity, aggregates each source independently and establishes one row per practice-month.
4. **Coverage-preserving and matched joins** construct different retained populations. The reusable union spine supports coverage and provenance questions; source-led and matched designs retain their own documented key populations.
5. **Verified annual lineage** separately matches validated OCS, GPAD and month-specific registered-patient evidence before applying twelve-month completeness and finite-feature rules.
6. **Annual matrices** publish a 14-feature national OCS-GPAD contract. Validated prepared CBT evidence defines nested 17- and 21-feature restricted contracts through a separate evidence layer from the national 21-file raw-source route.
7. **Validation and reference outputs** record schema, dimensions, cardinality, missingness, source totals, cohort nesting, inherited values and deterministic checksums.

## Separation of concerns

| Layer | Responsibility | Main locations |
|---|---|---|
| Configuration | Observation period and prepared-input locations | `configs/`, `contracts/` |
| Source preparation | Identifier, date, type and source-family standardisation | `sql/core_pipeline/01` to `06`, `sql/portable/01` |
| Integration | Practice-month spine and question-specific joins | `sql/core_pipeline/07` to `08`, `sql/portable/02` |
| Annual features | Eligibility, documented aggregates and nested cohorts | `sql/core_pipeline/09` to `10`, `sql/portable/03` to `04` |
| Validation | Mandatory SQL gates, output contracts and checksums | `sql/core_pipeline/11` to `12`, `sql/portable/05`, `validation/` |
| Orchestration | Repeatable commands, manifests and exports | `automation/`, root `RUN_*.cmd` files |

This separation keeps SQL definitions inspectable and allows configuration, orchestration and validation to evolve around stable analytical contracts.

## Identity, grain and cardinality

`practice_code_standardised` is the linkage key. ODS reference information supports organisational identity and relevant geography checks. Activity remains within its source family. Each prepared source is unique at practice-month grain before integration, while the temporal design adds documented day and time dimensions before joining.

The union spine preserves source-only reporting. Source-led joins retain the population that anchors the question. Matched joins retain documented common keys. In the verified reference implementation, annual aggregation begins from a separately validated matched OCS-GPAD-denominator panel after practice-month uniqueness passes. See [Grain and cardinality](concepts/GRAIN_AND_CARDINALITY.md) and [How the joins work](HOW_THE_JOINS_WORK.md).

## Reference application and configurable periods

The [April 2025 to March 2026 reference application](reference-applications/apr2025-mar2026.md) demonstrates the complete pipeline with frozen output contracts. The configurable branch supports other consecutive periods when compatible official source files satisfy the same contracts. Synthetic demonstrations exercise one-, three-, twelve- and twenty-four-month configurations.

## Downstream analytical boundary

PCADI's published responsibility ends with source preparation, SQL integration, cohort construction, validated feature matrices, provenance and reference-output validation. Model selection, clustering, profile interpretation, sensitivity testing, temporal robustness, external contextual analysis and visual reporting are downstream activities performed under their own analytical specifications.

The reference matrices are reusable inputs for clustering, descriptive comparison or external linkage. Their identifiers, features, cohort definitions and validation evidence remain attached so later work can trace every result back to a documented integration contract.
