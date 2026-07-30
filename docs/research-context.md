# Research context

PCADI was developed alongside an MSc Data Science project for module DS7010.
The project examined whether recorded online-consultation, appointment and
telephony activity could be integrated into reproducible practice-level access
activity profiles.

## Role of PCADI

PCADI provides the data-integration layer:

- records publication provenance and source-month ownership;
- standardises source tables at practice-month grain;
- preserves missingness and reporting coverage;
- creates question-specific joins;
- constructs annual matrices under explicit twelve-month eligibility rules;
  and
- validates schemas, dimensions, numerical integrity and fingerprints.

Downstream exploratory analysis, clustering, interpretation and sensitivity
comparisons are separate from this repository. PCADI does not reproduce those
models or claim that integrated activity measures total demand, access quality
or patient outcomes.

## Academic inspection route

An examiner or academic reviewer can:

1. read the [verified reference application](reference-applications/apr2025-mar2026.md);
2. inspect the [analytical contract and lineage](audits/ANALYTICAL_CONTRACT_AND_LINEAGE.md);
3. review the [cohort flow](architecture/COHORT_FLOW.md);
4. run the [reference validation](VALIDATION_METHOD.md); and
5. inspect the national annual matrix through the
   [examiner guide](audiences/examiner-guide.md).

This academic origin is one use of PCADI. The repository remains a reusable
analytical pipeline for other compatible periods and research questions.
