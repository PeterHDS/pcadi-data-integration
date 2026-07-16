# Grain and join cardinality

The standard integration grain is one row for each:

```text
practice_code_standardised + reporting_month
```

Each source is aggregated independently to this grain and tested for a unique
key before joining. The join uses both practice and month. The integrated row
count must equal the union-spine key count, which gives a row-multiplication
factor of 1.0.

The practice-month grain works for any configured number of months. Changing
the window changes which month keys are eligible; it does not change the join
key.

Annual profiles use one row per practice and require exactly twelve complete
months. Temporal analysis uses practice, month, weekday and a harmonised time
bucket only when the official definitions can be aligned without inventing
precision.
