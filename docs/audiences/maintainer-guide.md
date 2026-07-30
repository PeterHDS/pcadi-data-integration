# Maintainer guide

## Adding a publication

Do not overwrite an earlier release definition. Record the publication page,
resource URL, retrieval date, observation months, checksum, archive members and
metadata. Add selected and non-selected candidates to the provenance evidence.

## Handling schema changes

If a header fails its JSON contract, compare the new official metadata with the
previous definition. Add a versioned adapter or contract and a synthetic test.
Do not add an alias solely because two columns have similar names.

## Release gates

Run:

```powershell
python automation/pipeline_cli.py demo --months 3
python automation/pipeline_cli.py demo --months 12
python automation/pipeline_cli.py demo --months 24 --start-month 2024-01
python automation/pipeline_cli.py validate-reference --restore-missing --output work/reference_validation.csv
python tests/run_tests.py
python automation/prepare_publication_manifest.py
```

Review the publication manifest before Git. A new software release that changes
an output formula requires a documented data-contract version change.

When reference outputs change, run
`python automation/refresh_reference_metadata.py`. Build the planned release
archive with `python automation/build_reference_release_asset.py`, then verify the
archive hash in `reference-release/validation/release_asset_manifest.csv`.
