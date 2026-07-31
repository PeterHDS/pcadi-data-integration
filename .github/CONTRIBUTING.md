# Contributing

PCADI welcomes focused improvements to source contracts, SQL integration, validation and public guidance. Open an issue before a change that affects a source schema, retained population, feature definition or output contract.

## Source and analytical changes

For a new publication or schema:

1. Retain the official publication page and metadata.
2. Add or revise the relevant source contract.
3. Add a synthetic regression fixture.
4. Prove source-month ownership and source-total reconciliation.
5. Run the one-, three-, twelve- and twenty-four-month demonstrations and reference validation.
6. Document every changed output contract.
7. Update the feature dictionary and checksums.
8. Test exact parent-to-child inheritance for restricted-cohort matrices.

Analytical transformations and joins belong in SQL. Orchestration prepares inputs, executes the ordered SQL, exports results and records evidence from the same definitions.

## Repository hygiene

Keep raw NHS downloads, databases, archives, credentials, private audit evidence and local paths outside Git. Preserve the distinction between official source definitions, transparent project-derived measures and downstream analytical recommendations.

## Documentation style

- Explain purpose before implementation.
- Use direct, public-facing language and define abbreviations on first use.
- Prefer colons, commas, parentheses or separate sentences instead of em dashes.
- State the retained population, grain, analytical scope and validation route for every output.
- Write prose paragraphs as logical source lines and keep Markdown links intact on one line.

Run `python tests/run_tests.py` before opening a pull request. Local and GitHub Actions validation use the same entry point.
