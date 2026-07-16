# Missingness and zero

A value of zero is retained only when the source or a validated aggregation
reports zero activity. The following are not equivalent to zero:

- no practice-month row;
- a blank or SQL null field;
- non-participation;
- supplier non-submission;
- unknown supplier;
- invalid or unassigned CBT account mapping;
- suppressed value;
- corrupted source component;
- a structurally unavailable measure.

The union-spine design exposes source-presence flags so an analyst can separate
coverage from observed activity. Imputation is outside the integration stage.
