#!/usr/bin/env python3
"""Generate bundled catalog + admissions pathway JSON for the CollegeTracker iOS app.

Looks for the college-data checkout in this order:
  COLLEGE_DATA_DIR env, ../college-data-git, ../college-data, /workspace/college-data-git
Requires universities_hk_japan_v1.csv, universities_japan_admissions_v1.csv, and
universities_hk_admissions_v1.csv (under a data/ subfolder or the directory root).
"""
from __future__ import annotations

import csv
import json
import os
from collections import defaultdict
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / "CollegeTracker" / "Resources"
TODAY = date.today().isoformat()

CANDIDATE_DATA_DIRS = [
    Path(os.environ["COLLEGE_DATA_DIR"]) if os.environ.get("COLLEGE_DATA_DIR") else None,
    ROOT.parent / "college-data-git",
    ROOT.parent / "college-data",
    Path("/workspace/college-data-git"),
    Path("/workspace/college-data"),
]

REQUIRED_CSVS = (
    "universities_hk_japan_v1.csv",
    "universities_japan_admissions_v1.csv",
    "universities_hk_admissions_v1.csv",
)

PATHWAY_FIELDS = [
    "student_category",
    "pathway_name",
    "exams_required",
    "typical_timeline",
    "language_requirements",
    "notes",
    "confidence",
]

CATALOG_FIELDS = [
    "id",
    "official_english_name",
    "local_native_name",
    "city",
    "country_region",
    "website",
    "type",
    "founded_year",
    "qs_wur_rank",
    "qs_rank_year",
    "tuition_approx_usd",
    "tuition_currency",
    "majors_faculties",
    "admissions_notes",
]


def resolve_csv_dir(candidate: Path) -> Path:
    return candidate / "data" if (candidate / "data").is_dir() else candidate


def missing_required_csvs(csv_dir: Path) -> list[str]:
    return [name for name in REQUIRED_CSVS if not (csv_dir / name).exists()]


def find_data_dir() -> Path:
    env_dir = os.environ.get("COLLEGE_DATA_DIR")
    if env_dir:
        csv_dir = resolve_csv_dir(Path(env_dir))
        missing = missing_required_csvs(csv_dir)
        if missing:
            raise SystemExit(
                f"COLLEGE_DATA_DIR={env_dir} is missing required CSV(s): {', '.join(missing)}. "
                "Need universities_hk_japan_v1.csv, universities_japan_admissions_v1.csv, "
                "and universities_hk_admissions_v1.csv."
            )
        return csv_dir
    for candidate in CANDIDATE_DATA_DIRS:
        if candidate is None:
            continue
        csv_dir = resolve_csv_dir(candidate)
        if not missing_required_csvs(csv_dir):
            return csv_dir
    raise SystemExit(
        "Could not find college-data CSVs (universities_hk_japan_v1.csv, "
        "universities_japan_admissions_v1.csv, and universities_hk_admissions_v1.csv). "
        "Set COLLEGE_DATA_DIR to a college-data checkout that includes the official HK admissions CSV."
    )


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    path.write_text(text, encoding="utf-8")
    print(f"Wrote {path.relative_to(ROOT)} ({path.stat().st_size:,} bytes, {payload.get('count', '?')} rows)")


def generate_catalog(data_dir: Path) -> None:
    src = data_dir / "universities_hk_japan_v1.csv"
    colleges = []
    with src.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            colleges.append({field: (row.get(field) or "").strip() for field in CATALOG_FIELDS})
    write_json(
        RESOURCES / "universities_hk_japan_v1.json",
        {
            "version": "hk_japan_v1",
            "source": "college-data/universities_hk_japan_v1.csv",
            "generated": TODAY,
            "region_focus": "Hong Kong SAR + Japan",
            "count": len(colleges),
            "colleges": colleges,
        },
    )


def load_admissions_csv(path: Path, by_id: dict[str, list[dict[str, str]]]) -> int:
    if not path.exists():
        raise SystemExit(f"Missing official admissions CSV: {path.name}")
    count = 0
    with path.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            uid = (row.get("university_id") or "").strip()
            if not uid:
                continue
            by_id[uid].append({field: (row.get(field) or "").strip() for field in PATHWAY_FIELDS})
            count += 1
    return count


def generate_pathways(data_dir: Path) -> None:
    by_id: dict[str, list[dict[str, str]]] = defaultdict(list)
    japan_count = load_admissions_csv(data_dir / "universities_japan_admissions_v1.csv", by_id)
    hk_count = load_admissions_csv(data_dir / "universities_hk_admissions_v1.csv", by_id)
    print(f"Loaded {japan_count} Japan pathway rows and {hk_count} official HK pathway rows")

    payload = {
        "version": "pathways_v1",
        "source": "college-data/universities_japan_admissions_v1.csv + college-data/universities_hk_admissions_v1.csv",
        "generated": TODAY,
        "region_focus": "Hong Kong SAR + Japan",
        "count": sum(len(v) for v in by_id.values()),
        "pathways_by_id": dict(sorted(by_id.items())),
    }
    write_json(RESOURCES / "admissions_pathways_v1.json", payload)


def main() -> None:
    data_dir = find_data_dir()
    print(f"Using college-data CSVs in {data_dir}")
    generate_catalog(data_dir)
    generate_pathways(data_dir)


if __name__ == "__main__":
    main()
