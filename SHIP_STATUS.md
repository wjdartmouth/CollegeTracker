# CollegeTracker ship status

**Thesis:** CollegeTracker is the mobile client for the [college-data](https://github.com/wjdartmouth/college-data) catalog (Hong Kong + Japan first). US Common App polish, counselor CloudKit sharing, and essay AI are deferred unless asked.

**Deadline:** Sunday 21 December 2026  
**Today (this update):** Wednesday 11 November 2026 (Asia/Hong_Kong) — 40 days left  
**Plan:** 6-week ship. Week 1 code is on `ship/week1-catalog` ([PR #2](https://github.com/wjdartmouth/CollegeTracker/pull/2)). Week 2 pathway work is on `ship/week2-pathways`, branched from Week 1.

This document is a code/repo status report. **This environment has no Mac Xcode.** Do not treat anything here as an Xcode build, Simulator, TestFlight, or App Store Connect success.

---

## Week 1 (done in code, not yet merged to `main`)

1. **Bundled HK + Japan catalog** — `universities_hk_japan_v1.json`, 830 schools (12 Hong Kong SAR + 818 Japan).
2. **Searchable add-college picker** with custom-entry fallback and duplicate catalog-id checks.
3. Empty `StudentDetailView.swift` stub deleted (real view lives in counselor code, which is gated).
4. CloudKit container renamed from `iCloud.com.yourname.collegetracker` to `iCloud.edu.asu.jwang875.CollegeTracker`. ModelContainer falls back to local SwiftData if CloudKit configuration fails.
5. Counselor gated as Coming soon; no fake local-UUID iCloud sharing.
6. Hygiene: `.gitignore` excludes `xcuserdata/`, single canonical `README.md`, stub `PrivacyInfo.xcprivacy`, catalog unit tests (not executed here).

See [PR #2](https://github.com/wjdartmouth/CollegeTracker/pull/2).

---

## Week 2 (done in code, 11 Nov 2026)

Week 2 theme is HK/JP pathway detail screens and region-aware deadline / document types. This was started during Week 1 calendar days because Week 1 code was already complete.

1. **Catalog facts on the school screen**
   - Regenerated `universities_hk_japan_v1.json` with `majors_faculties` and `admissions_notes` (still 830 schools; bundle is ~532 KB).
   - Detail header / Pathways tab shows type, founded year, approximate USD tuition, website, and faculties.
2. **Bundled admissions pathways**
   - New resource: `admissions_pathways_v1.json` (~2.6 MB, 3,296 rows, 831 ids).
   - Japan: joined from college-data `universities_japan_admissions_v1.csv` (4 student categories per school: domestic, EJU, international qualifications, overseas returnee), plus `JP_SYSTEM` national-norm fallback.
   - Hong Kong: structured JUPAS / Non-JUPAS (or direct application for self-financing schools) derived from catalog `admissions_notes` — college-data has no separate HK admissions CSV.
   - `AdmissionsStore` looks up by catalog id. International / EJU / Non-JUPAS rows are listed first.
3. **Pathways tab**
   - College detail now has Pathways | Deadlines | Documents | Notes.
   - Each pathway shows category, exams, typical timeline, language, notes (expandable), and confidence.
   - Copy states these are typical catalog routes, not official deadlines — verify JUPAS / the university guide / 募集要項.
4. **Region-aware deadline types**
   - Added JUPAS, Non-JUPAS, EJU, Common Test, Comprehensive (AO), School Recommendation. Existing ED/EA/RD values are unchanged so old records still decode.
   - Add-deadline and first-deadline pickers order types by the school's catalog region; HK defaults to JUPAS, Japan to EJU.
5. **Region-aware document types**
   - Added Personal Statement, JUPAS Application, School Report, EJU Scores. Common App types remain available at the end of the HK/JP lists.
6. **Regen script:** `scripts/generate_bundled_data.py` rebuilds both JSON files from a college-data checkout.
7. **Tests** added for pathway decode/lookup/fallback and region-aware type defaults. **Not executed here** (no Xcode on this box).

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

- `main` still does not include Week 1 or Week 2; merge [PR #2](https://github.com/wjdartmouth/CollegeTracker/pull/2) first, then the Week 2 PR.
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
3. Build and run `ship/week2-pathways` (it includes Week 1): confirm both JSON files are in the app bundle, picker search works, and a catalog school’s Pathways tab shows JUPAS or EJU routes plus type / tuition / majors.
4. Run `CollegeTrackerTests`.
5. Add a 1024×1024 App Store icon.
6. App Store Connect: create the app record for the chosen bundle ID (markets TBD; thesis is HK / Japan first, not a claim that listings exist).
7. Privacy Nutrition Labels + required-reason API audit before submission.

---

## Next 1–3 actions

1. **Jian (Mac):** merge or review [PR #2](https://github.com/wjdartmouth/CollegeTracker/pull/2), then the Week 2 PR; choose the bundle ID; build `ship/week2-pathways` and smoke-test the Pathways tab for one HK and one Japan school.
2. **Week 3 candidate:** polish the student dashboard / progress / local notifications so they read well with JUPAS and EJU deadlines (not only ED/EA/RD).
3. **Later:** app icon, L10n (en / ja / zh-Hant), privacy and store drafts.

---

## Explicit non-claims

- No Xcode build, Simulator run, archive, TestFlight upload, or App Store Connect submission was performed.
- Catalog and pathway JSON were generated and inspected (830 colleges; 3,296 pathway rows; unique ids). Unit tests were added but have not been executed here.
