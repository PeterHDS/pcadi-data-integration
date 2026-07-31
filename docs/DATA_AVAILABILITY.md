# Data availability

Official OCS, GPAD, CBT and registered-patient source files are available through the NHS England publication pages listed in [`pipeline/source_registry/official_sources.csv`](../pipeline/source_registry/official_sources.csv) and the [official NHS data guide](get-official-nhs-data/README.md). Users obtain the publications required for their selected period and record the publication page, downloadable resource, metadata, publication date, observation month, file checksum and selection decision in `source_provenance.csv`.

A later publication can revise an earlier observation month. PCADI therefore assigns exactly one selected vintage to each dataset-component-month and records candidate releases before import.

The repository includes derived aggregate practice-level reference outputs, source manifests and checksums. Official raw downloads and working databases remain in the user's governed workspace. The sources and included outputs contain aggregate organisational records rather than patient-level records.

Reuse follows the applicable source publication terms, the Open Government Licence where stated, institutional policy and the interpretation contract documented in [Project context and responsible use](PROJECT_CONTEXT_AND_RESPONSIBLE_USE.md).
