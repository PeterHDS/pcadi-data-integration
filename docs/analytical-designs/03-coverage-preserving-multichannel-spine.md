# Coverage-preserving OCS, GPAD and CBT practice-month spine

**Question:** Where does each source report, and where is evidence absent,
across the selected period?

**Output:** `multichannel_practice_month_coverage`

**Population and grain:** The union of all observed OCS, GPAD and CBT
practice-month keys.

**Join:** Build one unique union spine, then left-join each prepared source on
practice code plus reporting month. Explicit presence, mapping and integrity
flags travel with the measures.

**Use:** Coverage assessment, provenance, missingness, population flow and
construction of narrower cohorts.

**Main limitation:** OCS submissions, GPAD appointments and CBT calls represent
different processes and cannot be added as total demand.

**Reference evidence:** The fixed release has 74,195 practice-month rows. The
upstream annual OCS checkpoint contains 6,210 unique practices; a
practice-month row count and a unique-practice count answer different
questions.

**Validation:** The spine equals the distinct union of source keys, has no
duplicate keys and retains missing source rows as absent rather than zero.
