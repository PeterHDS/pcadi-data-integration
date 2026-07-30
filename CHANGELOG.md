# Changelog

## 2.0.0 - pending review

- Restored separate GPAD 1-day and 2-to-7-day shares in the authoritative
  national, CBT inbound and CBT outcome-complete matrices.
- Locked the 6,067 by 15, 3,020 by 18 and 1,456 by 22 CSV interfaces with exact
  schema, inheritance and checksum gates.
- Reorganised public documentation around analytical questions and retained
  populations.
- Added architecture, cohort-flow, migration and individual analytical-design
  guides.
- Removed superseded modelling matrices from the active output directory and
  recorded their historical hashes in a machine-readable register.

The release is prepared on a review branch. It remains pending until the pull
request is approved and the v2.0.0 release asset is published.

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
