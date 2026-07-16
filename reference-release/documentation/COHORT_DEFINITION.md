# Cohort definition

The analytical cohort is defined by observable data-quality and mathematical eligibility rules. Published counts are validation evidence, not selection instructions.

## Sequential rules

1. **Source availability:** a practice must have valid standardised source evidence within April 2025-March 2026. Mapping-file presence is reference evidence only.
2. **Twelve-month completeness:** the practice must have exactly 12 distinct OCS months and 12 distinct GPAD months in the fixed window.
3. **Denominator validity:** each of the 12 months must have one positive registered-patient value; repeated supplier values must agree.
4. **Grain and category reconciliation:** practice-month keys must be unique. OCS components and the GPAD status, mode and booking breakdown families must reconcile within documented definitions.
5. **Positive annual OCS total:** a practice with zero annual OCS submissions cannot have defined OCS clinical or administrative shares and is excluded without imputation.
6. **Final matrix completeness:** every selected feature must be present, numeric, finite and within its defined range; rate and mean-absolute-change features must be non-negative.

## Observed lineage

| Lineage point | Observed practices | Meaning |
|---|---:|---|
| Annual OCS population | 6,210 | Practices represented in annual OCS source evidence |
| Annual GPAD population | 6,184 | Practices represented in annual GPAD source evidence |
| Annual denominator population | 6,210 | Practices represented in the denominator series |
| Eligible before annual OCS-total rule | 6,130 | Met the 12-month OCS, GPAD and denominator rules |
| Zero/null annual OCS-total exclusions | 63 | OCS composition ratios undefined; no zero imputation |
| Final matrix | 6,067 | One complete record per eligible practice |

## Non-selection factors

The following do not define the cohort: a desired row count; GPAD mapping-file presence; similarity to another practice; geographic balancing; removal of statistical outliers; clustering results; or subjective performance labels.

## Interpretation

The cohort is a complete-case, 12-month practice panel for the selected source vintage. It is not all English practices, all practices with any activity, or a patient sample. Practices absent because of supplier coverage, missing months or undefined ratios may differ systematically from retained practices.

