# PCADI v2 repository rebuild report

## 1. What was found

The published repository described a national annual matrix with thirteen
numerical features. The completed dissertation lineage contained fourteen. The
repository had combined the GPAD `1 day` and `2 to 7 days` booking bands in its
public modelling interface even though the authoritative matrices retained
them separately.

The authoritative local assets were identified by exact schema, dimensions,
full-table parent-child inheritance and SHA-256 checksum. Their provenance is
recorded in
[`validation/pcadi_v2_authoritative_source_register.csv`](validation/pcadi_v2_authoritative_source_register.csv).
The dependency review is recorded in
[`docs/audits/PCADI_V2_DEPENDENCY_GRAPH.md`](docs/audits/PCADI_V2_DEPENDENCY_GRAPH.md).

## 2. Why the former release was wrong

GPAD publishes `1 day` and `2 to 7 days` as separate booking-interval
categories. The former repository matrix replaced those two source-defined
features with one derived `1 to 7 days` share. That interface did not match the
completed dissertation analysis and removed information that the authoritative
matrix retained.

The repair preserves both exact fields. A combined value remains available only
as `gpad_days_1_to_7_audit_share` in the detailed annual table, where its name
and purpose make clear that it is an audit derivative rather than a modelling
feature.

## 3. Authoritative 14 to 17 to 21 contracts

| Matrix | Practices | Numerical features | Total columns | SHA-256 |
|---|---:|---:|---:|---|
| National annual OCS-GPAD | 6,067 | 14 | 15 | `C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF` |
| CBT inbound restricted cohort | 3,020 | 17 | 18 | `CCC179B870BBD3EC46DD1B75868DB38156FE23A44BBC5A8FF698505FC9B63ED5` |
| CBT outcome-complete restricted cohort | 1,456 | 21 | 22 | `D3D2E70C1A718260DD332B59F835EB6316826677A1DF5CEB928ED563C0FC1021` |

The 3,020 practice codes are nested inside the 6,067-practice population. The
1,456 practice codes are nested inside the 3,020-practice population. Every
shared value agrees exactly after alignment by practice code. Identifiers are
retained for traceability and excluded from numerical modelling.

The downstream outcome-composition notebook was also located. Its notebook
hash is
`28B987989989F25F86946A711BD9F93D16236339DB53470E0B8700B1609C8284`.
Its scaled 20-feature ILR matrix has hash
`91F798BF93335506EB342B4DE7DB46FAC85BE429370F17E7F797DE9B09A15BDF`.
That modelling sensitivity remains separate from the raw SQL integration
output.

## 4. Public analytical designs

The public guides now use descriptive names based on the retained population
and analytical question.

| Public design | Grain | Retained population and logic |
|---|---|---|
| Online consultation records with appointment context | Practice-month | Every OCS key; attach GPAD and CBT on practice code plus month |
| Appointment records with online consultation context | Practice-month | Every GPAD key; attach OCS and CBT on practice code plus month |
| Coverage-preserving OCS, GPAD and CBT practice-month spine | Practice-month | Union of observed source keys with separate presence and integrity flags |
| Matched online consultation and appointment activity | Practice-month | Keys with both OCS and GPAD evidence |
| Matched OCS, GPAD and valid CBT activity | Practice-month | Matched OCS-GPAD keys with observed and validly mapped CBT evidence |
| OCS-GPAD comparison within the CBT-observed population | Practice-month | OCS-GPAD comparison restricted to valid CBT-observed keys |
| National annual OCS-GPAD access-activity profile matrix | Practice | Twelve complete eligible OCS and GPAD months with valid denominators |
| CBT inbound restricted-cohort access-profile matrix | Practice | National-core practices with complete valid CBT inbound evidence |
| CBT outcome-complete restricted-cohort access-profile matrix | Practice | Inbound-cohort practices with complete recorded CBT outcome evidence |
| Within-week online consultation and telephony timing | Practice-month-day-time before summary | Separately recorded OCS and CBT activity in compatible day/time buckets |

Each individual guide states the question, grain, key, use, retained records,
selection limitation and validation evidence. The historical label crosswalk is
quarantined under `docs/internal/`.

## 5. File categories changed

- Fixed and portable SQL now produce the same fourteen-feature annual contract.
- Validation SQL now applies 39 fixed-build gates and 16 portable gates.
- Synthetic fixtures keep `1 day` and `2 to 7 days` deliberately unequal.
- Output contracts, data dictionaries, checksums and manifests match actual
  headers.
