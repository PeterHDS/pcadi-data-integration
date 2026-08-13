# Analytical contract and lineage

This document identifies the authoritative reference matrices and the dependency path that produces them.

## Authoritative matrices

| Output | Practices | Numerical features | Total columns | SHA-256 |
|---|---:|---:|---:|---|
| National annual OCS-GPAD matrix | 6,067 | 14 | 15 | `C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF` |
| CBT inbound restricted cohort | 3,020 | 17 | 18 | `CCC179B870BBD3EC46DD1B75868DB38156FE23A44BBC5A8FF698505FC9B63ED5` |
| CBT outcome-complete restricted cohort | 1,456 | 21 | 22 | `D3D2E70C1A718260DD332B59F835EB6316826677A1DF5CEB928ED563C0FC1021` |

The machine-readable output register is [`validation/authoritative_output_manifest.csv`](../../validation/authoritative_output_manifest.csv). The public source and SQL authority register is [`validation/authoritative_source_register.csv`](../../validation/authoritative_source_register.csv).

## Portable integration design

```text
official NHS England publication resources
    |
    v
selected publication-vintage ownership
    |
    v
source-specific standardisation and reconciliation
    |
    v
one OCS, GPAD or CBT row per practice and reporting month
    |
    v
coverage-preserving union practice-month spine
    |
    `--> purpose-led practice-month analytical tables
```

The portable design uses the union spine as the coverage and provenance surface from which source-led and matched practice-month populations can be selected. Its row count is governed by the distinct union of prepared source keys.

## Verified reference lineage

```text
selected OCS and GPAD raw-source evidence
    |
    v
validated OCS and GPAD practice-month tables
    |
    +--> month-matched registered-patient denominator
    |
    v
matched OCS-GPAD-denominator practice-month panel
    |
    v
twelve-month eligibility and annual aggregation
    |
    v
14-feature national matrix
    |
    +--> attach validated prepared CBT inbound evidence
    |         `--> 17-feature CBT inbound restricted cohort
    |                    `--> exact 14-field inheritance gate
    |
    `--> attach validated prepared CBT outcome evidence
              `--> 21-feature CBT outcome-complete restricted cohort
                         `--> exact 17-field inheritance gate
```

The coverage union spine is not the physical parent of the selected national annual matrix in the verified April 2025 to March 2026 implementation. Both structures use the same grain and source-governance principles, but the national matrix is constructed separately from the validated OCS, GPAD and registered-patient source tables. CBT enters the restricted annual contracts through a separately validated prepared-evidence layer; the 21-file national raw-source build does not reconstruct CBT from raw archives.

## Annual calculations

- Counts are summed across twelve observed eligible months.
- Rates divide annual activity totals by the sum of matched monthly registered populations.
- Shares divide annual component totals by the relevant annual source total.
- Monthly variation is the mean absolute change across eleven adjacent monthly rates.
- Missing months are not filled with zero.
- OCS, GPAD and CBT activity totals are never added together.

The GPAD booking-delay contract retains `same day`, `1 day`, `2 to 7 days`, `8 to 14 days` and `over 14 days` as mutually exclusive analytical bands.

## Cohort controls

- Each matrix has one nonblank unique practice code per row.
- The 3,020-practice CBT inbound cohort is nested inside the 6,067-practice national cohort.
- The 1,456-practice CBT outcome cohort is nested inside the inbound cohort.
- Every inherited value is compared across the complete aligned matrices.
- All modelling values are numeric, finite and within documented ranges.

## Downstream composition-aware sensitivity

The raw SQL output retains four CBT outcome shares. The completed modelling sensitivity uses three isometric log-ratio balances on the same 1,456 practices. That transformation is a downstream modelling decision and is not substituted for the raw 21-feature integration matrix.

## Review evidence

- [Feature dictionary](../../reference-release/documentation/FEATURE_DICTIONARY.md)
- [Join-design validation](../../validation/join_design_gate.csv)
- [Matrix numerical validation](../../validation/matrix_numeric_validation.csv)
- [Reference output checksums](../../validation/output_register_and_checksums.csv)
- [Release validation gate](../../validation/repository_release_gate.csv)
