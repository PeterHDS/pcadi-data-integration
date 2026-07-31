# Research context

PCADI was developed as the executable and documentary data-integration component of an MSc Data Science dissertation. The study examines recorded online-consultation, appointment and telephony activity through reproducible practice-level access-activity profiles and a separate evidence-readiness framework.

## Role of PCADI

PCADI provides the source-to-matrix layer:

- publication provenance and source-month ownership;
- standardised source tables at practice-month grain;
- reporting coverage and source-specific missingness;
- question-specific retained populations and joins;
- annual matrices under explicit twelve-month eligibility rules; and
- schema, dimension, numerical-integrity, nesting and fingerprint validation.

The repository's current analytical boundary is documented in [Project architecture](PROJECT_ARCHITECTURE.md). Downstream model selection, clustering, interpretation, sensitivity analysis and external contextual evidence use the validated PCADI contracts under separate analytical specifications.

## Academic inspection route

An examiner or academic reviewer can:

1. Read the [verified reference application](reference-applications/apr2025-mar2026.md).
2. Inspect the [analytical contract and lineage](audits/ANALYTICAL_CONTRACT_AND_LINEAGE.md).
3. Review the [cohort flow](architecture/COHORT_FLOW.md).
4. Run the [reference validation](VALIDATION_METHOD.md).
5. Inspect the national annual matrix through the [examiner guide](audiences/examiner-guide.md).
6. Trace official and research sources through [Evidence base and references](EVIDENCE_BASE_AND_REFERENCES.md).

The academic application demonstrates one complete use of PCADI. The integration workflow remains reusable for compatible periods and related primary-care activity questions.