- The three authoritative matrices replace the superseded active assets.
- README, start guide and five audience routes now lead readers to the relevant
  question, output and validation evidence.
- Ten analytical-design pages explain row retention and interpretation.
- Architecture, cohort-flow and social-preview assets provide compact visual
  orientation with text equivalents.
- Release notes, migration evidence and superseded-output registers preserve
  history without leaving obsolete matrices in the active output directory.
- Release and restoration automation now targets the v2.0.0 fourteen-output
  archive.
- Local user paths were removed from tracked provenance text.

The complete path-level inventory is in
[`validation/pcadi_v2_changed_file_manifest.csv`](validation/pcadi_v2_changed_file_manifest.csv).

## 6. Old and new checksums

| Asset | Superseded SHA-256 | v2 SHA-256 |
|---|---|---|
| National annual matrix | `97B5EDA02117F14250D712E5F265E465E165725340D415B81178E78931011444` | `C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF` |
| CBT inbound matrix | `09DDF224A4D38410A1912163C1449F83DAFAA80984BA12C37B5E96BBF3333263` | `CCC179B870BBD3EC46DD1B75868DB38156FE23A44BBC5A8FF698505FC9B63ED5` |
| CBT outcome matrix | `822D9764863E94E2146C2B3970CA8963A38C92DEC675C58C798E7692CD5EB8C6` | `D3D2E70C1A718260DD332B59F835EB6316826677A1DF5CEB928ED563C0FC1021` |

The deterministic v2 reference archive contains fourteen CSVs, is 40,656,898
bytes and has SHA-256
`93F6594BE743DA79CE4E8461DD307AF99692B31D61AAF2E12C003DB336C55022`.
It is prepared locally for publication only after the pull request is approved.

## 7. Validation results

- `python tests/run_tests.py`: PASS.
- `RUN_DEMO.cmd`: PASS.
- Configurable 1-, 3-, 12- and 24-month commands: PASS.
- Portable SQL: 16 PASS and 0 FAIL for each tested period.
- `RUN_REFERENCE_VALIDATION.cmd`: 14 files checked, 0 failures.
- Public matrix dimensions, schemas, uniqueness, finite values, nesting and
  inheritance: PASS.
- Join-design grain and cardinality: PASS with zero duplicate stated keys and
  row-multiplication factor 1.0.
- Publication manifest: 153 candidate files and 0 blockers.
- Public terminology, local paths, encoding and internal links: PASS.
- Clean official-source build: 21/21 imports, 12/12 SQL stages, 39 PASS and
  0 FAIL, database integrity `ok`, 0 foreign-key violations and 6,067 unique
  practices.

The clean SQL export uses seventeen significant digits while the locked
authoritative CSV uses shorter equivalent decimal strings. All 84,938
numerical cells are exactly equal after parsing, and the canonical
6,067-practice fingerprint agrees byte for byte. The authoritative public CSV
retains its locked checksum. See
[`validation/clean_build_value_equivalence.csv`](validation/clean_build_value_equivalence.csv).

The full machine-readable acceptance record is
[`validation/pcadi_v2_repository_rebuild_gate.csv`](validation/pcadi_v2_repository_rebuild_gate.csv).

## 8. Historical material retained

The old dimensions, hashes and replacement assets remain only in the migration
note and superseded-output registers. Historical design labels remain only in
the internal crosswalk. The v1 practice-month restore manifest is retained with
an explicit v1 filename for release history and is no longer used by the active
restore command.

## 9. Limits of verification

The clean 21-input reconstruction covers the primary OCS-GPAD annual build. The
CBT restricted-cohort and temporal outputs depend on separate validated source
sets, so they were not silently reconstructed by that core runner. Their
published matrices were verified against authoritative local assets, exact
hashes, full schemas, cohort nesting and complete inherited-value comparisons.

The v2.0.0 GitHub Release and its archive have not been published because
release publication requires approval after review. No clustering was run.

## 10. Branch and pull request

- Branch: `repo-rebuild/correct-14-feature-and-design-guides`
- Base: `main`
- Pull request: `TO_BE_INSERTED_AFTER_DRAFT_PR_CREATION`

## Recommendation

**READY FOR REVIEW.**

The repository is analytically coherent, the public interface matches the
authoritative dissertation matrices, every mandatory gate passes, and the
remaining action is human review of the draft pull request. Merge and v2.0.0
release publication should occur only after that review.
