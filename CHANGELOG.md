# Changelog

## 1.0.1 - 2026-07-16

- Restored the seven release-only practice-month outputs during clean-checkout
  validation after verifying the published ZIP size and SHA-256 checksum.
- Preserved the validated byte representation of the temporal reference CSV so
  Git line-ending normalisation cannot change its deterministic fingerprint.
- Removed the completed pre-publication-only check that prohibited Git metadata
  from existing inside a published checkout.

No SQL logic, analytical values, cohorts or validated conclusions changed in
this packaging correction.

## 1.0.0 - pre-publication candidate

- Added a configurable practice-month SQL pipeline for contiguous periods.
- Added official NHS England acquisition guidance and provenance ownership gates.
- Added purpose-led coverage, matched-cohort, sensitivity and annual outputs.
- Added a question-to-output guide and source catalogue so each analytical
  route states its evidence requirements, retained population and limits.
- Added deterministic demonstrations for any positive number of months.
- Added optional twelve-month annual profiles with an explicit eligibility
  gate.
- Added frozen dissertation reference outputs, checksums and validation evidence.

This is the first intended public release. No earlier development build is
presented as a public software release.
