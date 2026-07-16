#!/usr/bin/env python3
"""Rebuild and fingerprint the frozen OCS/GPAD annual reference from official CSVs."""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import hashlib
import json
import os
import platform
import re
import sqlite3
import subprocess
import sys
import time
from pathlib import Path

from export_outputs import export_all


STAGE_PATTERN = re.compile(
    r"-- >>> BEGIN STAGE (?P<name>[^\r\n]+)\r?\n(?P<sql>.*?)"
    r"-- <<< END STAGE (?P=name)",
    re.DOTALL,
)


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(16 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def read_manifest(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle))
    if len(rows) != 21:
        raise RuntimeError(f"Input manifest must contain 21 rows; observed {len(rows)}")
    return sorted(rows, key=lambda row: int(row["execution_order"]))


def resolve_input(row: dict[str, str], package_root: Path) -> Path:
    absolute = Path(row["absolute_source_path"])
    if absolute.is_file():
        return absolute
    relative = (package_root / Path(row["recommended_relative_path"])).resolve()
    if relative.exists():
        return relative
    raise FileNotFoundError(f"Manifest input not found: {absolute} or {relative}")


def parse_master(path: Path) -> list[tuple[str, str]]:
    text = path.read_text(encoding="utf-8")
    stages = [(match.group("name"), match.group("sql")) for match in STAGE_PATTERN.finditer(text)]
    if len(stages) != 12:
        raise RuntimeError(f"Master script must contain 12 marked stages; observed {len(stages)}")
    expected_prefixes = [f"{number:02d}_" for number in range(1, 13)]
    for (name, _), prefix in zip(stages, expected_prefixes):
        if not name.startswith(prefix):
            raise RuntimeError(f"Stage order mismatch at {name}; expected prefix {prefix}")
    return stages


def execute_stage(connection: sqlite3.Connection, name: str, sql: str) -> float:
    started = time.perf_counter()
    try:
        connection.executescript("BEGIN IMMEDIATE;\n" + sql + "\nCOMMIT;")
    except Exception:
        try:
            connection.execute("ROLLBACK")
        except sqlite3.Error:
            pass
        raise
    return time.perf_counter() - started


def import_one_file(
    connection: sqlite3.Connection,
    row: dict[str, str],
    source: Path,
) -> dict[str, object]:
    expected_hash = row["sha256"].upper()
    observed_hash = sha256_file(source)
    if observed_hash != expected_hash:
        raise RuntimeError(f"Checksum mismatch for {source}: {observed_hash} != {expected_hash}")

    table = row["destination_raw_table"]
    table_columns = [item[1] for item in connection.execute(f'PRAGMA table_info("{table}")')]
    expected_header = row["expected_columns"].split("|")
    if table_columns != expected_header:
        raise RuntimeError(
            f"Raw table schema mismatch for {table}: table={table_columns}, manifest={expected_header}"
        )

    placeholders = ",".join("?" for _ in table_columns)
    insert_sql = f'INSERT INTO "{table}" VALUES ({placeholders})'
    started = time.perf_counter()
    imported = 0
    with source.open("r", encoding=row["encoding"], newline="") as handle:
        reader = csv.reader(handle, delimiter=row["delimiter"])
        observed_header = next(reader)
        if observed_header != expected_header:
            raise RuntimeError(f"CSV header mismatch for {source}: {observed_header}")
        batch: list[list[str]] = []
        for values in reader:
            if len(values) != len(table_columns):
                raise RuntimeError(
                    f"Column count mismatch in {source} at data row {imported + 1}: "
                    f"expected {len(table_columns)}, observed {len(values)}"
                )
            batch.append(values)
            if len(batch) >= 25_000:
                connection.executemany(insert_sql, batch)
                imported += len(batch)
                batch.clear()
        if batch:
            connection.executemany(insert_sql, batch)
            imported += len(batch)
    connection.commit()

    expected_rows = int(row["expected_row_count"])
    observed_rows = connection.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
    if imported != expected_rows or observed_rows != expected_rows:
        raise RuntimeError(
            f"Row count mismatch for {table}: imported={imported}, table={observed_rows}, expected={expected_rows}"
        )
    return {
        "execution_order": int(row["execution_order"]),
        "table": table,
        "source": str(source),
        "expected_rows": expected_rows,
        "observed_rows": observed_rows,
        "sha256": observed_hash,
        "duration_seconds": round(time.perf_counter() - started, 3),
        "status": "PASS",
    }


