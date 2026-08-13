# Grain and join cardinality

The standard integration grain is one row for each:

```text
practice_code_standardised + reporting_month
```

Each source is aggregated independently to this grain and tested for a unique key before joining. Every practice-month join uses both practice and month. Output cardinality is evaluated against the distinct keys that the analytical design intends to retain.

| Design | Intended retained-key population | Cardinality condition |
|---|---|---|
| Coverage union spine | Distinct union of all selected source keys | Output keys equal the union keys |
| Source-led comparison | Keys present in the named anchor source | Output keys equal the anchor-source keys |
| Matched comparison | Keys satisfying the documented source-presence conditions | Output keys equal the eligible intersection |
| Verified national monthly panel | Keys with matched OCS, GPAD and valid registered-patient evidence | Output keys equal the validated matched population |
| Annual profile | Practices satisfying the documented month-completeness and feature-validity rules | One output row per eligible practice |

For each design, a row-multiplication factor of 1.0 means that every intended retained key appears exactly once. It does not mean that every analytical output has the same row count as the coverage union spine.

The practice-month grain works for any configured number of months. Changing the window changes which month keys are eligible; it does not change the join key.

Annual profiles use one row per practice and require exactly twelve complete months. Temporal analysis uses practice, month, weekday and a harmonised time bucket only when the official definitions can be aligned without inventing precision.
