# Synthetic examples

The fixtures are generated under the ignored `work/` directory so their content
is reproducible from code rather than maintained manually.

```powershell
python automation/create_synthetic_data.py --output work/example-3 --months 3
python automation/create_synthetic_data.py --output work/example-12 --months 12
python automation/create_synthetic_data.py --output work/example-24 --months 24 --start-month 2024-01
```

They contain invented identifiers and values only. Any positive month count can
be used to test configurable practice-month coverage and matched populations.
Exactly twelve months also enables the synthetic annual ratios, mutually
exclusive GPAD booking intervals and CBT sensitivity matrices.