def write_import_log(path: Path, records: list[dict[str, object]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(records[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(records)


def write_validation_log(connection: sqlite3.Connection, path: Path) -> tuple[int, int]:
    rows = connection.execute(
        "SELECT validation_order, test_name, expected_result, observed_result, result "
        "FROM pipeline_validation_results ORDER BY validation_order"
    ).fetchall()
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        for row in rows:
            handle.write(" | ".join(str(value) for value in row) + "\n")
    passes = sum(row[4] == "PASS" for row in rows)
    failures = len(rows) - passes
    return passes, failures


def build_database(arguments: argparse.Namespace) -> dict[str, object]:
    package_root = arguments.manifest.resolve().parent
    logs_dir = arguments.database.resolve().parent / "logs"
    logs_dir.mkdir(parents=True, exist_ok=True)
    build_log = logs_dir / "build_log.txt"
    database = arguments.database.resolve()

    if database.exists():
        if not arguments.overwrite:
            raise FileExistsError(
                f"Refusing to overwrite existing database: {database}. Supply --overwrite explicitly."
            )
        database.unlink()
    database.parent.mkdir(parents=True, exist_ok=True)

    stages = parse_master(arguments.master_sql.resolve())
    manifest = read_manifest(arguments.manifest.resolve())
    connection = sqlite3.connect(database)
    connection.execute("PRAGMA journal_mode = OFF")
    connection.execute("PRAGMA synchronous = OFF")
    connection.execute("PRAGMA temp_store = FILE")
    connection.execute("PRAGMA cache_size = -500000")
    connection.execute("PRAGMA foreign_keys = ON")

    log_lines = [
        "PRIMARY PRACTICE ACCESS PIPELINE BUILD LOG",
        f"Started UTC: {utc_now()}",
        f"Python: {sys.version.replace(os.linesep, ' ')}",
        f"SQLite: {sqlite3.sqlite_version}",
        f"Operating system: {platform.platform()}",
        f"Manifest: {arguments.manifest.resolve()}",
        f"Master SQL: {arguments.master_sql.resolve()}",
        f"Master SQL SHA-256: {sha256_file(arguments.master_sql.resolve())}",
        f"Database: {database}",
        "",
    ]
    stage_records: list[dict[str, object]] = []
    overall_started = time.perf_counter()

    name, sql = stages[0]
    duration = execute_stage(connection, name, sql)
    stage_records.append({"stage": name, "duration_seconds": duration, "status": "PASS"})
    log_lines.append(f"{name}: PASS ({duration:.3f}s)")

    import_records = []
    for row in manifest:
        source = resolve_input(row, package_root)
        record = import_one_file(connection, row, source)
        import_records.append(record)
        log_lines.append(
            f"IMPORT {record['table']}: PASS rows={record['observed_rows']} "
            f"duration={record['duration_seconds']}s"
        )
    write_import_log(logs_dir / "import_log.csv", import_records)

    for name, sql in stages[1:]:
        duration = execute_stage(connection, name, sql)
        stage_records.append({"stage": name, "duration_seconds": duration, "status": "PASS"})
        log_lines.append(f"{name}: PASS ({duration:.3f}s)")
        if name.startswith("03_"):
            raw_failures = connection.execute(
                "SELECT COUNT(*) FROM raw_source_row_count_validation WHERE status <> 'PASS'"
            ).fetchone()[0]
            if raw_failures:
                raise RuntimeError(f"Mandatory raw row-count validations failed: {raw_failures}")
        if name.startswith("11_"):
            count, passes, failures = connection.execute(
                "SELECT COUNT(*), SUM(result = 'PASS'), SUM(result <> 'PASS') "
                "FROM pipeline_validation_results"
            ).fetchone()
            if count != 36 or passes != 36 or failures != 0:
                raise RuntimeError(
                    f"Mandatory validation gate failed: count={count}, PASS={passes}, FAIL={failures}"
                )

    integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
    foreign_key_rows = connection.execute("PRAGMA foreign_key_check").fetchall()
    if integrity != "ok" or foreign_key_rows:
        raise RuntimeError(
            f"Database integrity gate failed: integrity={integrity}, foreign_key_rows={len(foreign_key_rows)}"
        )
    passes, failures = write_validation_log(connection, logs_dir / "validation_log.txt")
    final_rows, final_practices = connection.execute(
        "SELECT COUNT(*), COUNT(DISTINCT practice_code_standardised) "
        "FROM primary_practice_access_clustering_matrix_ordered"
    ).fetchone()
    connection.close()

    export_records = export_all(
        database,
        arguments.output_dir.resolve(),
        arguments.validation_dir.resolve(),
        logs_dir / "export_log.txt",
    )

    observed_fingerprint = arguments.output_dir.resolve() / "modelling_output_fingerprint.csv"
    expected_fingerprint = arguments.expected_fingerprint.resolve()
    observed_fingerprint_hash = sha256_file(observed_fingerprint)
    expected_fingerprint_hash = sha256_file(expected_fingerprint)
    if observed_fingerprint_hash != expected_fingerprint_hash:
        raise RuntimeError(
            "Deterministic fingerprint mismatch: "
            f"observed={observed_fingerprint_hash}, expected={expected_fingerprint_hash}"
        )

    elapsed = time.perf_counter() - overall_started
    log_lines.extend(
        [
            "",
            f"Integrity check: {integrity}",
            f"Foreign-key violations: {len(foreign_key_rows)}",
            f"Validation: {passes} PASS, {failures} FAIL",
            f"Final rows: {final_rows}",
            f"Final distinct practices: {final_practices}",
            f"Reference fingerprint: PASS ({observed_fingerprint_hash})",
            f"Completed UTC: {utc_now()}",
            f"Total duration seconds: {elapsed:.3f}",
        ]
    )
    build_log.write_text("\n".join(log_lines) + "\n", encoding="utf-8")
    return {
        "database": str(database),
        "database_sha256": sha256_file(database),
        "stages_completed": len(stage_records),
        "validation_passes": passes,
        "validation_failures": failures,
        "final_rows": final_rows,
        "final_practices": final_practices,
        "integrity_check": integrity,
        "foreign_key_violations": len(foreign_key_rows),
        "reference_fingerprint": "PASS",
        "duration_seconds": round(elapsed, 3),
        "exports": export_records,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--database", required=True, type=Path)
    parser.add_argument("--master-sql", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--validation-dir", required=True, type=Path)
    parser.add_argument("--expected-fingerprint", required=True, type=Path)
    parser.add_argument("--overwrite", action="store_true")
    arguments = parser.parse_args()
    package_root = arguments.manifest.resolve().parent
    blocker_path = arguments.database.resolve().parent / "BLOCKERS_AND_EXCEPTIONS.md"
    try:
        result = build_database(arguments)
    except Exception as error:
        blocker_path.write_text(
            "# Blockers and exceptions\n\n"
            f"- Timestamp UTC: {utc_now()}\n"
            f"- Status: FAIL\n"
            f"- Exception type: {type(error).__name__}\n"
            f"- Exception: {error}\n\n"
            "The final release ZIP must not be created until this exception is resolved without changing analytical logic.\n",
            encoding="utf-8",
        )
        print(f"PIPELINE FAILED: {error}", file=sys.stderr)
        raise
    else:
        if blocker_path.exists():
            blocker_path.unlink()
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
