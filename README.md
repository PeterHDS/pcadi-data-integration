# PCADI — Primary Care Activity Data Integration

*A reproducible pipeline for integrating NHS England OCS, GPAD and CBT data
across configurable observation periods.*

This repository provides a reproducible SQL method for integrating three
official NHS England data sources at general-practice and reporting-month
level:

- Online Consultation Systems (OCS);
- General Practice Appointment Data (GPAD); and
- Cloud Based Telephony (CBT).

The user chooses the observation period. A run may cover one month, twelve
months, twenty-four months or any other positive number of consecutive months.
The pipeline derives the inclusive month count, checks that every selected
source belongs to that window and produces practice-month tables without
assuming that twelve months is always the correct analytical choice.

The repository also preserves a fixed April 2025 to March 2026 release used in
an MSc Data Science dissertation. That release is a reproducible case study,
not a limit built into the general pipeline.

This is an independent academic project, not an NHS England product. OCS
submissions, GPAD appointments and CBT calls describe different activities.
Their counts remain separate and are never presented as a combined measure of
total demand.

## Questions this repository can support

The integration is designed to support questions such as:

- Where are OCS, GPAD and CBT records present or absent by practice and month?
- How do recorded online-consultation and appointment patterns compare where
  both sources are observed?
- What changes when a comparison is restricted to practices with valid CBT
  evidence?
- Which practices have complete evidence for a twelve-month annual profile?
- How are separate OCS and CBT activities distributed within the week when
  compatible official day/time evidence is available?

The outputs cannot establish patient-level links, total demand, access quality,
unmet need, channel substitution or causality. Start with the
[source catalogue](docs/SOURCE_CATALOGUE.md) to understand what each dataset
records, then use the [analytical design guide](docs/analytical-designs/README.md)
to select the population that fits the question.

## Choose a route

- **Review the dissertation method:** run `RUN_DEMO.cmd`, then follow the
  [examiner guide](docs/audiences/examiner-guide.md).
- **Integrate a period of your choice:** follow the
  [analyst guide](docs/audiences/analyst-guide.md).
- **Learn the SQL design:** use the
  [learner tutorial](docs/audiences/learner-tutorial.md).
- **Assess engineering quality:** read the
  [technical reviewer overview](docs/audiences/technical-reviewer.md).
- **Maintain or extend the pipeline:** use the
  [maintainer guide](docs/audiences/maintainer-guide.md).

## Controls applied by the pipeline

For a correctly prepared input set, the pipeline:

1. treats publication release date and observation month as different facts;
2. requires one selected publication source for each required
   dataset-component-month;
3. validates headers, types, practice identifiers and the configured period;
4. reduces each source to one row per practice and month before any join;
5. joins on both practice code and reporting month;
6. preserves the union of observed practice-month keys and records which
   sources are present;
7. keeps observed zero, SQL null, absent row, non-participation and integrity
   gaps distinct;
8. checks reconciliation, uniqueness and row multiplication; and
9. exports deterministic tables plus expected-versus-observed validation
   evidence.

SQL contains the transformations, joins and feature calculations. Python uses
only the standard library and handles configuration, input checks, CSV
import/export, checksums and execution order.

## Try it without NHS data

On Windows, double-click:

```text
RUN_DEMO.cmd
```

Or run a synthetic demonstration for any period length:

```powershell
python automation/pipeline_cli.py demo --months 1
python automation/pipeline_cli.py demo --months 24 --start-month 2024-01
```

The generated values and practice identifiers are invented. They exercise the
same configurable SQL used for prepared official data. No clustering is run.

## Configure any observation period

Create a configuration by giving either an inclusive end month or a number of
months. These two commands both define March through May 2026:

```powershell
python automation/pipeline_cli.py make-config `
  --start 2026-03 --end 2026-05 `
  --output configs/my_period.json

python automation/pipeline_cli.py make-config `
  --start 2026-03 --months 3 `
  --output configs/my_period.json
```

For a twenty-four-month panel, change `--months 3` to `--months 24`. The same
practice-month SQL runs for either period. The optional annual profile is a
different product: request it with `--annual-features`, and only for exactly
twelve months.

Next, generate the official-data collection plan:

```powershell
python automation/pipeline_cli.py data-checklist `
  --config configs/my_period.json `
  --output work/my_period_data_checklist.csv
```

