# Pipeline architecture

```text
Official NHS England publication pages
        |
        v
download checklist + retained metadata
        |
        v
source_provenance.csv -- exactly one selected owner per component-month
        |
        v
dataset-specific preparation and canonical source contracts
        |
        v
unique OCS, GPAD and CBT practice-month tables
        |
        v
coverage-preserving UNION spine
        |
        +--> source-led coverage views
        +--> matched two-source cohort
        +--> matched three-source cohort
        +--> telephony-observed sensitivity cohort
        +--> optional twelve-month annual profiles, when requested and eligible
        +--> separate temporal design, when day/time schemas permit
        |
        v
validation evidence + deterministic exports + checksums
```

The orchestration layer cannot redefine a measure. SQL remains authoritative.
The canonical contract is the boundary between changing official file layouts
and stable analytical tables. When a source schema changes, its adapter or
contract must be versioned rather than weakening validation.

The practice-month path is period-agnostic. The configured start and end months
may describe any positive number of consecutive months. The annual branch is
deliberately stricter because it represents one complete twelve-month record
per practice rather than a general period summary.
