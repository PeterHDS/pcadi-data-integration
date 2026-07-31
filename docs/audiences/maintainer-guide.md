# Maintainer guide

Changes must preserve the distinction between reusable pipeline behaviour and frozen reference outputs.

## Source updates

1. Add or revise a source contract.
2. Record publication vintage and observation-month ownership.
3. Update the source catalogue and official acquisition guide.
4. Add a deterministic synthetic fixture for the new field or rule.
5. Validate source grain before joining.

## Analytical changes

Document the question, retained population, grain, join keys, output and limitation in the [analytical design index](../analytical-designs/README.md). Do not silently rename stable machine-facing outputs.

## Regression controls

Run:

```powershell
python -m compileall automation tests reference-release/automation
python tests/run_tests.py
```

If reference outputs are intentionally changed, update the analytical contract, source evidence and technical manifests together. Do not refresh a checksum to hide an unexplained difference.

## Visual assets

Run `python automation/generate_public_visuals.py` after installing the optional visual dependency. The script generates matched SVG and PNG architecture, cohort-flow and social-preview assets from one source.
