#!/usr/bin/env python3
"""Generate bundled catalog + admissions pathway JSON for the CollegeTracker iOS app.

Looks for the college-data checkout in this order:
  COLLEGE_DATA_DIR env, ../college-data-git, ../college-data, /workspace/college-data-git
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


def find_data_dir() -> Path:
    for candidate in CANDIDATE_DATA_DIRS:
        if candidate is None:
            continue
        csv_dir = candidate / "data" if (candidate / "data").is_dir() else candidate
        catalog = csv_dir / "universities_hk_japan_v1.csv"
        admissions = csv_dir / "universities_japan_admissions_v1.csv"
        if catalog.exists() and admissions.exists():
            return csv_dir
    raise SystemExit("Could not find college-data CSVs (universities_hk_japan_v1.csv / universities_japan_admissions_v1.csv)")


# Structured HK pathways derived from universities_hk_japan_v1.csv admissions_notes
# (there is no separate HK admissions join table in college-data).
HK_PATHWAYS: dict[str, list[dict[str, str]]] = {
    "HK001": [  # The University of Hong Kong
        {
            "student_category": "local_jupas",
            "pathway_name": "JUPAS (HKDSE)",
            "exams_required": "Hong Kong Diploma of Secondary Education (HKDSE) via the Joint University Programmes Admissions System (JUPAS).",
            "typical_timeline": "JUPAS cycle in the HKDSE year; programme choice list and offer rounds follow the official JUPAS calendar.",
            "language_requirements": "Instruction mainly English.",
            "notes": "Local HKDSE applicants apply through JUPAS. Always confirm programme-specific subject requirements on the current HKU / JUPAS pages.",
            "confidence": "high",
        },
        {
            "student_category": "international_non_jupas",
            "pathway_name": "Non-JUPAS / International",
            "exams_required": "Apply directly to HKU with IB, GCE A-Level, SAT, or other recognised qualifications.",
            "typical_timeline": "Typically October–November main round for the following September intake.",
            "language_requirements": "Instruction mainly English.",
            "notes": "International and other non-JUPAS applicants apply directly to HKU. A student visa is required for non-locals. Verify the current non-JUPAS guide; do not treat this summary as a deadline.",
            "confidence": "high",
        },
    ],
    "HK002": [  # CUHK
        {
            "student_category": "local_jupas",
            "pathway_name": "JUPAS (HKDSE)",
            "exams_required": "HKDSE via JUPAS.",
            "typical_timeline": "Follow the official JUPAS calendar in the HKDSE year.",
            "language_requirements": "Bilingual environment; many programmes are English-medium; Chinese is used in some arts and education tracks.",
            "notes": "Local HKDSE applicants apply through JUPAS. Check faculty-specific language and subject requirements.",
            "confidence": "high",
        },
        {
            "student_category": "international_non_jupas",
            "pathway_name": "Non-JUPAS / International",
            "exams_required": "Direct application with IB, A-Level, or other recognised qualifications.",
            "typical_timeline": "Main non-JUPAS / international deadlines often December–January; confirm the current CUHK international admissions calendar.",
            "language_requirements": "Bilingual environment; many programmes English-medium.",
            "notes": "Non-JUPAS and international applicants apply directly. Verify the current guide before setting a deadline in the app.",
            "confidence": "high",
        },
    ],
    "HK003": [  # HKUST
        {
            "student_category": "local_jupas",
            "pathway_name": "JUPAS (HKDSE)",
            "exams_required": "HKDSE via JUPAS.",
            "typical_timeline": "Follow the official JUPAS calendar in the HKDSE year.",
            "language_requirements": "Instruction predominantly English.",
            "notes": "Local HKDSE applicants apply through JUPAS.",
            "confidence": "high",
        },
        {
            "student_category": "international_non_jupas",
            "pathway_name": "Non-JUPAS / International",
            "exams_required": "Direct international application; IB, A-Level, and AP are commonly submitted.",
            "typical_timeline": "International applications typically open in autumn for the following September intake.",
            "language_requirements": "Instruction predominantly English.",
            "notes": "Confirm current international / non-JUPAS dates on the HKUST admissions site.",
            "confidence": "high",
        },
    ],
    "HK004": [  # PolyU
        {
            "student_category": "local_jupas",
            "pathway_name": "JUPAS (HKDSE)",
            "exams_required": "HKDSE via JUPAS.",
            "typical_timeline": "Follow the official JUPAS calendar in the HKDSE year.",
            "language_requirements": "Mainly English instruction.",
            "notes": "Local HKDSE applicants apply through JUPAS. PolyU has a strong applied / professional focus.",
            "confidence": "high",
        },
        {
            "student_category": "international_non_jupas",
            "pathway_name": "Non-JUPAS / International",
            "exams_required": "Direct non-JUPAS / international application with recognised overseas qualifications.",
            "typical_timeline": "See the current PolyU international / non-JUPAS admissions calendar.",
            "language_requirements": "Mainly English instruction.",
            "notes": "Verify programme-specific requirements and dates on the official PolyU pages.",
            "confidence": "high",
        },
    ],
    "HK005": [  # CityU
        {
            "student_category": "local_jupas",
            "pathway_name": "JUPAS (HKDSE)",
            "exams_required": "HKDSE via JUPAS.",
            "typical_timeline": "Follow the official JUPAS calendar in the HKDSE year.",
            "language_requirements": "English-medium teaching.",
            "notes": "Local HKDSE applicants apply through JUPAS.",
            "confidence": "high",
        },
        {
            "student_category": "international_non_jupas",
            "pathway_name": "Non-JUPAS / International",
            "exams_required": "Direct international / non-JUPAS application.",
            "typical_timeline": "See the current CityU international admissions calendar.",
            "language_requirements": "English-medium teaching. Highly international student body.",
            "notes": "Confirm deadlines and qualifications on the official CityU pages.",
            "confidence": "high",
        },
    ],
    "HK006": [  # HKBU
        {
            "student_category": "local_jupas",
            "pathway_name": "JUPAS (HKDSE)",
            "exams_required": "HKDSE via JUPAS.",
            "typical_timeline": "Follow the official JUPAS calendar in the HKDSE year.",
            "language_requirements": "English as the primary medium of instruction; Chinese is used in Chinese Medicine and Chinese programmes.",
            "notes": "Local HKDSE applicants apply through JUPAS. Check language of instruction by programme.",
            "confidence": "high",
        },
        {
            "student_category": "international_non_jupas",
            "pathway_name": "Non-JUPAS / International",
            "exams_required": "Direct non-JUPAS / international application.",
            "typical_timeline": "See the current HKBU non-JUPAS / international admissions calendar.",
            "language_requirements": "English as the primary medium of instruction, with Chinese used in some programmes.",
            "notes": "Verify the current guide before setting a deadline in the app.",
            "confidence": "high",
        },
    ],
    "HK007": [  # Lingnan
        {
            "student_category": "local_jupas",
            "pathway_name": "JUPAS (HKDSE)",
            "exams_required": "HKDSE via JUPAS.",
            "typical_timeline": "Follow the official JUPAS calendar in the HKDSE year.",
            "language_requirements": "English as the main medium of instruction.",
            "notes": "Small liberal-arts university. Local HKDSE applicants apply through JUPAS.",
            "confidence": "high",
        },
        {
            "student_category": "international_non_jupas",
            "pathway_name": "Non-JUPAS / International",
            "exams_required": "Direct international / non-JUPAS application.",
            "typical_timeline": "See the current Lingnan international admissions calendar.",
            "language_requirements": "English as the main medium of instruction.",
            "notes": "Confirm dates and qualifications on the official Lingnan pages.",
            "confidence": "high",
        },
    ],
    "HK008": [  # EdUHK
        {
            "student_category": "local_jupas",
            "pathway_name": "JUPAS (HKDSE)",
            "exams_required": "HKDSE via JUPAS.",
            "typical_timeline": "Follow the official JUPAS calendar in the HKDSE year.",
            "language_requirements": "English and Chinese used depending on the programme.",
            "notes": "Teacher-education focus. Local HKDSE applicants apply through JUPAS.",
            "confidence": "high",
        },
        {
            "student_category": "international_non_jupas",
            "pathway_name": "Non-JUPAS / International",
            "exams_required": "Direct international / non-JUPAS application.",
            "typical_timeline": "See the current EdUHK international / non-JUPAS admissions calendar.",
            "language_requirements": "English and Chinese used depending on the programme.",
            "notes": "Verify programme-specific language and admissions requirements.",
            "confidence": "high",
        },
    ],
    "HK009": [  # HKMU — generally not JUPAS
        {
            "student_category": "direct_application",
            "pathway_name": "Direct application",
            "exams_required": "Apply directly to Hong Kong Metropolitan University. Most places are not offered through JUPAS.",
            "typical_timeline": "See the current HKMU admissions calendar. Flexible and part-time pathways have historically been available; full-time undergraduate intake has expanded.",
            "language_requirements": "English or Chinese depending on the programme.",
            "notes": "Not UGC-funded for most places. Confirm the current application route; do not assume a JUPAS code exists for a given programme.",
            "confidence": "high",
        },
    ],
    "HK010": [  # Hang Seng
        {
            "student_category": "direct_application",
            "pathway_name": "Direct application (non-JUPAS)",
            "exams_required": "Direct application; growing international intake.",
            "typical_timeline": "See the current Hang Seng University of Hong Kong admissions calendar.",
            "language_requirements": "English and Chinese are used.",
            "notes": "Self-financing private university. Applications are direct (non-JUPAS). Verify current requirements on the official site.",
            "confidence": "high",
        },
    ],
    "HK011": [  # Shue Yan
        {
            "student_category": "direct_application",
            "pathway_name": "Direct application",
            "exams_required": "Direct application with the qualifications listed in the current admissions guide.",
            "typical_timeline": "See the current Hong Kong Shue Yan University admissions calendar.",
            "language_requirements": "Bilingual environment with a strong Chinese-language / liberal arts character.",
            "notes": "Self-financing private university. Confirm the current application process on the official site.",
            "confidence": "high",
        },
    ],
    "HK012": [  # Chu Hai
        {
            "student_category": "direct_application",
            "pathway_name": "Direct application (international and local)",
            "exams_required": "Direct application for international students and other applicants as set out in the current guide.",
            "typical_timeline": "See the current Hong Kong Chu Hai College admissions calendar.",
            "language_requirements": "Chinese or English depending on the programme.",
            "notes": "Self-financing institution with smaller enrolment. Verify current requirements on the official pages.",
            "confidence": "high",
        },
    ],
}

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


def generate_pathways(data_dir: Path) -> None:
    src = data_dir / "universities_japan_admissions_v1.csv"
    by_id: dict[str, list[dict[str, str]]] = defaultdict(list)
    with src.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            by_id[row["university_id"]].append(
                {
                    "student_category": row["student_category"].strip(),
                    "pathway_name": row["pathway_name"].strip(),
                    "exams_required": row["exams_required"].strip(),
                    "typical_timeline": row["typical_timeline"].strip(),
                    "language_requirements": row["language_requirements"].strip(),
                    "notes": (row.get("notes") or "").strip(),
                    "confidence": (row.get("confidence") or "").strip(),
                }
            )
    # HK structured pathways (do not overwrite if a future CSV adds HK ids)
    for uid, rows in HK_PATHWAYS.items():
        by_id.setdefault(uid, rows)

    payload = {
        "version": "pathways_v1",
        "source": "college-data/universities_japan_admissions_v1.csv + HK admissions_notes (structured)",
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
