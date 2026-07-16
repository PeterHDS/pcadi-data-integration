# Analyst guide

## 1. Begin with the question

Check `docs/SOURCE_CATALOGUE.md`, then choose the analytical design in
`docs/analytical-designs/README.md`. Broad coverage, matched-source comparison
and annual profiles retain different populations and are not interchangeable.

## 2. Configure the observation period

Generate a configuration with `make-config`. Supply a start month and either an
inclusive end month or a positive number of consecutive months. Dates mean
observation months, not publication months.

```powershell
python automation/pipeline_cli.py make-config `
  --start 2024-01 --months 24 `
  --output configs/my_period.json
```

Practice-month tables accept any period length. Add `--annual-features` only
when an exactly twelve-month annual profile is required.

## 3. Obtain official data

Run `data-checklist`, visit the NHS England pages and retain the CSV/ZIP,
metadata and supporting information. Do not rely on the filename alone.

## 4. Establish vintage ownership

Create `source_provenance.csv`. Exactly one selected publication vintage must
own each required dataset-component-observation-month. If the evidence is
ambiguous, stop rather than append overlapping releases.

## 5. Prepare source-contract tables

Create the three CSVs defined in `contracts/sources/`. They must each contain at
most one row per practice-month. Source-specific aggregation must precede the
multichannel join.

## 6. Run and review

Run the pipeline. Do not use an output if any validation row fails. Absence of a
source row is not zero activity. A configuration of any length produces
practice-month outputs; the optional annual product requires exactly twelve
complete months and an explicit request in the configuration.
