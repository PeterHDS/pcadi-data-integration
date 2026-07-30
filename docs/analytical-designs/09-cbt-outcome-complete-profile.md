# CBT outcome-complete restricted-cohort access-profile matrix

**Question:** Within practices with complete recorded CBT outcome evidence,
what information is introduced by answered, missed, IVR and callback-request
balance?

**Output:** `cbt_outcomes_sensitivity_clustering_matrix_21_features.csv`

**Population and grain:** One row for each of 1,456 practices, nested inside
the 3,020-practice inbound cohort.

**Features:** Seventeen inherited fields plus four raw outcome shares.

**Use:** Raw outcome representation sensitivity. In downstream modelling, the
preferred interpretation replaces the four near-compositional shares with
three isometric log-ratio balances, producing twenty features on the same
1,456 practices.

**Main limitation:** Recorded outcomes do not directly measure workload,
patient experience, access quality or staff performance.

**Validation:** All seventeen inherited values match the parent matrix exactly.
The raw file has twenty-two total columns and SHA-256
`D3D2E70C1A718260DD332B59F835EB6316826677A1DF5CEB928ED563C0FC1021`.
