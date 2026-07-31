#!/usr/bin/env python3
"""Create deterministic non-NHS fixtures for the portable SQL pipeline."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from pathlib import Path


MONTH_RE = re.compile(r"^\d{4}-(0[1-9]|1[0-2])$")


def positive_integer(value: str) -> int:
    number = int(value)
    if number < 1:
        raise argparse.ArgumentTypeError("months must be a positive integer")
    return number


def add_months(value: str, count: int) -> list[str]:
    year, month = map(int, value.split("-"))
    result = []
    for offset in range(count):
        index = year * 12 + month - 1 + offset
        result.append(f"{index // 12:04d}-{index % 12 + 1:02d}")
    return result


def write_csv(path: Path, fields: list[str], rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def build(output: Path, months_count: int, start_month: str | None = None) -> Path:
    start = start_month or ("2025-04" if months_count == 12 else "2026-03")
    if not MONTH_RE.fullmatch(start):
        raise ValueError("start month must use YYYY-MM")
    months = add_months(start, months_count)
    practices = ["A00001", "A00002", "A00003", "A00004", "A00005"]
    ocs_rows: list[dict[str, object]] = []
    gpad_rows: list[dict[str, object]] = []
    cbt_rows: list[dict[str, object]] = []

    for month_number, month in enumerate(months, start=1):
        for practice_number, practice in enumerate(practices, start=1):
            complete_annual = months_count == 12 and practice in {"A00001", "A00002"}
            if complete_annual or practice in {"A00001", "A00002", "A00004"}:
                total = 80 + month_number * 3 + practice_number
                clinical = total // 2
                administrative = total // 3
                ocs_rows.append({
                    "practice_code_standardised": practice,
                    "reporting_month": month,
                    "registered_patients": 5000 + practice_number * 100 + month_number,
                    "total_submissions": total,
                    "clinical_submissions": clinical,
                    "administrative_submissions": administrative,
                    "other_unknown_submissions": total - clinical - administrative,
                    "participation_flag": 1,
                    "unknown_supplier_flag": 0,
                })
            if complete_annual or practice in {"A00001", "A00003", "A00004"}:
                total = 200 + month_number * 5 + practice_number
                attended = total - 10
                dna = 8
                status_unknown = 2
                face_to_face = 100
                telephone = 70
                video = 5
                home = 5
                mode_unknown = 10
                mode_other = total - face_to_face - telephone - video - home - mode_unknown
                same_day = 40
                one_day = 20
                two_to_seven = 50
                eight_to_fourteen = 30
                fifteen_to_twenty_one = 20
                twenty_two_to_twenty_eight = 15
                more_than_twenty_eight = 10
                booking_unknown = 5
                booking_other = total - same_day - one_day - two_to_seven - eight_to_fourteen - fifteen_to_twenty_one - twenty_two_to_twenty_eight - more_than_twenty_eight - booking_unknown
                gpad_rows.append({
                    "practice_code_standardised": practice,
                    "reporting_month": month,
                    "total_appointments": total,
                    "attended": attended,
                    "dna": dna,
                    "status_unknown": status_unknown,
                    "face_to_face": face_to_face,
                    "telephone": telephone,
                    "video_online": video,
                    "home_visit": home,
                    "mode_unknown": mode_unknown,
                    "mode_other": mode_other,
                    "same_day": same_day,
                    "one_day": one_day,
                    "two_to_seven_days": two_to_seven,
                    "eight_to_fourteen_days": eight_to_fourteen,
                    "fifteen_to_twenty_one_days": fifteen_to_twenty_one,
                    "twenty_two_to_twenty_eight_days": twenty_two_to_twenty_eight,
                    "more_than_twenty_eight_days": more_than_twenty_eight,
                    "booking_unknown": booking_unknown,
                    "booking_other": booking_other,
                })
            if practice in {"A00001", "A00002", "A00005"}:
                inbound = 300 + month_number + practice_number
                answered = 180
                missed = 40
                ivr = 60
                callback = inbound - answered - missed - ivr
                cbt_rows.append({
                    "practice_code_standardised": practice,
                    "reporting_month": month,
                    "inbound_calls": inbound,
                    "answered_calls": answered,
                    "missed_calls": missed,
                    "ivr_exits": ivr,
                    "callback_requests": callback,
                    "mapping_valid": 1,
                    "integrity_gap_flag": 1 if practice == "A00005" and month == months[0] else 0,
                })

    datasets = [
        ("OCS", "main", "online_consultation_practice_month.csv", ocs_rows),
        ("GPAD", "practice_level_crosstab", "appointment_activity_practice_month.csv", gpad_rows),
        ("CBT", "practice_month_activity", "cloud_telephony_practice_month.csv", cbt_rows),
    ]
    for _, _, filename, rows in datasets:
        write_csv(output / filename, list(rows[0]), rows)

    provenance = []
    for dataset, component, filename, _ in datasets:
        checksum = sha256(output / filename)
        for month in months:
            provenance.append({
                "dataset": dataset,
                "component": component,
                "observation_month": month,
                "publication_release_month": month,
                "publication_page_url": "SYNTHETIC_FIXTURE",
                "selected": 1,
                "source_filename": filename,
                "sha256": checksum,
                "notes": "Deterministic non-NHS test evidence",
            })
    write_csv(output / "source_provenance.csv", list(provenance[0]), provenance)

    config = {
        "analysis_start_month": months[0],
        "analysis_end_month": months[-1],
        "expected_months": months_count,
        "required_sources": ["OCS", "GPAD", "CBT"],
        "annual_features": months_count == 12,
        "description": f"Deterministic {months_count}-month synthetic fixture",
    }
    config_path = output / "synthetic_config.json"
    config_path.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    return config_path


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Create deterministic test data for any positive number of months."
    )
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--months", default=3, type=positive_integer)
    parser.add_argument("--start-month", help="First observation month in YYYY-MM format")
    args = parser.parse_args()
    path = build(args.output.resolve(), args.months, args.start_month)
    print(path)


if __name__ == "__main__":
    main()
