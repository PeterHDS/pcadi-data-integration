# PCADI: Primary Care Activity Data Integration

*Build auditable practice-month datasets from NHS England
online-consultation, appointment, telephony and registered-patient data.*

[![Validation](https://github.com/PeterHDS/pcadi-data-integration/actions/workflows/validate.yml/badge.svg)](https://github.com/PeterHDS/pcadi-data-integration/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Primary language: SQL](https://img.shields.io/badge/primary%20language-SQL-blue.svg)](sql/README.md)

PCADI is an open SQL and Python workflow for preparing NHS England
general-practice activity data for reproducible analysis. It standardises
source files at practice-month level, preserves coverage and missingness,
creates question-specific joins, and can generate annual practice-level
matrices when twelve complete eligible months are available.

The repository includes a verified reference application covering April 2025
to March 2026. The pipeline can be configured for other contiguous periods when
the required official source files are available.

> PCADI is an independent academic project. It is not an NHS England product
> and must not be interpreted as an official NHS performance system.

![PCADI turns official publication files into validated practice-month tables and question-specific analytical outputs](docs/assets/pcadi-architecture.svg)

## Contents

- [Start here](#start-here)
- [What PCADI produces](#what-pcadi-produces)
- [Choose an analytical design](#choose-an-analytical-design)
- [Build a selected period](#build-a-selected-period)
- [Inspect the included reference application](#inspect-the-included-reference-application)
- [Validate an output](#validate-an-output)
- [Interpretation boundaries](#interpretation-boundaries)
- [Guides for particular readers](#guides-for-particular-readers)
- [Repository structure](#repository-structure)
- [Citation and reuse](#citation-and-reuse)

## Start here

| I need to... | Start here |
|---|---|
| Understand PCADI in two minutes | [Project overview](docs/architecture/PIPELINE_ARCHITECTURE.md) |
| See the pipeline run without NHS data | [Synthetic demonstration](examples/synthetic/README.md) |
| Build outputs for a selected period | [Period configuration guide](docs/PERIOD_CONFIGURATION.md) |
| Understand why several joins exist | [Analytical design guide](docs/analytical-designs/README.md) |
| Inspect the April 2025 to March 2026 outputs | [Verified reference application](docs/reference-applications/apr2025-mar2026.md) |
| Verify schemas, counts and file integrity | [Validation guide](docs/VALIDATION_METHOD.md) |
| Review the complete technical controls | [Technical reviewer guide](docs/audiences/technical-reviewer.md) |

Install [Python 3.11 or newer](https://www.python.org/downloads/), then run:

```powershell
git clone https://github.com/PeterHDS/pcadi-data-integration.git
cd pcadi-data-integration
python automation/pipeline_cli.py demo --months 3
```

On Windows, `RUN_DEMO.cmd` runs the same demonstration. It creates
deterministic synthetic inputs, executes the SQL and writes validation evidence
under `work/demo_3_months/outputs/`. It does not use NHS data or run
clustering.

## What PCADI produces

PCADI first creates source-specific tables with one row per practice and
reporting month. It then builds:

- coverage views that preserve where each source reports or is absent;
- question-specific matched views with explicit retained populations;
- a union practice-month spine for OCS, GPAD and CBT coverage;
- annual practice-level matrices when exactly twelve eligible months are
  complete; and
- validation results, source-provenance records and deterministic file
  fingerprints.

OCS submissions, GPAD appointments and CBT calls remain separate measures.
Registered-patient counts are used as monthly practice-size denominators where
the documented rate contract requires them. ODS practice codes provide the
identity key.

## Choose an analytical design

Different joins answer different questions and intentionally retain different
populations. A smaller result is not automatically a failed join.

| Analytical question | Retained population | Grain | Sources | Output | Principal limitation |
|---|---|---|---|---|---|
| What appointment context is available for OCS records? | OCS-reported practice-months | Practice-month | OCS, GPAD | `online_consultation_led_appointment_alignment` | GPAD may be absent |
| What OCS context is available for appointment records? | GPAD-reported practice-months | Practice-month | GPAD, OCS | `appointment_led_online_consultation_alignment` | OCS may be absent |
| Where do all activity sources report or remain absent? | Union of reported source keys | Practice-month | OCS, GPAD, CBT | `multichannel_practice_month_coverage` | Coverage is not activity |
| How do OCS and GPAD compare where both report? | Matched OCS-GPAD keys | Practice-month | OCS, GPAD | `matched_online_and_scheduled_activity` | Excludes unmatched reporting |
| What evidence is available where all three sources match? | Matched keys with valid CBT | Practice-month | OCS, GPAD, CBT | `matched_multichannel_activity` | CBT availability narrows coverage |
| How do OCS-GPAD patterns look in the CBT-observed population? | CBT-observed matched keys | Practice-month | OCS, GPAD, CBT | `telephony_observed_comparative_cohort` | Restricted population |
| What is each eligible practice's annual OCS-GPAD profile? | Practices with 12 eligible months | Practice | OCS, GPAD, registered patients | `primary_practice_access_clustering_matrix.csv` | Annual eligibility is strict |
| What CBT inbound evidence can extend the annual profile? | Nested CBT inbound cohort | Practice | OCS, GPAD, CBT | `cbt_inbound_sensitivity_clustering_matrix_17_features.csv` | Restricted evidence cohort |
| What complete CBT outcomes can extend the annual profile? | Nested CBT outcome-complete cohort | Practice | OCS, GPAD, CBT | `cbt_outcomes_sensitivity_clustering_matrix_21_features.csv` | Smallest evidence cohort |
| How are OCS and CBT records distributed within the week? | Eligible temporal records | Practice and timing bucket | OCS, CBT | Supplementary timing output | Timing definitions limit alignment |

The [analytical design index](docs/analytical-designs/README.md) gives the
complete question, join key, retained population and interpretation limit for
each design. Stable machine-facing filenames are retained for reproducibility.

## Build a selected period

PCADI can construct practice-month outputs for any positive number of
consecutive months, provided the required official monthly source files are
obtained and prepared.

Create a configuration:

```powershell
python automation/pipeline_cli.py make-config `
  --start 2026-03 --months 3 `
  --output configs/my_period.json
```

Generate a source checklist:

```powershell
python automation/pipeline_cli.py data-checklist `
  --config configs/my_period.json `
  --output work/my_period_data_checklist.csv
```

After preparing the four contract-controlled inputs:

```powershell
python automation/pipeline_cli.py run `
  --config configs/my_period.json `
  --input-dir data/prepared `
  --output-dir work/my_period_output `
  --database work/my_period.sqlite `
  --overwrite
```

Use the [official NHS data guide](docs/get-official-nhs-data/README.md) and
[`contracts/sources`](contracts/sources) before preparing data. The repository
does not mirror every NHS publication. One-, three- and twenty-four-month
demonstrations are synthetic. A 24-month official run needs 24 compatible
months of source inputs. Annual matrices are produced only by the explicit
twelve-month branch.

## Inspect the included reference application

The verified April 2025 to March 2026 application includes three annual
analytical contracts:

| Matrix | Practices | Numerical features | Role |
|---|---:|---:|---|
| [National annual OCS-GPAD matrix](outputs/primary_practice_access_clustering_matrix.csv) | 6,067 | 14 | National annual reference matrix |
| [CBT inbound restricted cohort](outputs/cbt_inbound_sensitivity_clustering_matrix_17_features.csv) | 3,020 | 17 | Nested telephony sensitivity matrix |
| [CBT outcome-complete restricted cohort](outputs/cbt_outcomes_sensitivity_clustering_matrix_21_features.csv) | 1,456 | 21 | Nested outcome-complete sensitivity matrix |

The national matrix retains the published GPAD `1 day` and `2 to 7 days`
booking bands as separate features. The two CBT matrices inherit every shared
parent value exactly after alignment by practice code. The practice identifier
is retained for traceability and must be excluded from numerical modelling.

The included outputs are locked by schema, dimensions and
[SHA-256 checksums](validation/authoritative_output_manifest.csv). The
[reference application](docs/reference-applications/apr2025-mar2026.md)
documents sources, cohort nesting, validation and analytical boundaries.

![The 6,067-practice annual matrix contains two nested CBT evidence-availability cohorts](docs/assets/pcadi-cohort-flow.svg)

## Validate an output

Run:

```powershell
python automation/pipeline_cli.py validate-reference `
  --restore-missing `
  --output work/reference_validation.csv
```

On Windows, `RUN_REFERENCE_VALIDATION.cmd` performs the same check. Missing
release-only CSVs are restored from the period-labelled GitHub release only
after the archive's filename, byte size and checksum pass. Every restored CSV
is then checked against the output register.

For a new period, use `pipeline_validation_results.csv` from that run. Do not
use an output when a mandatory validation row fails.

## Interpretation boundaries

PCADI describes recorded activity and data availability:

- activity is not total demand;
- appointments are not total workload;
- calls are not patient journeys;
- missing is not zero;
- public practice data are not patient-level evidence;
- profiles are not performance ranks;
- correlation is not causation; and
- the outputs do not establish safety, equity, value or patient outcomes.

Booking interval records the time between the recorded booking date and
appointment date. It does not necessarily measure the time since a patient
first sought care.

Read the [source catalogue](docs/SOURCE_CATALOGUE.md), [missingness and zero
guide](docs/concepts/MISSINGNESS_AND_ZERO.md) and [interpretation
limitations](docs/limitations/INTERPRETATION.md) before analysis.

## Guides for particular readers

| Reader | Guide |
|---|---|
| Examiner or academic reviewer | [Research and reference-output inspection](docs/audiences/examiner-guide.md) |
| NHS or ICB analyst | [Build and select a period-specific output](docs/audiences/analyst-guide.md) |
| Learner | [Follow the guided synthetic tutorial](docs/audiences/learner-tutorial.md) |
| Technical reviewer | [Inspect contracts, tests and integrity gates](docs/audiences/technical-reviewer.md) |
| Maintainer | [Update source and output contracts safely](docs/audiences/maintainer-guide.md) |

The [start guide](START_HERE.md) offers the same routes by purpose rather than
role.

## Repository structure

| Location | Purpose |
|---|---|
| [`sql/portable`](sql/portable) | Configurable practice-month and annual SQL |
| [`sql/core_pipeline`](sql/core_pipeline) | Ordered SQL for the verified reference application |
| [`automation`](automation) | Standard-library Python orchestration and checks |
| [`contracts`](contracts) | Prepared-source and output interfaces |
| [`docs`](docs) | Concepts, analytical designs, source acquisition and reader guides |
| [`reference-release`](reference-release) | Frozen reference lineage and validation evidence |
| [`outputs`](outputs) | Compact verified reference outputs |
| [`validation`](validation) | Machine-readable checksums and gates |
| [`tests`](tests) | Deterministic regression and documentation checks |

Raw NHS downloads and working databases are not committed.

## Citation and reuse

Use [CITATION.cff](CITATION.cff) to cite PCADI. Also cite:

1. the exact NHS England publications used for the selected observation period;
2. any downstream analytical method; and
3. the associated study when its findings are reused.

The code is released under the [MIT licence](LICENSE).
