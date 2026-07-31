# Technical reviewer guide

Use this route to inspect contracts, SQL order, cardinality, deterministic outputs and release-asset verification.

## Controls

| Control | Evidence |
|---|---|
| Prepared-source schemas | [`contracts/sources`](../../contracts/sources) |
| SQL stage order | [`sql/portable`](../../sql/portable) and [`sql/core_pipeline`](../../sql/core_pipeline) |
| Join grain and retained populations | [Analytical design index](../analytical-designs/README.md) |
| Source-month ownership | [`reference-release/manifests`](../../reference-release/manifests) |
| Output schemas and fingerprints | [`validation/authoritative_output_manifest.csv`](../../validation/authoritative_output_manifest.csv) |
| Numerical and cohort integrity | [`validation/matrix_numeric_validation.csv`](../../validation/matrix_numeric_validation.csv) |
| Join and release gates | [`validation/repository_release_gate.csv`](../../validation/repository_release_gate.csv) |

## Run deterministic tests

```powershell
python tests/run_tests.py
```

The suite covers one, three, twelve and twenty-four months, source ownership, booking-delay separation, annual eligibility, cohort nesting, inherited parent values, local documentation links and all registered reference outputs.

## Verify the reference asset

```powershell
python automation/pipeline_cli.py validate-reference `
  --restore-missing `
  --output work/reference_validation.csv
```

The verifier requires the exact asset name, byte size and SHA-256 fingerprint, supports the verified `outputs/<filename>` archive layout, and validates each restored CSV. It rejects an incorrect or unavailable asset.

## Authoritative matrix fingerprints

| Matrix | SHA-256 |
|---|---|
| National annual OCS-GPAD | `C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF` |
| CBT inbound restricted cohort | `CCC179B870BBD3EC46DD1B75868DB38156FE23A44BBC5A8FF698505FC9B63ED5` |
| CBT outcome-complete restricted cohort | `D3D2E70C1A718260DD332B59F835EB6316826677A1DF5CEB928ED563C0FC1021` |

The practice identifier remains attached for traceability and is excluded from the numerical feature count.
