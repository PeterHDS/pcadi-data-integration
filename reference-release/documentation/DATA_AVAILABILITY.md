# Data availability for the fixed reference release

The repository includes transformation code, source manifests, documentation,
aggregate validation evidence, deterministic derived outputs and checksums. It
does not include the large original NHS CSVs or SQLite working databases.

## Obtain the source files

The underlying publications are available from NHS England:

- *Submissions via Online Consultation Systems in General Practice, May 2026*;
- monthly *Appointments in General Practice* practice-level releases covering
  April 2025 to March 2026; and
- the associated practice mappings, metadata and supporting information.

Official series pages are listed in
`reference-release/documentation/OFFICIAL_SOURCE_REFERENCES.md`. Web locations
can change, so a newly downloaded file is suitable for exact reconstruction
only when its SHA-256, header and row count match
`reference-release/input_manifest.csv`.

## Place the files

Use each manifest row's `recommended_relative_path`. Do not rename headers,
change encoding, re-save the CSV or pre-aggregate it. Such changes alter the
file hash and can change missing-value or numerical semantics.

## Publication vintage and observation period

The reference uses selected publication vintages because historical OCS values
can be revised. A publication released after March 2026 may legitimately own
an observation from April 2025 to March 2026. Publication date and observation
month therefore remain separate provenance fields.

The source files contain aggregate practice-level records rather than
patient-level identifiers. Users must still follow NHS England publication
terms and their institution's research-data policies.
