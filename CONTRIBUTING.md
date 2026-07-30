# Contributing

Changes should be small, documented and accompanied by deterministic tests.
Never commit raw NHS downloads, databases, archives, credentials or local paths.
Preserve the distinction between official source definitions, transparent
project-derived measures and downstream analytical recommendations.

For a new publication or schema:

1. retain the official publication page and metadata;
2. add or version the relevant source contract;
3. add a synthetic regression fixture;
4. prove source-month ownership and source-total reconciliation;
5. run the 1, 3, 12 and 24-month demonstrations and reference validation;
6. document any changed output contract;
7. update the feature dictionary, checksums and migration record; and
8. test exact parent-to-child inheritance for restricted-cohort matrices.

Analytical transformations and joins belong in SQL. Orchestration code must not
silently implement a competing transformation.

## Documentation style

- Use direct, public-facing language that explains purpose before implementation.
- Prefer colons, commas, parentheses or separate sentences instead of em dashes.
- Define abbreviations on first use and retain exact table names only where they
  help a reader run or validate the pipeline.
- State the retained population, grain and analytical limitation whenever a new
  output is documented.
