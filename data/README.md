# Local data area

Official NHS downloads and working data stay on the user's computer and are
excluded from Git.

Recommended layout:

```text
data/
|-- downloads/
|   |-- ocs/
|   |-- gpad/
|   |-- cbt/
|   `-- metadata/
`-- prepared/
    |-- online_consultation_practice_month.csv
    |-- appointment_activity_practice_month.csv
    |-- cloud_telephony_practice_month.csv
    `-- source_provenance.csv
```

The four prepared files must match the contracts in `contracts/sources/`.
Every official input must remain traceable to its publication page, direct
resource URL, observation month, release vintage and SHA-256 checksum.
