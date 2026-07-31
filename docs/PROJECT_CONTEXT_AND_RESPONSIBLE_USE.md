# Project context and responsible use

## What PCADI processes

PCADI prepares published NHS England data on Online Consultation Systems in General Practice (OCS), Appointments in General Practice (GPAD), Cloud Based Telephony in General Practice (CBT) and Patients Registered at a GP Practice. Organisation Data Service practice codes provide the linkage key. The pipeline records publication vintage, observation month, source ownership, retained population and validation status.

## Questions supported by the outputs

The practice-month outputs support questions about reporting coverage, recorded online-consultation activity, recorded appointments, telephony activity and their patterns across common practice-month keys. The annual matrices support practice-level comparison of recorded activity configurations across a documented twelve-month cohort. The supplementary timing design supports comparison of separate OCS and CBT distributions within defensibly aligned day and time buckets.

Each design specifies its retained population. Source-led designs preserve the selected source population, matched designs retain common keys, the coverage spine retains the union of available source keys, and annual designs apply explicit month-completeness rules.

## Coverage, missingness and zero

PCADI records source presence separately from activity values. An observed zero is retained as a reported value. A missing practice-month, supplier non-submission, mapping gap, structural absence or excluded integrity component retains its documented source-specific status. This distinction keeps reporting coverage available for audit and prevents absence from acquiring an activity meaning.

## Measure scope

OCS submissions, GPAD appointments and CBT calls describe separate operational records. Registered-patient counts provide month-matched practice-size denominators for documented per-1,000 rates. ODS codes identify practices. Together these fields support analysis of recorded activity and reporting availability.

Workforce, patient experience, deprivation, quality, safety, outcomes and patient journeys require separately governed evidence. Downstream analysis should state its method, assumptions, uncertainty and linkage rules alongside the PCADI input contract.

## Extending the matrices

External evidence can be linked by a compatible practice identifier and reference period after its provenance, grain, completeness and population have been audited. The linked analysis should preserve the PCADI practice identifier, report unmatched records and distinguish descriptive association from causal interpretation.

## Citation and source acknowledgement

Reuse should cite PCADI through [`CITATION.cff`](../CITATION.cff), every official publication used for the selected period, the downstream analytical method and the associated study where findings are reused. The [evidence base and references](EVIDENCE_BASE_AND_REFERENCES.md) page provides source-family links and citation guidance.

## Governance and questions

PCADI is independently maintained and draws on published NHS England data and documentation. Use [GitHub Issues](https://github.com/PeterHDS/pcadi-data-integration/issues) for reproducibility questions, proposed source-contract changes or documented methodological concerns. Security and sensitive-data matters follow the [security guide](../.github/SECURITY.md).
