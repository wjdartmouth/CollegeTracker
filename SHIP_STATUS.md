# CollegeTracker ship status

**Thesis:** CollegeTracker is the mobile client for the [college-data](https://github.com/wjdartmouth/college-data) catalog (Hong Kong + Japan first). US Common App polish, counselor CloudKit sharing, and essay AI are deferred unless asked.

**Deadline:** Sunday 21 December 2026  
**Today (this update):** Thursday 12 November 2026 (Asia/Hong_Kong) — 39 days left  
**Plan:** 6-week ship. Week 1 is on `main` ([PR #2](https://github.com/wjdartmouth/CollegeTracker/pull/2) merged). [PR #3](https://github.com/wjdartmouth/CollegeTracker/pull/3) (Week 2 pathways) landed only on `ship/week1-catalog`, not on `main`. This branch (`ship/week2-onto-main`) cherry-picks the Week 2 work onto current `main` and refreshes the bundled catalog and pathways from the latest college-data.

This document is a code/repo status report. **This environment has no Mac Xcode.** Do not treat anything here as an Xcode build, Simulator, TestFlight, or App Store Connect success.

---

## Week 1 (merged to `main`, PR #2)

1. **Bundled HK + Japan catalog** — originally 830 schools (12 Hong Kong SAR + 818 Japan); this branch refreshes the bundle to the current college-data catalog (see Week 2).
2. **Searchable add-college picker** with custom-entry fallback and duplicate catalog-id checks.
3. Empty `StudentDetailView.swift` stub deleted (real view lives in counselor code, which is gated).
4. CloudKit container renamed from `iCloud.com.yourname.collegetracker` to `iCloud.edu.asu.jwang875.CollegeTracker`. ModelContainer falls back to local SwiftData if CloudKit configuration fails.
5. Counselor gated as Coming soon; no fake local-UUID iCloud sharing.
6. Hygiene: `.gitignore` excludes `xcuserdata/`, single canonical `README.md`, stub `PrivacyInfo.xcprivacy`, catalog unit tests (not executed here).

See [PR #2](https://github.com/wjdartmouth/CollegeTracker/pull/2) (merged to `main` on 11 November 2026).

---

## Week 2 (cherry-picked onto `main` and refreshed, 12 Nov 2026)

Week 2 theme is HK/JP pathway detail screens and region-aware deadline / document types. The original Week 2 commit lived on `ship/week2-pathways` (stacked on Week 1) and was merged only into `ship/week1-catalog` via PR #3. This branch brings that feature onto `main` and regenerates both bundled JSON files from current college-data.

1. **Catalog facts on the school screen**
   - Regenerated `universities_hk_japan_v1.json` with `majors_faculties` and `admissions_notes`: **839 schools (21 Hong Kong SAR + 818 Japan)**.
   - New Hong Kong schools HK013–HK021: Saint Francis University, THEi, Tung Wah College, UOW College Hong Kong, Gratia Christian College, HKCT Institute of Higher Education, Hong Kong Nang Yan College of Higher Education, Yew Chung College of Early Childhood Education, and The Hong Kong Academy for Performing Arts.
   - Detail header / Pathways tab shows type, founded year, approximate USD tuition, website, and faculties.
2. **Bundled admissions pathways**
   - Resource: `admissions_pathways_v1.json` (~2.8 MB, 3,342 rows, 841 ids).
   - Japan: joined from college-data `universities_japan_admissions_v1.csv` (4 student categories per school: domestic, EJU, international qualifications, overseas returnee), plus `JP_SYSTEM` national-norm fallback.
   - Hong Kong: official `universities_hk_admissions_v1.csv` (66 rows: 3 categories × 21 schools, plus 3 `HK_SYSTEM` fallback rows). Categories are `jupas_local`, `non_jupas_local`, and `international_non_jupas`. The generator no longer uses a hardcoded 12-school HK dict.
   - `AdmissionsStore` looks up by catalog id, with `HK_SYSTEM` / `JP_SYSTEM` fallbacks for missing HK- or JP-prefixed ids. International / EJU / Non-JUPAS rows are listed first (then local non-JUPAS, then JUPAS).
3. **Pathways tab**
   - College detail now has Pathways | Deadlines | Documents | Notes.
   - Each pathway shows category, exams, typical timeline, language, notes (expandable), and confidence.
   - Copy states these are typical catalog routes, not official deadlines — verify JUPAS / the university guide / 募集要項.
4. **Region-aware deadline types**
   - Added JUPAS, Non-JUPAS, EJU, Common Test, Comprehensive (AO), School Recommendation. Existing ED/EA/RD values are unchanged so old records still decode.
   - Add-deadline and first-deadline pickers order types by the school's catalog region; HK defaults to JUPAS, Japan to EJU.
5. **Region-aware document types**
   - Added Personal Statement, JUPAS Application, School Report, EJU Scores. Common App types remain available at the end of the HK/JP lists.
6. **Regen script:** `scripts/generate_bundled_data.py` rebuilds both JSON files from a college-data checkout (`COLLEGE_DATA_DIR`). It requires the official HK admissions CSV and exits with a clear error if that file is missing.
7. **Tests** added for official HK category titles/sort, pathway decode/lookup, `HK_SYSTEM` / `JP_SYSTEM` fallback, and region-aware type defaults. **Not executed here** (no Xcode on this box).

---

## Identifiers (confirm before ASC)

| Item | Current value in repo | Note |
|------|------------------------|------|
| App bundle ID | `edu.asu.jwang875.CollegeTracker` | Already in `project.pbxproj`. ASU-era. Vocab9000 uses `com.jianwang.Vocab9000`. |
| CloudKit container | `iCloud.edu.asu.jwang875.CollegeTracker` | Matches the bundle ID above. **No `.entitlements` file and no iCloud capability in the pbxproj yet.** |
| Suggested alternative | `com.jianwang.CollegeTracker` / `iCloud.com.jianwang.CollegeTracker` | Only switch if Jian wants a personal team ID before creating the App Store Connect record. Changing later is painful. |
| iOS deployment target | 26.2 | As set in the pbxproj (Xcode 26). Confirm this is intended. |
| App icon | Empty `AppIcon` slots | No 1024×1024 images in `Assets.xcassets` |
| Localization | `en` / `Base` only | No `Localizable.xcstrings` yet |
| Privacy manifest | Stub only | Audit required-reason APIs (UserDefaults, file timestamps, etc.) on a Mac before submit |

---

## Remaining MVP gaps

- Week 1 is on `main`. Week 2 plus the 12 Nov 2026 catalog/pathways refresh is on `ship/week2-onto-main` and still needs a PR into `main` (none has been opened from this branch).
- No in-app catalog refresh / remote update path (data is compile-time bundled).
- SwiftData schema added optional College fields in Week 1; existing installs will migrate, but this was not run on a device.
- Counselor dashboard code remains in the tree but is unreachable from onboarding.
- Essay AI (`AIFeedbackService`) still present; not part of this ship.
- No L10n yet (English UI only) — Week 4 theme.
- Empty app icon.
- No entitlements / Push Notifications / iCloud capability wired in Xcode.
- `PrivacyInfo.xcprivacy` is a stub and has not been audited.
- Tests were written but **not executed** (no Xcode on this box).
- Pathway timelines are descriptive text, not auto-created `Deadline` rows (calendars change every year).

---

## Blockers that need Jian’s Mac / Apple ID

1. Open the project in Xcode, select a Development Team, and confirm the bundle ID (`edu.asu.jwang875.CollegeTracker` vs `com.jianwang.CollegeTracker`).
2. Signing & Capabilities: add **iCloud (CloudKit)** with container `iCloud.edu.asu.jwang875.CollegeTracker` (or the chosen replacement) and **Push Notifications** if CloudKit sync is wanted. This will create an entitlements file.
3. After this branch is on `main`, build and run: confirm both JSON files are in the app bundle, picker search works, and a catalog school’s Pathways tab shows official JUPAS / non-JUPAS or EJU routes plus type / tuition / majors, including one of the new HK013–HK021 schools.
4. Run `CollegeTrackerTests`.
5. Add a 1024×1024 App Store icon.
6. App Store Connect: create the app record for the chosen bundle ID (markets TBD; thesis is HK / Japan first, not a claim that listings exist).
7. Privacy Nutrition Labels + required-reason API audit before submission.

---

## Next 1–3 actions

1. **Jian:** open a pull request from `ship/week2-onto-main` into `main`. Then, on a Mac, choose the bundle ID; build this branch and smoke-test the Pathways tab for one HK school (including a new HK013–HK021 entry) and one Japan school.
2. **Week 3 candidate:** polish the student dashboard / progress / local notifications so they read well with JUPAS and EJU deadlines (not only ED/EA/RD).
3. **Later:** app icon, L10n (en / ja / zh-Hant), privacy and store drafts.

---

## Explicit non-claims

- No Xcode build, Simulator run, archive, TestFlight upload, or App Store Connect submission was performed.
- Catalog and pathway JSON were generated and inspected (839 colleges; 3,342 pathway rows = 3,276 Japan including JP_SYSTEM + 66 official HK including HK_SYSTEM; unique ids). Unit tests were added or updated but have not been executed here.
