# Learner tutorial

Start with a short run:

```powershell
python automation/pipeline_cli.py demo --months 3
```

The generated fixture contains five invented practice codes. Some appear in
all sources, while others appear in only OCS, GPAD or CBT. Inspect these tables
in order:

1. `practice_month_union_spine` in the generated SQLite database;
2. `multichannel_practice_month_coverage.csv`;
3. `matched_online_and_scheduled_activity.csv`;
4. `matched_multichannel_activity.csv`;
5. `pipeline_validation_results.csv`.

The coverage table retains every observed practice-month and uses source
presence flags. The matched tables answer narrower questions and therefore
retain fewer records. Empty OCS, GPAD or CBT fields are not changed to zero.

The number three is only a convenient small example. The same command accepts
any positive integer, so `--months 1` and `--months 24` exercise one-month and
twenty-four-month practice panels.

Then run the twelve-month fixture:

```powershell
python automation/pipeline_cli.py demo --months 12
```

Twelve months additionally creates an annual 13-feature matrix because the
synthetic configuration explicitly enables that product. Compare its booking
features with the source columns: one-day and two-to-seven-day counts are
combined once, while all intervals above fourteen days remain mutually
exclusive. Other period lengths deliberately leave the annual tables empty.
