# Start here

Choose the route that matches your purpose.

## See the method run

Install Python 3.11 or newer, then clone the repository or download and extract
its ZIP. No third-party Python packages are required.

Double-click `RUN_DEMO.cmd`. It creates deterministic synthetic data, executes
the configurable SQL and writes validation evidence under `work/`. No official
NHS files are needed. A successful run reports 16 validation passes and zero
failures.

## Integrate a chosen observation period

Create a configuration for any positive number of consecutive months:

```powershell
python automation/pipeline_cli.py make-config `
  --start 2024-01 --months 24 `
  --output configs/my_period.json
```

Then:

1. generate a collection checklist with `data-checklist`;
2. download the required resources from the linked NHS England pages;
3. record publication provenance and one selected source owner per required
   dataset-component-month;
4. prepare the four CSVs defined in `contracts/sources/`;
5. run `RUN_PIPELINE.cmd configs\my_period.json`; and
6. inspect `pipeline_validation_results.csv` before analysis.

The practice-month outputs support one month, twelve months, twenty-four months
or another contiguous range. Annual practice profiles are optional and require
exactly twelve complete months.

## Review the fixed dissertation evidence

Run `RUN_REFERENCE_VALIDATION.cmd`. It verifies the frozen April 2025 to March
2026 output checksums without rebuilding the large databases. On a clean
checkout of v1.0.0, the command downloads and verifies the pinned 40.7 MB
dissertation reference archive before checking all fourteen outputs.
Use
`RUN_REFERENCE_BUILD.cmd` only when the 21 exact source CSVs are available and
a complete raw-source reconstruction is required.

A created CSV is not sufficient evidence of a valid run. Use an output only
when every mandatory validation row passes and its retained population is
appropriate for the analytical question.

## Choose an analytical output

Different joins retain different practice-month populations. Use the
[analytical design guide](docs/analytical-designs/README.md) to move from a
question to the appropriate table, and check the
[source catalogue](docs/SOURCE_CATALOGUE.md) before interpreting its measures.

## Inspect the fixed matrices

The national matrix contains 6,067 practices and fourteen numerical features.
The CBT inbound and outcome-complete matrices contain 3,020 practices with
seventeen features and 1,456 practices with twenty-one raw features.

Start with the [cohort flow](docs/architecture/COHORT_FLOW.md), then run
`RUN_REFERENCE_VALIDATION.cmd` to check the exact schemas and SHA-256 hashes.
