# NHS and ICB analyst guide

Use this route to construct a practice-month dataset for a selected period and choose an output whose retained population matches the analytical question.

## 1. Define the period

Read the [period configuration guide](../PERIOD_CONFIGURATION.md). PCADI accepts any positive number of consecutive months when compatible official source files are available. Annual matrices require exactly twelve complete eligible months.

## 2. Obtain and record sources

Use the [official NHS data guide](../get-official-nhs-data/README.md). Record:

- publication page and direct resource URL;
- publication date and observation month;
- selected archive member;
- file size and checksum; and
- one selected owner for each dataset-component-month.

## 3. Prepare contract-controlled inputs

Create the four CSVs defined in [`contracts/sources`](../../contracts/sources). Do not convert absent reporting to zero. Validate practice codes and reduce each activity source to one row per practice-month before integration.

## 4. Run and select an output

Run `RUN_PIPELINE.cmd` with the selected configuration. Then use the [analytical design index](../analytical-designs/README.md) to choose a coverage, matched or annual output.

Review `pipeline_validation_results.csv`. Do not use an output when a mandatory gate fails.

## Interpretation

OCS submissions, GPAD appointments and CBT calls are distinct recorded activities. Rates normalise activity by documented registered-patient denominators. They do not measure total demand or patient journeys. Profiles should not be interpreted as performance rankings.
