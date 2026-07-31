# Start here

Choose a route by the task to complete.

| Goal | Route | First action |
|---|---|---|
| Understand the data flow | [Project architecture](docs/PROJECT_ARCHITECTURE.md) | Review the source-to-output diagram and boundaries |
| Demonstrate the pipeline without NHS data | [Synthetic demonstration](examples/synthetic/README.md) | Run `RUN_DEMO.cmd` or the Python command below |
| Obtain official source files | [Official NHS data guide](docs/get-official-nhs-data/README.md) | Select a period and record publication vintages |
| Build a chosen period | [Period configuration](docs/PERIOD_CONFIGURATION.md) | Create a JSON configuration and source checklist |
| Choose an output | [Analytical design index](docs/analytical-designs/README.md) | Match the research question to a retained population |
| Follow a complete task | [Practical use cases](docs/PRACTICAL_USE_CASES.md) | Select the workflow closest to the intended analysis |
| Inspect the reference outputs | [April 2025 to March 2026 application](docs/reference-applications/apr2025-mar2026.md) | Review the three annual contracts and validation evidence |
| Validate files | [Validation method](docs/VALIDATION_METHOD.md) | Run reference validation and inspect every mandatory gate |

## Run the demonstration

Install Python 3.11 or newer, then clone the repository or download and extract its ZIP:

```powershell
python automation/pipeline_cli.py demo --months 3
```

On Windows, double-click `RUN_DEMO.cmd`. The command creates deterministic synthetic inputs, runs the configurable SQL and writes validation evidence under `work/demo_3_months/outputs/`.

## Build a chosen observation period

PCADI accepts a positive number of consecutive months when compatible official source inputs are available:

```powershell
python automation/pipeline_cli.py make-config `
  --start 2024-01 --months 24 `
  --output configs/my_period.json
```

Continue in this order:

1. Generate a collection checklist with `data-checklist`.
2. Use the linked NHS England publication pages to obtain the required files.
3. Record publication vintage and one selected owner for every dataset-component-month.
4. Prepare the four CSVs defined in [`contracts/sources`](contracts/sources).
5. Run `RUN_PIPELINE.cmd configs\my_period.json`.
6. Inspect every row in `pipeline_validation_results.csv`.

Practice-month outputs can cover one, three, twelve, twenty-four or another contiguous number of months. The annual practice matrices use exactly twelve complete eligible months.

## Inspect the verified reference outputs

The repository includes verified outputs for April 2025 to March 2026. Run:

```powershell
python automation/pipeline_cli.py validate-reference `
  --restore-missing `
  --output work/reference_validation.csv
```

The command retrieves absent release-only CSVs from the period-labelled reference asset, verifies the archive and checks all fourteen registered outputs. `RUN_REFERENCE_BUILD.cmd` provides the full source reconstruction route when the exact twenty-one selected source CSVs are available.

## Reader guides

- [Examiner or academic reviewer](docs/audiences/examiner-guide.md)
- [NHS or ICB analyst](docs/audiences/analyst-guide.md)
- [Learner](docs/audiences/learner-tutorial.md)
- [Technical reviewer](docs/audiences/technical-reviewer.md)
- [Maintainer](docs/audiences/maintainer-guide.md)

PCADI is independently maintained and draws on published NHS England data and documentation. Methodological and reproducibility questions can be raised through [GitHub Issues](https://github.com/PeterHDS/pcadi-data-integration/issues).
