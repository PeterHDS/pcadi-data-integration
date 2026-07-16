# Data availability

The repository does not redistribute NHS England source files. Obtain OCS,
GPAD, CBT and registered-patient evidence from the official publication pages
listed in `pipeline/source_registry/official_sources.csv`.

The publication page, downloadable resource, metadata, publication date,
observation month, file checksum and selection decision must be retained in
`source_provenance.csv`. A later publication may revise an earlier observation
month; the pipeline therefore requires exactly one selected vintage for each
dataset-component-month.

The dissertation reference release contains derived aggregate practice-level
outputs and checksums, not patient-level information. Users remain responsible
for the source publication terms, the Open Government Licence where applicable,
institutional policy and appropriate interpretation.
