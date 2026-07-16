# Contributing

Changes should be small, documented and accompanied by deterministic tests.
Never commit raw NHS downloads, databases, archives, credentials or local paths.

For a new publication or schema:

1. retain the official publication page and metadata;
2. add or version the relevant source contract;
3. add a synthetic regression fixture;
4. prove source-month ownership and source-total reconciliation;
5. run both demonstration periods and reference validation;
6. document any changed output contract.

Analytical transformations and joins belong in SQL. Orchestration code must not
silently implement a competing transformation.
