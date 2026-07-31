# Matched OCS, GPAD and valid CBT activity

**Question:** What does the multichannel evidence look like where all three sources are present and CBT mapping is valid?

**Output:** `matched_multichannel_activity`

**Population and grain:** One row per practice-month with OCS, GPAD and validly mapped CBT evidence.

**Join:** Filter the coverage spine after each source is unique. Require all three presence flags and valid CBT mapping.

**Use:** Three-source descriptive comparison and telephony evidence auditing.

**Main limitation:** Supplier participation, account mapping and integrity conditions narrow the population. Matching does not link individual patients, requests, calls and appointments.

**Validation:** CBT invalid mappings remain outside the output, keys remain unique and each source total is reconciled only to itself.
