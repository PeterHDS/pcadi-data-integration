# SQL organisation

`portable/` is the configurable pipeline for one month, twelve months,
twenty-four months or any other positive contiguous period. It starts from
validated canonical practice-month contracts, builds tables for distinct
analytical populations and records mandatory evidence.

`core_pipeline/` is the complete ordered OCS/GPAD raw-source reconstruction for
the frozen dissertation reference period. It preserves the exact known source
schemas, expected counts and twelve-month annual feature rules.

The top-level temporal script is retained as reference-release SQL evidence for
the separate day/time analysis. New users should begin with `portable/` and use
`core_pipeline/` when reproducing the fixed raw-source build.

Execution order is encoded in filenames. Numerical prefixes describe SQL stage
order, not analytical-design names.
