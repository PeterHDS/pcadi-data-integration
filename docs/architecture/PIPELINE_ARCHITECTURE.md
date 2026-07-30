# Pipeline architecture

![PCADI pipeline architecture](../assets/pcadi-architecture.svg)

## Text equivalent

Official NHS England releases are recorded in a source-provenance manifest and
adapted to stable prepared-source contracts. OCS, GPAD and CBT are each reduced
to one row per practice-month and validated before integration.

The pipeline builds a union of all observed practice-month keys. It attaches
each source using practice code plus reporting month. This coverage-preserving
table supplies source-led views, matched populations and the optional annual
branch.

The annual branch requires exactly twelve complete eligible months. It creates
the fourteen-feature national OCS-GPAD matrix, then nests the seventeen-feature
CBT inbound population and the twenty-one-feature raw CBT outcome population.
Downstream modelling and interpretation remain outside source integration.

## Stable boundary

The prepared-source contracts separate changing official file layouts from
stable analytical SQL. When an NHS publication changes schema, its adapter and
provenance record must be updated. Join logic and output contracts must not be
weakened to accommodate an unreviewed source change.

## Period behaviour

Practice-month integration accepts any positive number of consecutive months.
One, three and twenty-four-month demonstrations do not create an annual matrix.
The annual output appears only when twelve months are configured and the
annual feature option is enabled.

## Responsibility by layer

| Layer | Responsibility |
|---|---|
| Official-source acquisition | publication URL, release vintage, file identity and licence |
| Prepared-source contract | exact header, type, grain and source-specific meaning |
| SQL | aggregation, joining, eligibility, features and validation queries |
| Python orchestration | configuration, CSV import/export, execution order and checksums |
| Output manifest | dimensions, deterministic identity and publication status |

Read [How the joins work](../HOW_THE_JOINS_WORK.md) for cardinality and annual
calculation details.
