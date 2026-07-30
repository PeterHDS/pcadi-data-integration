# Clean reference build validation

The April 2025 to March 2026 OCS-GPAD build was executed from 21
checksum-locked official source files in a new ignored SQLite database.
Existing reference outputs were not used as SQL inputs and were not
overwritten.

- Completed UTC: 30 July 2026 at 00:11:34
- Working database size: 6,666,563,584 bytes
- SQL stages completed: 12/12
- Raw manifest imports: 21/21
- Mandatory SQL validations: 39 PASS, 0 FAIL
- Database integrity: `ok`
- Foreign-key violations: 0
- Final rows and unique practices: 6,067
- Matrix contract: one identifier plus fourteen numerical features
- Feature-range rows: 14
- Expected-versus-observed canonical values: exact agreement
- Clustering run: no

The clean exporter writes SQLite floating-point values with seventeen
significant digits. The frozen public CSV uses its established serialization.
A full comparison found identical headers, identical ordered practice codes,
84,938 numerical cells, zero numerical-value differences and maximum absolute
difference `0`.

The clean export is build evidence rather than a replacement public asset.
Value-equivalence evidence is recorded in
`validation/clean_build_value_equivalence.csv`. The authoritative public
matrix fingerprint remains in the technical output manifest.
