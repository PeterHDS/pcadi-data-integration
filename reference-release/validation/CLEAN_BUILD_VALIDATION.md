# Clean reference build validation

The fixed April 2025 to March 2026 OCS-GPAD build was executed from the 21
checksum-locked official source files in a new ignored SQLite database. Existing
reference outputs were not used as SQL inputs and were not overwritten.

- Completed UTC: 30 July 2026 at 00:11:34
- Working database size: 6,666,563,584 bytes
- Working database SHA-256:
  `2B187CAE3460C39BF7ED69A627D1F3D8FDE1EC1E046EA863ECA00E76A67A7155`
- SQL stages completed: 12/12
- Raw manifest imports: 21/21
- Mandatory SQL validations: 39 PASS, 0 FAIL
- Database integrity: `ok`
- Foreign-key violations: 0
- Final rows and unique practices: 6,067
- Matrix contract: one identifier plus fourteen numerical features
- Feature-range rows: 14
- Canonical fingerprint SHA-256:
  `2124FED989F4D0EE4D35B35BE9AE142927F83DEBE868169CFEF3EE638641A3ED`
- Expected-versus-observed canonical fingerprint: exact byte agreement
- Clustering run: no

The clean exporter writes every SQLite floating-point value with seventeen
significant digits. The locked dissertation CSV uses a shorter decimal
representation for many values. This produces different CSV bytes while
representing the same binary floating-point values. A full comparison found
identical headers, identical ordered practice codes, 84,938 numerical cells,
zero numerical-value differences and maximum absolute difference `0`.

The clean export therefore remains build evidence rather than a replacement
public asset. The authoritative public matrix retains SHA-256
`C50B14AA191C54C29201DC9909E138395C1A2AEA7F596E8CF6B02F43A6DD7EBF`.
The serialization comparison is recorded in
`validation/clean_build_value_equivalence.csv`.

During this run, the wrapper observed all 39 gates passing but still expected
the former count of 36. The assertion was updated to 39. Stages 1 to 11 were
already committed in the clean database, so only the previously unexecuted
Stage 12 and deterministic exports were resumed. No analytical SQL or source
data changed during that control repair.
