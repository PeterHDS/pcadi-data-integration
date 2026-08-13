# Data lineage

## National annual OCS-GPAD raw-source build

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
      (identifier + 14 separate features)
                         |
                         v
  39 validations + ordering + canonical fingerprint
                         |
                         v
 Deterministic CSV export + fresh-reference equivalence
```

This physical lineage reconstructs the national 14-feature OCS-GPAD matrix. It is separate from the portable coverage-union design and does not use the union spine as an upstream annual table.

## Restricted CBT evidence lineage

```text
broader selected-release CBT register
    |
    v
validated prepared CBT practice-month evidence
    |
    +--> valid complete inbound evidence
    |         `--> attach to national parent values -> 17-feature restricted matrix
    |
    `--> valid complete supported outcome evidence
              `--> attach to inbound parent values -> 21-feature restricted matrix
```

The prepared CBT layer preserves publication ownership, mapping and integrity evidence, including the two excluded source members. The national 21-file manifest does not claim a raw CBT rebuild. The restricted matrices are validated by cohort nesting and exact inheritance of their OCS-GPAD parent features.

## Join boundary

The only cross-source integration key is:

```text
practice_code_standardised + reporting_month
```

Both sources and the denominator are independently unique at this key before joining. The annual table is not created by joining annual source detail; it is derived from the validated monthly panel and complete source-specific series.

## Feature lineage boundary

OCS count and composition features use only OCS numerators. GPAD count and composition features use only GPAD numerators. Both rate families may use the same validated registered-list exposure. No feature adds OCS activity to GPAD activity.
