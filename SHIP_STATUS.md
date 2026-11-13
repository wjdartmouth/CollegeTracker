# CollegeTracker ship status

**Thesis:** CollegeTracker is the mobile client for the [college-data](https://github.com/wjdartmouth/college-data) catalog (Hong Kong + Japan first). US Common App polish, counselor CloudKit sharing, and essay AI are deferred unless asked.

**Deadline:** Sunday 21 December 2026  
**Today (this update):** Friday 13 November 2026 (Asia/Hong_Kong) — 38 days left  
**Plan:** 6-week ship. Week 1 is on `main` ([PR #2](https://github.com/wjdartmouth/CollegeTracker/pull/2) merged). [PR #3](https://github.com/wjdartmouth/CollegeTracker/pull/3) (Week 2 pathways) landed only on `ship/week1-catalog`, not on `main`. Week 2 plus the 12 Nov catalog refresh lives on `ship/week2-onto-main` (no PR into `main` yet). This branch (`ship/week3-crm`) starts from that tip and adds Week 3 student CRM polish (dashboard, progress, local notifications). Calendar Week 1 runs through ~16 Nov; this work is ahead of the Week 3 window (~24–30 Nov).

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


## Week 3 (student CRM polish, 13 Nov 2026)

Week 3 theme is polish the student dashboard / progress / local notifications so they work for JUPAS and EJU (not only ED/EA/RD), and keep counselor gated. Branched from `ship/week2-onto-main`.

1. **Local notifications, no Critical Alerts**
   - Reminder sound is always `UNNotificationSound.default`. The previous 1-day and day-of path used `.defaultCritical`, which needs a Critical Alerts entitlement this app does not have and could prevent those reminders from scheduling.
   - Titles name the deadline type ("JUPAS in 1 week", "EJU is tomorrow") instead of a generic "deadline" label.
   - Reminders still fire at 9:00, 30 / 7 / 1 / 0 days before, only when that fire date is still in the future.
   - Opening the student tabs reschedules reminders for every incomplete upcoming deadline (covers permission granted later, or reminders lost after reinstall).
   - Completing a deadline cancels its reminders; un-completing schedules them again. Deleting a deadline from the context menu also cancels its reminders.
2. **Dashboard**
   - Stats are Schools / In Progress / Upcoming (incomplete deadlines from today onward).
   - Overdue deadlines get their own section.
   - If schools exist but no deadlines are set, a short prompt points at the JUPAS / EJU Deadlines tab and explains the 9:00 local reminders.
   - If notification permission was denied, a banner explains how to enable regular (not Critical Alert) reminders. The banner is hidden while permission is still undetermined so first launch does not flash a false warning.
3. **Progress**
   - Deadlines-by-month chart now groups and sorts chronologically (including year when the range crosses a year). The previous "MMM" string sort put April before January.
   - Replaced the "Essay Progress / AI Feedback Coverage" card with document progress (started vs total, plus JUPAS / personal statement / EJU counts). Essay AI stays in the tree but is not the Progress-tab center of gravity.
   - Overdue quick-stat uses start-of-day, consistent with the dashboard.
4. **Hygiene**
   - Removed leftover `CollegeTracker_README.md` so the repo has a single README.
   - Tests added for reminder identifiers/titles/lead times and for month-bucket / document-stat helpers. **Not executed here** (no Xcode on this box).

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

- Week 1 is on `main`. Week 2 (`ship/week2-onto-main`) and Week 3 (`ship/week3-crm`, includes Week 2) still need a pull request into `main` (none has been opened from these branches).
- No in-app catalog refresh / remote update path (data is compile-time bundled). college-data gained a 12 Nov Mainland China tuition/name polish after the last catalog refresh; that data is out of the HK+Japan MVP bundle and was not pulled in.
- SwiftData schema added optional College fields in Week 1; existing installs will migrate, but this was not run on a device.
- Counselor dashboard code remains in the tree but is unreachable from onboarding (Coming soon).
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
3. After this branch is on `main`, build and run: confirm both JSON files are in the app bundle, picker search works, a catalog school’s Pathways tab shows official JUPAS / non-JUPAS or EJU routes plus type / tuition / majors (including one of the new HK013–HK021 schools), and that adding a JUPAS or EJU deadline schedules regular 9:00 local reminders (no Critical Alerts prompt).
4. Run `CollegeTrackerTests` (catalog, pathways, reminder plan, CRM metrics).
5. Add a 1024×1024 App Store icon.
6. App Store Connect: create the app record for the chosen bundle ID (markets TBD; thesis is HK / Japan first, not a claim that listings exist).
7. Privacy Nutrition Labels + required-reason API audit before submission.

---

## Next 1–3 actions

1. **Jian:** open a pull request from `ship/week3-crm` into `main` (it includes Week 2 pathways plus this Week 3 CRM work). Then, on a Mac, choose the bundle ID; build and smoke-test Pathways for one HK school (including a new HK013–HK021 entry) and one Japan school, add a JUPAS or EJU deadline with notifications on, and confirm the dashboard / Progress tab.
2. Run `CollegeTrackerTests` in Xcode (including the new reminder and CRM metric tests).
3. **Week 4 candidate:** L10n (en / ja / zh-Hant), App Icon, PrivacyInfo audit, privacy policy and HK/JP store-listing drafts.

---

## Explicit non-claims

- No Xcode build, Simulator run, archive, TestFlight upload, or App Store Connect submission was performed.
- Catalog and pathway JSON were last generated on 12 Nov 2026 and inspected (839 colleges; 3,342 pathway rows = 3,276 Japan including JP_SYSTEM + 66 official HK including HK_SYSTEM; unique ids). Unit tests were added or updated (including Week 3 reminder and CRM metric tests) but have not been executed here.
