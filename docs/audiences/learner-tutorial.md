# Learner tutorial

This tutorial uses deterministic synthetic data so the pipeline can be studied
without NHS downloads.

## Run a three-month example

```powershell
python automation/pipeline_cli.py demo --months 3
```

On Windows, `RUN_DEMO.cmd` runs the same command. Inspect:

- `work/demo_3_months/inputs/` for contract-shaped source files;
- `work/demo_3_months/pipeline.sqlite` for intermediate tables;
- `work/demo_3_months/outputs/` for analytical tables; and
- `pipeline_validation_results.csv` for the gates.

## Follow one key

Choose one practice and month. Compare it across OCS, GPAD, CBT, the union
spine and a matched output. Notice that:

- source-led views keep the selected source even when another source is absent;
- the union spine preserves every reported source key;
- matched views contain only common eligible keys; and
- missing reporting is not changed to zero.

The [analytical design index](../analytical-designs/README.md) explains why each
population differs.

The demo runs no clustering and its values are not NHS observations.
