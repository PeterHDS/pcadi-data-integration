# PCADI: Primary Care Activity Data Integration

*A reproducible SQL pipeline for integrating NHS England OCS, GPAD and CBT
data across configurable observation periods.*

[![Validation](https://github.com/PeterHDS/pcadi-data-integration/actions/workflows/validate.yml/badge.svg)](https://github.com/PeterHDS/pcadi-data-integration/actions/workflows/validate.yml)
[![Dissertation release: v1.0.0](https://img.shields.io/badge/dissertation%20release-v1.0.0-24557a.svg)](docs/releases/v1.0.0.md)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Primary language: SQL](https://img.shields.io/badge/primary%20language-SQL-blue.svg)](sql/README.md)

PCADI prepares official NHS England Online Consultation Systems (OCS), General
Practice Appointments Data (GPAD) and Cloud Based Telephony (CBT) for
practice-month analysis. It shows where each source reports, creates
question-specific joins and can produce a complete annual practice profile
when exactly twelve eligible months are available.

The user chooses the observation period. One month, twelve months, twenty-four
months and other contiguous periods use the same practice-month pipeline. The
fixed April 2025 to March 2026 dissertation release is included as a verified
case study.

PCADI is an independent academic project, not an NHS England product. OCS
submissions, GPAD appointments and CBT calls describe different recorded
activities. They remain separate throughout the pipeline.

## Start in two minutes

Install [Python 3.11 or newer](https://www.python.org/downloads/), then clone
the repository:

```powershell
git clone https://github.com/PeterHDS/pcadi-data-integration.git
cd pcadi-data-integration
python automation/pipeline_cli.py demo --months 3
```

On Windows, `RUN_DEMO.cmd` runs the same demonstration. It creates
deterministic synthetic inputs, executes the SQL and writes a validation
report under `work/demo_3_months/outputs/`. No NHS data and no clustering are
used.

## Choose a route

| Reader | First step | What it provides |
|---|---|---|
| Examiner | [Verify the dissertation release](docs/audiences/examiner-guide.md) | Locked matrices, SQL lineage, cohort flow and checksums |
| NHS or ICB analyst | [Run a chosen period](docs/audiences/analyst-guide.md) | Official-source checklist, contracts and output selection |
| Learner | [Follow the guided tutorial](docs/audiences/learner-tutorial.md) | A small runnable example with row-retention explanations |
| Technical reviewer | [Inspect the controls](docs/audiences/technical-reviewer.md) | Schemas, tests, cardinality and deterministic fingerprints |
| Maintainer | [Update or extend the pipeline](docs/audiences/maintainer-guide.md) | Release-vintage, contract and regression-test workflow |

The shorter [start guide](START_HERE.md) helps readers who are not sure which
route applies.

## What question needs answering?

| Question | Recommended table |
|---|---|
| Where does each source report or remain absent? | `multichannel_practice_month_coverage` |
| What appointment evidence accompanies OCS records? | `online_consultation_cohort_with_appointment_context` |
| What OCS evidence accompanies appointment records? | `appointment_cohort_with_online_consultation_context` |
| How do OCS and GPAD compare where both report? | `matched_online_and_scheduled_activity` |
| What evidence is present where all three sources match? | `matched_multichannel_activity` |
| Do OCS-GPAD patterns differ in the CBT-observed population? | `telephony_observed_comparative_cohort` |
| What is each eligible practice's complete annual OCS-GPAD profile? | `primary_practice_access_clustering_matrix.csv` |
| How are OCS and CBT records distributed within the week? | supplementary temporal workflow |

Each table retains a different population. The
[analytical design index](docs/analytical-designs/README.md) states the
question, grain, join key, retained records, validation evidence and
interpretation limit for every design.

## How the pipeline works

![PCADI pipeline from official releases to analytical outputs](docs/assets/pcadi-architecture.svg)

1. Record official publication pages, release vintages and observation months.
2. Reduce each source to one row per practice and reporting month.
3. validate identifiers, source totals, category reconciliation and source
   ownership.
4. Build a union practice-month spine and attach each source on practice code
   plus reporting month.
5. Derive narrower populations by explicit presence and eligibility rules.
6. Export deterministic tables, validation results and SHA-256 checksums.

The full explanation is in [How the joins work](docs/HOW_THE_JOINS_WORK.md).
The [architecture guide](docs/architecture/PIPELINE_ARCHITECTURE.md) includes a
text equivalent of the diagram.

## Use any contiguous observation period

Create a configuration:

```powershell
python automation/pipeline_cli.py make-config `
  --start 2026-03 --months 3 `
  --output configs/my_period.json
```

Generate the official-data checklist:

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

Use the [official NHS data guide](docs/get-official-nhs-data/README.md) and the
machine-readable contracts in [`contracts/sources`](contracts/sources) before
preparing data. The annual feature branch must be requested explicitly and
requires exactly twelve complete months.

## PCADI v1.0.0 dissertation reference release

The April 2025 to March 2026 dissertation reference release contains three
locked modelling matrices:

| Matrix | Practices | Numerical features | SHA-256 |
|---|---:|---:|---|
| [National annual OCS-GPAD profile](outputs/primary_practice_access_clustering_matrix.csv) | 6,067 | 14 | `C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF` |
| [CBT inbound restricted cohort](outputs/cbt_inbound_sensitivity_clustering_matrix_17_features.csv) | 3,020 | 17 | `CCC179B870BBD3EC46DD1B75868DB38156FE23A44BBC5A8FF698505FC9B63ED5` |
| [CBT outcome-complete restricted cohort](outputs/cbt_outcomes_sensitivity_clustering_matrix_21_features.csv) | 1,456 | 21 | `D3D2E70C1A718260DD332B59F835EB6316826677A1DF5CEB928ED563C0FC1021` |

The core matrix retains the official GPAD `1 day` and `2 to 7 days` booking
bands as separate features. The two CBT matrices inherit every shared value
exactly after alignment by practice code. The identifier is retained for
traceability and must be excluded from numerical modelling.

Run `RUN_REFERENCE_VALIDATION.cmd` to verify the complete reference manifest.
The [cohort figure](docs/assets/pcadi-cohort-flow.svg) shows how evidence
availability narrows the population.

## Interpretation boundaries

PCADI describes recorded activity and data availability. The outputs do not,
on their own, measure total demand, unmet need, access quality, patient
experience or causal substitution between channels. Booking interval records
the time between the recorded booking date and appointment date, not
necessarily the time since a patient first sought care.

Read the [source catalogue](docs/SOURCE_CATALOGUE.md), [missingness and zero
guide](docs/concepts/MISSINGNESS_AND_ZERO.md) and [interpretation
limitations](docs/limitations/INTERPRETATION.md) before analysis.

## Repository map

| Location | Purpose |
|---|---|
| [`sql/portable`](sql/portable) | Configurable practice-month and annual SQL |
| [`sql/core_pipeline`](sql/core_pipeline) | Ordered fixed dissertation build |
| [`automation`](automation) | Standard-library Python orchestration and checks |
| [`contracts`](contracts) | Prepared-source and output interfaces |
| [`docs`](docs) | Concepts, designs, audience routes and source acquisition |
| [`reference-release`](reference-release) | Fixed lineage and release evidence |
| [`outputs`](outputs) | Compact validated reference outputs |
| [`validation`](validation) | Machine-readable checksums and gates |
| [`tests`](tests) | Deterministic regression and documentation checks |

Raw NHS downloads and working databases are not committed. Source provenance,
SQL, schemas, synthetic fixtures and checksums remain inspectable.

## Citation and licence

Use [CITATION.cff](CITATION.cff) for the software release and cite the exact
NHS England publications recorded in the source-provenance file. The code is
released under the [MIT licence](LICENSE).
