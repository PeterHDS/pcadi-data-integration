# SQL portability notes

> The analytical design is platform-independent. The executable implementation supplied with this package was validated in SQLite. Other database engines require platform-specific import commands and limited syntax substitutions described in this portability guide.

## Tested SQLite-specific constructs

| SQLite construct | Use in this package | PostgreSQL | DuckDB | SQL Server / generic alternative |
|---|---|---|---|---|
| `PRAGMA integrity_check`, `foreign_key_check` | Physical/logical database checks | Use database-specific integrity tools and constraint checks | Use DuckDB verification/checkpoint tooling and SQL constraints | Use `DBCC CHECKDB`, constraint checks or platform equivalent |
| `printf('%.17g', x)` | Canonical numeric fingerprint | `to_char` is not byte-identical; use an explicitly tested canonical formatter | `printf` is available but verify exact formatting | `FORMAT`/`CONVERT` are not byte-identical; implement tested canonical formatting |
| `GLOB` | ASCII practice-code shape validation | POSIX regular expression (`~`) | `regexp_matches` | `LIKE` plus character checks or `PATINDEX`; ANSI engines vary |
| `pragma_table_info('t')` | Column-presence validation | `information_schema.columns` | `information_schema.columns` or `DESCRIBE` | `sys.columns` or `information_schema.columns` |
| Boolean expression inside `SUM` | Conditional counts | `SUM((condition)::int)` or `COUNT(*) FILTER` | `SUM(CAST(condition AS INTEGER))` | `SUM(CASE WHEN condition THEN 1 ELSE 0 END)` |
| `CREATE TABLE ... AS SELECT` | Materialised intermediate tables | `CREATE TABLE AS` | `CREATE TABLE AS` | `SELECT ... INTO` or create then insert |
| SQLite type affinity | Text-preserving raw staging and explicit casts | Declare text types and use guarded casts | Declare `VARCHAR`; use `TRY_CAST` where appropriate | Declare `nvarchar`; use `TRY_CONVERT`/`TRY_CAST` |
| Python/SQLite CSV import | Deterministic import with header/hash checks | `COPY` or client loader | `read_csv`/`COPY` with explicit schema | `BULK INSERT`, external table or client loader |
| `||` concatenation | Canonical lines and compound keys | Same | Same | Use `CONCAT` or `+` with explicit NULL handling |
| `LAG` window function | Adjacent-month rate changes | Same semantic syntax | Same | Same; verify date ordering and numeric types |

## Import is part of reproducibility

The master SQL creates raw tables but does not embed 21 platform-specific file-load commands. The tested Python runner verifies hash, header, encoding, column count and data-row count and inserts every field as text. A port must reproduce those checks before executing Stage 02.

## Numeric equivalence

SQLite stores numeric values using dynamic typing and binary64 REAL values. Alternative engines may use different implicit-cast, decimal or aggregation behaviour. Match explicit casts and operation ordering, and define an engine-specific canonical representation before claiming byte-level equivalence. Numerical tolerance alone is not the release criterion used for this tested implementation.

## Transaction and indexing considerations

Each stage is executed in its own transaction by the runner. Indexes are created at the standardised and aggregate keys used by later grouping and joins. Platform ports should preserve transaction boundaries and unique constraints while adapting physical index syntax and storage options.

