# CollegeTracker ship status

**Thesis:** CollegeTracker is the mobile client for the [college-data](https://github.com/wjdartmouth/college-data) catalog (Hong Kong + Japan first). US Common App polish, counselor CloudKit sharing, and essay AI are deferred unless asked.

**Deadline:** Sunday 21 December 2026  
**Today (this update):** Tuesday 10 November 2026 (Asia/Hong_Kong) — 41 days left  
**Plan:** 6-week ship, Week 1 in progress on `ship/week1-catalog`

This document is a code/repo status report. **This environment has no Mac Xcode.** Do not treat anything here as an Xcode build, Simulator, TestFlight, or App Store Connect success.

---

## Week 1 (done in code)

1. **Bundled HK + Japan catalog**
   - Resource: `CollegeTracker/Resources/universities_hk_japan_v1.json`
   - Generated 2026-11-10 from `college-data/universities_hk_japan_v1.csv`
   - 830 schools (12 Hong Kong SAR + 818 Japan)
   - Trimmed fields: `id`, `official_english_name`, `local_native_name`, `city`, `country_region`, `website`, `type`, `founded_year`, `qs_wur_rank`, `qs_rank_year`, `tuition_approx_usd`, `tuition_currency`
   - Long notes (`tuition_notes`, `majors_faculties`, `admissions_notes`, `data_confidence_notes`) were omitted to keep the bundle ~299 KB vs the 656 KB CSV
2. **Models + store**
   - `CatalogCollege` / `CollegeCatalogFile` (`Models/CatalogCollege.swift`)
   - `CollegeCatalogStore` loads the JSON and searches by English name, native name, city, region, type, and catalog id
   - SwiftData `College` now stores optional `catalogId`, `city`, `countryRegion`, `localNativeName`, `qsRankText`
3. **Searchable add-college picker**
   - Add flow starts with `CatalogCollegePicker` (region chips + search)
   - Selecting a row fills name, catalog id, location, website/portal URL, and QS rank
   - Custom-entry fallback: “School not listed? Add custom”
   - Duplicate catalog ids (or custom names) are blocked
4. **Empty `StudentDetailView.swift` stub deleted**
   - The real `StudentDetailView` already lived in `CounselorDashboardView.swift` (gated; see below)
5. **CloudKit / bundle naming**
   - Existing Xcode `PRODUCT_BUNDLE_IDENTIFIER`: `edu.asu.jwang875.CollegeTracker` (left unchanged for consistency)
   - `CloudKitService` no longer uses `iCloud.com.yourname.collegetracker`
   - Container is now `iCloud.edu.asu.jwang875.CollegeTracker`
   - README placeholders updated to match
   - ModelContainer falls back to local-only SwiftData if automatic CloudKit configuration fails (no entitlements file in the project yet)
6. **Counselor gated**
   - Onboarding shows Counselor as **Coming soon** (not selectable)
   - New profiles are always created as students
   - An existing counselor profile sees `CounselorComingSoonView` instead of student-management tabs (no local-UUID “iCloud sharing”)
   - Add-student copy no longer claims fake iCloud sync
7. **Hygiene**
   - `.gitignore` now excludes `xcuserdata/`
   - Committed `CollegeTracker.xcodeproj/xcuserdata` removed
   - `CollegeTracker_README.md` is a pointer; `README.md` is canonical
   - Added `PrivacyInfo.xcprivacy` stub (`NSPrivacyTracking = false`, empty API/data arrays)
   - Unit tests added for catalog decode + search (`CollegeTrackerTests`)

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

## Remaining Week 1 / MVP gaps

- Japan admissions detail CSV (`universities_japan_admissions_v1.csv`, ~2.8 MB) is **not** bundled; join-by-id detail UI is future work
- UK / US catalogs are deferred (thesis: HK + Japan first)
- Catalog picker does not yet show majors or admissions notes (trimmed out of the JSON)
- No in-app catalog refresh / remote update path (data is compile-time bundled)
- SwiftData schema added optional College fields; existing installs will migrate, but this was not run on a device
- Counselor dashboard code remains in the tree but is unreachable from onboarding
- Essay AI (`AIFeedbackService`) still present; not part of Week 1 polish
- Deadline types still lean US Common App (ED/EA/RD) — acceptable for now, not HK/JP-specific (JUPAS, EJU, etc.)
- No L10n (English UI only)
- Empty app icon
- No entitlements / Push Notifications / iCloud capability wired in Xcode
- `PrivacyInfo.xcprivacy` is a stub and has not been audited
- Tests were written but **not executed** (no Xcode on this box)
- Duplicate README is now a stub pointer; content lives in `README.md`

---

## Blockers that need Jian’s Mac / Apple ID

1. Open the project in Xcode, select a Development Team, and confirm the bundle ID (`edu.asu.jwang875.CollegeTracker` vs `com.jianwang.CollegeTracker`).
2. Signing & Capabilities: add **iCloud (CloudKit)** with container `iCloud.edu.asu.jwang875.CollegeTracker` (or the chosen replacement) and **Push Notifications** if CloudKit sync is wanted. This will create an entitlements file.
3. Build and run on a simulator / device: confirm the catalog JSON is copied into the app bundle (file-system synchronized group should pick up `Resources/`), picker search works, and a catalog school saves with id/city/region.
4. Run `CollegeTrackerTests`.
5. Add a 1024×1024 App Store icon.
6. App Store Connect: create the app record for the chosen bundle ID (markets TBD; thesis is HK / Japan first, not a claim that listings exist).
7. Privacy Nutrition Labels + required-reason API audit before submission.

---

## Next 1–3 actions

1. **Jian (Mac):** choose bundle ID, enable CloudKit capability, build the `ship/week1-catalog` branch, smoke-test the picker.
2. **Week 2 candidate:** surface catalog fields on detail (website, type, founded year, tuition USD) and/or a lightweight Japan admissions join if size allows.
3. **Week 2 candidate:** real app icon + decide whether student-only iCloud sync (SwiftData `.automatic`) is in v1 or local-only until signing is ready.

---

## Explicit non-claims

- No Xcode build, Simulator run, archive, TestFlight upload, or App Store Connect submission was performed.
- Catalog search/decode was validated by generating/inspecting the JSON (830 rows, unique ids) and by adding unit tests that have not been executed here.
