# Validation method

Every mandatory verdict must retain:

- the test performed;
- SQL or command used;
- expected result;
- observed result;
- pass/fail status;
- interpretation;
- affected output if failed.

Mandatory gates cover source identity, schema, ownership, date range, identifier
validity, grain, duplicates, source-family reconciliation, join cardinality,
missingness, annual eligibility, numerical validity and deterministic checksums.

The runner exits unsuccessfully when a mandatory SQL gate fails. A successful
process exit is necessary but not sufficient for substantive interpretation;
the selected analytical design and limitations must also be appropriate.
