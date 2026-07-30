# Start here

Choose a route by what needs to be done.

| Purpose | Route |
|---|---|
| Understand the workflow | [Architecture and data flow](docs/architecture/PIPELINE_ARCHITECTURE.md) |
| Demonstrate it without NHS data | [Run the synthetic example](examples/synthetic/README.md) |
| Build a selected period | [Configure a period](docs/PERIOD_CONFIGURATION.md) |
| Choose an output | [Compare analytical designs](docs/analytical-designs/README.md) |
| Inspect the included reference application | [April 2025 to March 2026](docs/reference-applications/apr2025-mar2026.md) |
| Validate outputs | [Validation method](docs/VALIDATION_METHOD.md) |
| Review all technical controls | [Technical reviewer guide](docs/audiences/technical-reviewer.md) |

## Demonstrate the method

Install Python 3.11 or newer, then clone the repository or download and extract
its ZIP:

```powershell
python automation/pipeline_cli.py demo --months 3
```

On Windows, double-click `RUN_DEMO.cmd`. The command creates deterministic
synthetic inputs, runs the configurable SQL and writes validation evidence
under `work/demo_3_months/outputs/`. It uses no official NHS data and runs no
clustering.

## Build a chosen observation period

PCADI accepts any positive number of consecutive months when compatible
official source inputs are available:

```powershell
python automation/pipeline_cli.py make-config `
  --start 2024-01 --months 24 `
  --output configs/my_period.json
```

Then:

1. generate a collection checklist with `data-checklist`;
2. use the linked NHS England publication pages to obtain the required files;
3. record release vintage and one selected owner for each
   dataset-component-month;
4. prepare the four CSVs defined in `contracts/sources/`;
5. run `RUN_PIPELINE.cmd configs\my_period.json`; and
6. inspect `pipeline_validation_results.csv`.

Practice-month outputs can cover one month, three months, 24 months or another
contiguous range. Annual practice matrices are a separate branch that requires
exactly twelve complete eligible months.

## Inspect the verified reference outputs

The repository includes official verified outputs for April 2025 to March
2026. Run:

```powershell
python automation/pipeline_cli.py validate-reference `
  --restore-missing `
  --output work/reference_validation.csv
```

The command retrieves any absent release-only CSVs from the period-labelled
reference asset, checks the archive, and verifies all fourteen registered
outputs. Use `RUN_REFERENCE_BUILD.cmd` only when the exact 21 selected source
CSVs are available and a full source reconstruction is required.

## Choose an analytical output

Different joins retain different practice-month populations. The
[analytical design guide](docs/analytical-designs/README.md) links each
analytical question to its population, grain, sources, output and main
limitation.

## Reader-specific guides

- [Examiner or academic reviewer](docs/audiences/examiner-guide.md)
- [NHS or ICB analyst](docs/audiences/analyst-guide.md)
- [Learner](docs/audiences/learner-tutorial.md)
- [Technical reviewer](docs/audiences/technical-reviewer.md)
- [Maintainer](docs/audiences/maintainer-guide.md)

PCADI is an independent academic project. It is not an NHS England product or
an official performance system.
