# How the joins work

PCADI first makes each source unique at `practice_code_standardised + reporting_month`. It then joins prepared sources on both fields. This order prevents category rows from multiplying activity when source files contain several breakdown families.

## The common key

`practice_code_standardised` identifies the GP practice. `reporting_month` identifies the observation month, stored as `YYYY-MM`. A practice code alone is not a safe join key because every practice can have many months.

Before joining, the pipeline checks:

- one row per source and practice-month;
- valid six-character practice codes;
- dates inside the configured period;
- source totals reconciled to their own category families;
- positive month-matched registered-patient denominators where a rate is used;
- one selected publication owner for every required component-month.

## The union coverage spine

The broadest integrated table starts with the distinct union of OCS, GPAD and CBT practice-month keys. Each prepared source is then left-joined to the spine. Presence flags show whether a source row existed.

```sql
SELECT practice_code_standardised, reporting_month FROM online_consultation_practice_month
UNION
SELECT practice_code_standardised, reporting_month FROM appointment_activity_practice_month
UNION
SELECT practice_code_standardised, reporting_month FROM cloud_telephony_practice_month;
```

This preserves available evidence without turning an absent source row into a zero. Relative to the distinct union keys, the multiplication factor must remain 1.0 because every source is unique on the join key before attachment.

## Source-led tables

An OCS-led table retains every OCS practice-month, then attaches GPAD and CBT where the same key exists. A GPAD-led table does the reverse. These designs are useful when one source defines the population and the other sources provide context.

## Matched tables

In the portable logical design, matched tables are filtered views of the coverage spine. They do not recalculate activity:

```sql
WHERE has_online_consultation = 1
  AND has_appointment_activity = 1
```

The three-source table additionally requires valid CBT evidence. The CBT-observed comparison uses the same OCS and GPAD values and changes only the eligible population.

## Verified reference implementation

The April 2025 to March 2026 national annual matrix has a separate physical lineage. Validated OCS, GPAD and registered-patient tables are inner-joined at practice-month grain to create the matched monthly panel. Twelve-month eligibility and annual feature construction then operate on that panel. The coverage union spine is valuable coverage evidence but is not an upstream table in this annual branch.

The restricted CBT annual matrices inherit the national OCS-GPAD features and attach separately validated prepared CBT evidence. The 21-file raw-source reconstruction covers the national OCS-GPAD branch only; it does not claim to rebuild raw CBT source archives.

## Annual profiles

The annual branch runs only when exactly twelve months are configured and annual features are enabled. Each eligible practice needs twelve OCS months, twelve GPAD months and twelve positive month-matched denominators.

Counts are summed across observed months. Rates divide the annual activity total by the sum of the twelve registered-patient denominators. Shares divide annual category counts by their annual source total. The two adjacent-month variation features average the absolute difference across the eleven monthly rate transitions.

Missing months preserve their source-specific status, distinct from observed zero activity. OCS and GPAD counts remain separate.

## Restricted CBT annual matrices

The 3,020-practice inbound matrix is a subset of the 6,067-practice national matrix. It inherits the fourteen OCS-GPAD values exactly and adds three CBT inbound measures.

The 1,456-practice outcome-complete matrix is a subset of the inbound matrix. It inherits all seventeen parent values exactly and adds four raw CBT outcome shares. Downstream modelling may replace those four near-compositional shares with three isometric log-ratio balances, but that transformation is separate from the SQL integration output.

## Temporal alignment

The temporal workflow has a different grain: `practice × month × weekday × harmonised time bucket`. OCS and CBT measures remain separate. Time buckets are harmonised only by aggregating to intervals that both official definitions support.

The documented April 2025 Y60 CBT day/time integrity gap remains missing evidence with an explicit integrity flag. Its source status is preserved without zero-filling or inference.

## Validation after every join

For each table, confirm:

1. the expected grain and unique key;
2. the retained population rule;
3. rows equal the distinct keys required by the retained-population rule;
4. the row-multiplication factor is 1.0 relative to that intended key set;
5. source totals reconcile before and after attachment;
6. absence and observed zero remain distinguishable;
7. the output period matches the configuration.

See the [analytical design index](analytical-designs/README.md) to choose the population that matches a research question.
