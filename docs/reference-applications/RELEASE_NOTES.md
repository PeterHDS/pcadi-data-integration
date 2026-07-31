# PCADI reference outputs: April 2025 to March 2026

This release publishes the verified April 2025 to March 2026 reference application of PCADI.

## Included output families

- coverage-preserving and source-led practice-month views;
- matched OCS-GPAD and OCS-GPAD-CBT views;
- annual OCS-GPAD practice profiles;
- CBT inbound and outcome-complete restricted cohorts; and
- supplementary within-week temporal features.

## Annual analytical matrices

| Matrix | Practices | Numerical features |
|---|---:|---:|
| National annual OCS-GPAD matrix | 6,067 | 14 |
| CBT inbound restricted cohort | 3,020 | 17 |
| CBT outcome-complete restricted cohort | 1,456 | 21 |

The smaller CBT cohorts reflect evidence availability. They are nested inside the national matrix and inherit every shared parent value exactly.

## Validation

The archive contains 14 complete CSV outputs. File dimensions, schemas and SHA-256 fingerprints are recorded in the [authoritative output manifest](../../validation/authoritative_output_manifest.csv). Run `RUN_REFERENCE_VALIDATION.cmd` or the equivalent Python command to retrieve and verify release-only outputs.

## Interpretation scope

OCS submissions, GPAD appointments and CBT calls remain separate operational measures. Missing reporting preserves its documented status and remains distinct from observed zero activity. Performance, safety, equity, value, patient outcomes and patient journeys require additional evidence and study designs.

PCADI is reusable for other consecutive observation periods when compatible official source files are obtained and prepared. Annual matrices require exactly twelve complete eligible months under the current contract.

PCADI is independently maintained and draws on published NHS England data and documentation.
