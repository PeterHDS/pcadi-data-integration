# Within-week online consultation and telephony timing

**Question:** How are separately recorded OCS submissions and CBT calls distributed across weekday and genuinely compatible time bands?

**SQL:** `sql/build_within_week_temporal_access.sql`

**Population and grain:** Practice, reporting month, weekday and harmonised time bucket, followed by a supplementary practice-level summary.

**Join:** Aggregate each source independently to the common key, build a union temporal spine, then attach OCS and CBT without adding their counts.

**Use:** Describe within-week channel timing where official day/time evidence can be aligned defensibly.

**Main limitation:** The output does not link an online request to a call or appointment. The April 2025 Y60 CBT day/time integrity gap remains missing evidence and limits national interpretation.

**Validation:** Compatible bucket definitions, unique temporal keys, source reconciliation, no row multiplication and an explicit integrity flag for all 582 affected practices in the 6,152-practice supplementary table.
