# PCADI v2 source of truth

This register was established before the repository rebuild. It separates the
validated analytical outputs from older public files that still use a combined
GPAD booking-delay feature.

## Authoritative annual contracts

| Output | Practices | Identifier | Numerical features | Total columns | SHA-256 |
|---|---:|---:|---:|---:|---|
| National annual OCS-GPAD matrix | 6,067 | 1 | 14 | 15 | `c50b14aa191c54c29201dc9909e138395c1a2aea7f596e8cf6b02f43a6dd7ebf` |
| CBT inbound restricted cohort | 3,020 | 1 | 17 | 18 | `ccc179b870bbd3ec46dd1b75868db38156fe23a44bbc5a8ff698505fc9b63ed5` |
| CBT outcome-complete restricted cohort | 1,456 | 1 | 21 | 22 | `d3d2e70c1a718260dd332b59f835eb6316826677a1df5ceb928ed563c0fc1021` |

The national matrix contains separate `gpad_1_day_share` and
`gpad_2_to_7_days_share` fields. The two fields are inherited without value
changes by the 3,020-practice and 1,456-practice matrices.

## Evidence checks completed before editing

- The three byte-level SHA-256 values match the controlled correction outputs.
- The matrices contain 6,067, 3,020 and 1,456 unique nonblank practice codes.
- All numerical values are present, finite and non-negative.
- Every share lies between zero and one.
- The 3,020-practice cohort is nested in the national cohort.
- The 1,456-practice cohort is nested in the 3,020-practice cohort.
- All 14 shared values match exactly between the national and inbound matrices.
- All 17 shared values match exactly between the inbound and outcome matrices.

## Corrected SQL authority

The pre-rebuild controlled SQL had SHA-256:

`fb9ce9b5136480f64209adde7dfc773228bb924d2a0566307da125f6519c57a9`

The reviewed logic is now incorporated into
[`sql/core_pipeline`](../../sql/core_pipeline) and
[`sql/portable`](../../sql/portable). The public SQL preserves the same locked
feature meanings while adding direct schema and inheritance gates.

## Downstream ILR evidence

The SQL output remains the raw 21-feature CBT outcome matrix. A completed
downstream notebook represents the four near-compositional outcome shares with
three isometric log-ratio balances, producing a 20-feature modelling
specification on the same 1,456 practices.

The ILR matrix is scaled modelling evidence, not a raw SQL integration output.
It is therefore documented as a downstream sensitivity and is not substituted
for the raw 21-feature reference CSV.

| Evidence | SHA-256 |
|---|---|
| ILR notebook | `28b987989989f25f86946a711bd9f93d16236339db53470e0b8700b1609c8284` |
| Scaled 20-feature ILR matrix | `91f798bf93335506eb342b4de7db46fac85be429370f17e7f797de9b09a15bdf` |
| ILR run manifest | `f1fa5317e748d22bb5a0979a0cf109ca890f8d70073053d34d891ceca59a35df` |

## Publication boundary

The three authoritative integration matrices are suitable public reference
outputs. The large modelling workspace, resampling checkpoints and full
notebook output tree remain internal modelling evidence. Public documentation
may report their registered conclusions and hashes without treating those
files as SQL pipeline outputs.

The machine-readable register is
[`validation/pcadi_v2_authoritative_source_register.csv`](../../validation/pcadi_v2_authoritative_source_register.csv).
