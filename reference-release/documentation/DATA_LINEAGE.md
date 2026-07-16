# Data lineage

```text
21 frozen raw monthly/component CSV files
    |-- OCS evidence series (2 regional files)
    |-- GPAD appointment crosstabs (14 files)
    `-- GPAD practice mappings (5 files; reference only)
                         |
                         v
Text-preserving raw staging + manifest hash/schema/count checks
                         |
                         v
Standardised OCS / GPAD / mapping tables
                         |
              +----------+-----------+
              |                      |
              v                      v
  OCS practice-month       GPAD practice-month
       activity                 activity
              |                      |
              `----------+-----------'
                         |
          registered-list practice-month
                 denominator
                         |
                         v
              Join-cardinality audit
                         |
                         v
       Integrated practice-month panel
                         |
                         v
        Source-specific annual features
                         |
                         v
  12-month eligibility + explicit exclusions
                         |
                         v
 Primary practice access clustering matrix
      (identifier + 13 separate features)
                         |
                         v
  36 validations + ordering + canonical fingerprint
                         |
                         v
 Deterministic CSV export + fresh-reference equivalence
```

## Join boundary

The only cross-source integration key is:

```text
practice_code_standardised + reporting_month
```

Both sources and the denominator are independently unique at this key before joining. The annual table is not created by joining annual source detail; it is derived from the validated monthly panel and complete source-specific series.

## Feature lineage boundary

OCS count and composition features use only OCS numerators. GPAD count and composition features use only GPAD numerators. Both rate families may use the same validated registered-list exposure. No feature adds OCS activity to GPAD activity.

