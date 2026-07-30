# National annual OCS-GPAD access-activity profile matrix

**Question:** What complete twelve-month OCS and GPAD configuration is recorded
for each eligible English general practice?

**Output:** `primary_practice_access_clustering_matrix.csv`

**Population and grain:** One row for each of 6,067 practices with twelve
eligible OCS months, twelve eligible GPAD months and twelve positive
month-matched registered-patient denominators.

**Annual calculation:**

- counts are summed from observed months;
- rates divide annual totals by summed monthly registered populations;
- shares use annual component totals rather than averaged monthly shares;
- variation is the mean absolute change across eleven adjacent monthly rates;
- missing months are not filled with zero.

**Features:** Fourteen numerical fields. The official GPAD `1 day` and `2 to 7
days` bands remain separate.

**Use:** Primary national clustering input and complete annual practice
profile.

**Main limitation:** Recorded activity is not total demand. Booking delay is
not access quality, and clusters are not practice rankings.

**Validation:** 6,067 unique identifiers, fifteen total columns, no missing or
non-finite values, valid ranges and locked SHA-256
`C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF`.
