# PCADI dissertation reference release report

## Release position

PCADI is the executable and documentary companion to the DS7010 dissertation.
The planned public release is:

**PCADI v1.0.0 — Dissertation Reference Release**

It presents the analytical contracts used in the completed dissertation and
the evidence required to reproduce, inspect and extend the SQL integration.

## Authoritative analytical contracts

| Matrix | Practices | Numerical features | Total columns | SHA-256 |
|---|---:|---:|---:|---|
| National annual OCS-GPAD | 6,067 | 14 | 15 | `C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF` |
| CBT inbound restricted cohort | 3,020 | 17 | 18 | `CCC179B870BBD3EC46DD1B75868DB38156FE23A44BBC5A8FF698505FC9B63ED5` |
| CBT outcome-complete restricted cohort | 1,456 | 21 | 22 | `D3D2E70C1A718260DD332B59F835EB6316826677A1DF5CEB928ED563C0FC1021` |

The 3,020-practice cohort is nested inside the national population. The
1,456-practice cohort is nested inside the CBT inbound population. All shared
values agree exactly after practice-code alignment. The practice identifier is
retained for traceability and excluded from modelling distances.

## Feature rationale

The national matrix contains fourteen numerical features describing recorded
OCS activity, GPAD activity, delivery mode, appointment outcome, booking-delay
bands and month-to-month variation. GPAD `1 day` and `2 to 7 days` remain
separate because they are separate published source categories and retain
different information.

Rates use the sum of month-matched registered-patient denominators. Shares use
annual component totals. Monthly variation is the mean absolute change across
eleven adjacent monthly rates. Missing months are not treated as zero.

The CBT inbound matrix adds three call-volume and variation measures. The
outcome-complete matrix adds four recorded outcome shares. A downstream
composition-aware sensitivity represents those four outcome shares with three
isometric log-ratio balances; that modelling transformation remains separate
from the raw SQL integration output.

## Analytical designs

PCADI provides purpose-led practice-month tables for OCS-led, GPAD-led,
coverage-preserving, matched two-source, matched three-source and CBT-observed
questions. It then derives the annual national and restricted-cohort matrices
and a supplementary within-week timing product.

Each design guide states its grain, join key, retained population, suitable
question, selection limitation and validation evidence. The
[analytical-design index](docs/analytical-designs/README.md) is the public
route from a research question to the appropriate table.

## Validation

- `python tests/run_tests.py`: PASS.
- `RUN_DEMO.cmd`: PASS.
- One-, three-, twelve- and twenty-four-month demonstrations: PASS.
- Portable SQL: 16 PASS and 0 FAIL for every tested period.
- Fixed source build: 21/21 imports, 12/12 SQL stages, 39 PASS and 0 FAIL.
- SQLite integrity: `ok`; foreign-key violations: 0.
- Reference output validation: 14 files checked, 0 failures.
- Matrix dimensions, schemas, uniqueness, finite values and ranges: PASS.
- Cohort nesting and exact inherited values: PASS.
- Join cardinality and row-multiplication controls: PASS.
- Publication scan: no blockers.
- Clustering run during repository preparation: no.

The machine-readable result is
[`validation/repository_release_gate.csv`](validation/repository_release_gate.csv).
The complete lineage is documented in
[`docs/audits/ANALYTICAL_CONTRACT_AND_LINEAGE.md`](docs/audits/ANALYTICAL_CONTRACT_AND_LINEAGE.md).

## Publication boundary

Raw NHS downloads, large working databases and detailed development
investigations are not included. The repository contains public analytical
contracts, SQL, small reference outputs, manifests, dictionaries, tests and
validation summaries. The complete fourteen-output archive is prepared locally
and will be attached only after the draft pull request is approved.

## Branch and review

- Branch: `repo-rebuild/correct-14-feature-and-design-guides`
- Base: `main`
- Draft pull request:
  `https://github.com/PeterHDS/pcadi-data-integration/pull/6`

## Recommendation

**READY FOR ACADEMIC REVIEW.**

The repository matches the dissertation analytical contracts and provides
independent checks of their provenance, construction and output identity.
Merge and release publication remain approval-dependent.