After obtaining the official resources and preparing the four files defined in
[`contracts/sources`](contracts/sources):

```powershell
python automation/pipeline_cli.py run `
  --config configs/my_period.json `
  --input-dir data/prepared `
  --output-dir work/my_period_output `
  --database work/my_period.sqlite `
  --overwrite
```

On Windows, `RUN_PIPELINE.cmd` prompts for a start month and number of months.
It can also receive an existing configuration path as its first argument.

## Choose the output that answers the question

The pipeline does not claim that one join is universally best. It creates
several outputs because each retains a different population:

| Question | Use this output | Evidence required | Supported period |
|---|---|---|---|
| Where is each source present or absent? | `multichannel_practice_month_coverage` | Any observed OCS, GPAD or CBT record | Any configured period |
| What appointment evidence accompanies OCS reporting? | `online_consultation_cohort_with_appointment_context` | OCS defines the population; GPAD is attached where available | Any configured period |
| What OCS evidence accompanies GPAD reporting? | `appointment_cohort_with_online_consultation_context` | GPAD defines the population; OCS is attached where available | Any configured period |
| How do OCS and GPAD compare where both are observed? | `matched_online_and_scheduled_activity` | OCS and GPAD for the same practice-month | Any configured period |
| What does a matched three-source population show? | `matched_multichannel_activity` | OCS, GPAD and validly mapped CBT for the same practice-month | Any configured period |
| Are OCS-GPAD findings similar in the CBT-observed subset? | `telephony_observed_comparative_cohort` | Matched OCS-GPAD plus observed CBT | Any configured period |
| What is a complete annual practice profile? | `annual_practice_access_profiles` | Twelve complete OCS and GPAD months with valid denominators | Exactly twelve months; explicitly enabled |
| How are separate OCS and CBT activities distributed within the week? | Supplementary temporal workflow | Compatible official OCS and CBT day/time evidence | Only aligned, validated months |

The [analytical design guide](docs/analytical-designs/README.md) explains the
population, grain, appropriate use and limitation of every output.

## Read every result in context

Before interpreting a table, identify:

1. the retained population and row grain;
2. the observation window and the publication vintage supplying each month;
3. which source-presence, missingness and integrity flags apply;
4. the denominator used for any rate; and
5. the claims the source data can and cannot support.

Use the [source catalogue](docs/SOURCE_CATALOGUE.md),
[grain and cardinality guide](docs/concepts/GRAIN_AND_CARDINALITY.md),
[missingness and zero guide](docs/concepts/MISSINGNESS_AND_ZERO.md) and
[interpretation limitations](docs/limitations/INTERPRETATION.md) together.

The repository deliberately does not create a composite access score, a
practice league table, a cross-source total, or a comparison built from
different observation periods presented as though they were aligned.

## Fixed dissertation reference release

The validated April 2025 to March 2026 release contains:

- 74,195 practice-month keys in the coverage-preserving table;
- 6,067 practices and 13 numerical features in the primary annual matrix;
- 3,020 practices in the CBT inbound sensitivity matrix;
- 1,456 practices in the CBT outcomes sensitivity matrix;
- 6,152 practices in the supplementary temporal table; and
- 582 practices explicitly flagged for the documented April 2025 Y60 CBT
  integrity gap.

The included evidence records 26 of 26 release SQL gates, 39 of 39 dependency
checks and 3 of 3 numerical-matrix checks passing. Run
`RUN_REFERENCE_VALIDATION.cmd` to recalculate the checksums without the large
working databases.

To rebuild the primary annual OCS-GPAD matrix from the 21 exact official CSVs,
place the files at the relative locations listed in
`reference-release/input_manifest.csv` and run `RUN_REFERENCE_BUILD.cmd`.

## Scope and responsible use

Raw NHS downloads, source archives and SQLite working databases are not stored
in the repository. Complete SQL, contracts, official-source guidance,
reference checksums, synthetic examples and validation evidence are included.

The outputs describe recorded activity and data availability. They do not, on
their own, measure access quality, unmet need, patient experience or causal
substitution between channels. Exploratory analysis, clustering and model
interpretation belong in a separate modelling project.

Before using the data, read [data availability](DATA_AVAILABILITY.md),
[official NHS data acquisition](docs/get-official-nhs-data/README.md) and
[interpretation limitations](docs/limitations/INTERPRETATION.md).
