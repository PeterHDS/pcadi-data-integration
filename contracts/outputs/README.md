# Output contracts

## Practice-month outputs

The key is `practice_code_standardised + reporting_month`. The
coverage-preserving table carries source-presence flags and separate OCS, GPAD
and CBT measures. Source-led and matched outputs inherit values without
recalculation. Any positive contiguous period is supported.

## National annual matrix

The key is `practice_code_standardised`. The first column is traceability
metadata. Fourteen numerical features follow in a locked order. The annual
matrix is created only when exactly twelve months are configured, annual
features are enabled and every retained practice passes source, denominator
and reconciliation rules.

The official GPAD `1 day` and `2 to 7 days` fields remain separate. A combined
field is not part of the modelling contract.

## CBT restricted-cohort matrices

The inbound matrix contains the fourteen core fields plus three CBT inbound
features. The outcome-complete matrix inherits those seventeen fields and adds
four raw outcome shares. Values shared with a parent matrix must match exactly
after alignment by practice code.

## Temporal output

OCS and CBT activity remain separate. The April 2025 Y60 integrity flag marks
practices affected by missing official CBT day/time evidence. Missing activity
is not filled or inferred.
