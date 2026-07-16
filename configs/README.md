# Observation-period configurations

A configuration defines the inclusive observation window and whether the
optional annual profile should be built. It does not identify publication
vintage; source ownership is recorded separately in `source_provenance.csv`.

Create a runnable configuration instead of calculating the end date manually:

```powershell
python automation/pipeline_cli.py make-config `
  --start 2026-03 --months 1 `
  --output configs/one_month.json

python automation/pipeline_cli.py make-config `
  --start 2024-04 --months 24 `
  --output configs/twenty_four_months.json
```

You may use `--end YYYY-MM` instead of `--months N`. Both bounds are inclusive.
The command calculates `expected_months` and rejects invalid dates.

Practice-month integration accepts any positive number of consecutive months.
The `--annual-features` option is accepted only for exactly twelve months
because that output is defined as one complete twelve-month profile per
practice.

Included examples:

- `example_three_month_period.json` demonstrates a short custom panel;
- `dissertation_reference_2025_04_to_2026_03.json` preserves the fixed academic
  reference period; and
- `rolling_twelve_month_period.json` is a runnable twelve-month example. Prefer
  `make-config` to create the exact window required for a new analysis.
