# Configure an observation period

PCADI separates pipeline capability from the official prepared data included in
the repository.

## What can be configured

A practice-month run may cover any positive number of consecutive months when
the required compatible source files are available:

```powershell
python automation/pipeline_cli.py make-config `
  --start 2026-03 --months 3 `
  --output configs/my_period.json
```

The command writes the start month, end month and expected month count. It does
not download or infer missing official source data.

Generate a collection checklist:

```powershell
python automation/pipeline_cli.py data-checklist `
  --config configs/my_period.json `
  --output work/my_period_data_checklist.csv
```

Use the [official source guide](get-official-nhs-data/README.md) to obtain the
required files, then prepare the CSV interfaces defined in
[`contracts/sources`](../contracts/sources).

## Annual matrices

Annual practice-profile matrices are a distinct analytical branch. Under the
current contract they require exactly twelve complete eligible months. A
one-month, three-month or 24-month practice-month run does not automatically
produce an annual matrix.

To request the annual branch:

```powershell
python automation/pipeline_cli.py make-config `
  --start 2025-04 --months 12 `
  --annual-features `
  --output configs/my_annual_period.json
```

Twelve configured months do not guarantee that every practice qualifies.
Practice-level completeness and source eligibility rules still apply.

## Included and synthetic periods

- April 2025 to March 2026 is the included official verified reference
  application.
- One-, three- and twenty-four-month demonstrations use deterministic
  synthetic data.
- A different official three-month or 24-month run requires the corresponding
  source files.
- PCADI does not maintain a complete mirror of NHS England publications.

## Run and validate

```powershell
python automation/pipeline_cli.py run `
  --config configs/my_period.json `
  --input-dir data/prepared `
  --output-dir work/my_period_output `
  --database work/my_period.sqlite `
  --overwrite
```

Review `pipeline_validation_results.csv` and the run report before using any
output. Missing source rows are not automatically converted to zero.
