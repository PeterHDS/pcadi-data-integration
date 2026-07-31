# CBT inbound restricted-cohort access-profile matrix

**Question:** Within practices with complete valid CBT inbound evidence, how does adding inbound call activity and variation alter the established OCS-GPAD feature space?

**Output:** `cbt_inbound_sensitivity_clustering_matrix_17_features.csv`

**Population and grain:** One row for each of 3,020 practices, nested inside the 6,067-practice annual population.

**Features:** The fourteen national OCS-GPAD values plus CBT inbound calls per 1,000 patient-months, mean absolute monthly call-rate change and call-rate range.

**Use:** Controlled matched-cohort sensitivity.

**Main selection consideration:** CBT evidence availability selects this restricted cohort. National coverage, workload and access quality require their own evidence assessments.

**Validation:** All fourteen inherited values match the national matrix exactly by practice code. The file has eighteen total columns and SHA-256 `CCC179B870BBD3EC46DD1B75868DB38156FE23A44BBC5A8FF698505FC9B63ED5`.
