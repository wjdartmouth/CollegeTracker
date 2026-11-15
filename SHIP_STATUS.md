# CollegeTracker ship status

**Thesis:** CollegeTracker is the mobile client for the [college-data](https://github.com/wjdartmouth/college-data) catalog (Hong Kong + Japan first). US Common App polish, counselor CloudKit sharing, and essay AI are deferred unless asked.

**Deadline:** Sunday 21 December 2026  
**Today (this update):** Sunday 15 November 2026 (Asia/Hong_Kong) — 36 days left. Week 4 is this branch, off `main` at `47688e4` (Weeks 1–3 are already on `main`).  
**Plan:** 6-week ship. Week 1 is on `main` ([PR #2](https://github.com/wjdartmouth/CollegeTracker/pull/2) merged). [PR #3](https://github.com/wjdartmouth/CollegeTracker/pull/3) (Week 2 pathways) landed only on `ship/week1-catalog`, not on `main`. Week 2 plus the 12 Nov catalog refresh lives on `ship/week2-onto-main` (no PR into `main` yet). This branch (`ship/week3-crm`) starts from that tip and adds Week 3 student CRM polish (dashboard, progress, local notifications). Calendar Week 1 runs through ~16 Nov; this work is ahead of the Week 3 window (~24–30 Nov).

The paragraph above is the 13 November history of how Weeks 2 and 3 were branched. It is kept as written. Those branches have since merged to `main`.

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

## Week 4 (localization, icon, privacy, store drafts — 15 Nov 2026)

Week 4 prepares the student app for an HK/Japan listing: English, Japanese, and Traditional Chinese; an App Store icon; an audited privacy manifest; and drafts Jian can paste into App Store Connect. Branched from `main` at `47688e4`. Not merged.

1. **Localization**
   - `CollegeTracker/Localizable.xcstrings` — English source keys with complete `ja` and `zh-Hant`. No `zh-Hans`.
   - `CollegeTracker/InfoPlist.xcstrings` — display name only: College Tracker / 進学トラッカー / 升學追蹤. No protected-resource usage strings (none apply; see the privacy audit).
   - `CollegeTracker/Shared/L10n.swift` — UI, notification titles, and the existing region-aware JUPAS / EJU wording go through the catalog. Stored enum raw values are unchanged, so old SwiftData records still decode.
   - Project `knownRegions` includes `ja` and `zh-Hant`.
   - `LocalizationCatalogTests` checks that every catalog key has en / ja / zh-Hant and that status, deadline, document, pathway, and reminder keys are present. **Not executed here.**
2. **App icon**
   - Original 1024×1024 light, dark, and tinted PNGs in `CollegeTracker/Assets.xcassets/AppIcon.appiconset/`, named from `Contents.json`. The target already set `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`.
   - iOS 26 uses that single size. This catalog did not have legacy 20/29/40 pt slots, and none were added.
3. **PrivacyInfo**
   - `CollegeTracker/PrivacyInfo.xcprivacy` audited against the source. Required-reason API list stays empty: this target does not call UserDefaults, file-timestamp APIs, boot time, disk space, or active keyboards.
   - One collected type: Other User Content, not linked, not tracking, app functionality. That is the reachable AI Feedback POST of essay text to `api.anthropic.com` (no API key is bundled). On-device SwiftData and optional private CloudKit are not declared as collected.
   - Details and the App Privacy answers: `Store/APP_PRIVACY.md`.
4. **Store drafts** (not pasted into App Store Connect)
   - `Store/APP_STORE_LISTING.md` — name, subtitle, keywords, description, what’s new, for en / ja / zh-Hant.
   - `Store/PRIVACY_POLICY.md` — HK PDPO and Japan APPI draft. Free app, no IAP, no invented Japanese business address. 特定商取引法 is noted only as a later paid/IAP requirement.
   - `Store/WEEK5_MAC_CHECKLIST.md` — Mac checklist only. Nothing on it was run.
5. **Not done here:** no Xcode build, Simulator, privacy report, TestFlight, or App Store Connect session. Bundle ID and CloudKit container were not rewritten.

---

## Identifiers (confirm before ASC)

| Item | Current value in repo | Note |
|------|------------------------|------|
| App bundle ID | `edu.asu.jwang875.CollegeTracker` | Unchanged. Do not rewrite it after the App Store Connect record exists. |
| CloudKit container | `iCloud.edu.asu.jwang875.CollegeTracker` | Unchanged. **No `.entitlements` file and no iCloud capability in the pbxproj yet.** |
| Suggested alternative | `com.jianwang.CollegeTracker` / `iCloud.com.jianwang.CollegeTracker` | Only switch if Jian wants a personal team ID before creating the App Store Connect record. Changing later is painful. |
| iOS deployment target | 26.2 | As set in the pbxproj (Xcode 26). Confirm this is intended. |
| App icon | 1024×1024 light, dark, tinted | `AppIcon.appiconset`. Not viewed on a device. |
| Localization | `en`, `ja`, `zh-Hant` | `Localizable.xcstrings` and `InfoPlist.xcstrings`. No zh-Hans. |
| Privacy manifest | Audited in-repo | `PrivacyInfo.xcprivacy` and `Store/APP_PRIVACY.md`. Xcode privacy report not run. |

---

## Remaining MVP gaps

- Weeks 1–3 are on `main` (`47688e4`). Week 4 is this branch and still needs review; it is not merged.
- No in-app catalog refresh / remote update path (data is compile-time bundled). college-data gained a 12 Nov Mainland China tuition/name polish after the last catalog refresh; that data is out of the HK+Japan MVP bundle and was not pulled in.
- SwiftData schema added optional College fields in Week 1; existing installs will migrate, but this was not run on a device.
- Counselor dashboard code remains in the tree but is unreachable from onboarding (Coming soon). Copy is localized.
- Essay AI (`AIFeedbackService`) still present and still reachable from a document. It is not a marketed v1 feature. The privacy manifest declares the essay POST. Remove the screen before submission if it should not ship, and then remove that collected-data entry.
- Localization and the app icon are in the repo. They have not been smoke-tested in Xcode.
- No entitlements / Push Notifications / iCloud capability wired in Xcode.
- Tests were written but **not executed** (no Xcode on this box), including the new string-catalog tests.
- Pathway timelines are descriptive text, not auto-created `Deadline` rows (calendars change every year).
- Store listing, privacy policy, and App Privacy answers are drafts under `Store/`. They have not been pasted into App Store Connect. The privacy policy has no hosted URL yet.

---

## Blockers that need Jian’s Mac / Apple ID

1. Open the project in Xcode, select a Development Team, and confirm the bundle ID stays `edu.asu.jwang875.CollegeTracker` unless you deliberately choose otherwise **before** creating the App Store Connect record.
2. Signing & Capabilities: add **iCloud (CloudKit)** with container `iCloud.edu.asu.jwang875.CollegeTracker` (or the chosen replacement) and **Push Notifications** only if CloudKit sync needs it. This will create an entitlements file. Do not enable Critical Alerts.
3. After this branch is on `main`, build and run: confirm both JSON files are in the app bundle, picker search works, a catalog school’s Pathways tab shows official JUPAS / non-JUPAS or EJU routes plus type / tuition / majors (including one of the new HK013–HK021 schools), and that adding a JUPAS or EJU deadline schedules regular 9:00 local reminders (no Critical Alerts prompt). Repeat in English, Japanese, and Traditional Chinese.
4. Run `CollegeTrackerTests` (catalog, pathways, reminder plan, CRM metrics, string catalog).
5. Confirm the 1024×1024 icon on the home screen (light, dark, tinted). The images are already in the asset catalog.
6. App Store Connect: create the app record for the confirmed bundle ID. Paste `Store/APP_STORE_LISTING.md`. Host `Store/PRIVACY_POLICY.md` first.
7. Generate an Xcode privacy report and match it to `PrivacyInfo.xcprivacy` and `Store/APP_PRIVACY.md` before submission.

The step-by-step list is `Store/WEEK5_MAC_CHECKLIST.md`. Checking an item there means you did it on a Mac. This file does not.

---

## Next 1–3 actions

1. Review and merge the Week 4 pull request into `main`.
2. On a Mac, work through `Store/WEEK5_MAC_CHECKLIST.md`: team, bundle ID, CloudKit capability, en/ja/zh-Hant smoke test, local notifications, privacy report, TestFlight.
3. Decide whether AI Feedback ships. If it does not, remove the screen and the Other User Content entry before the TestFlight build you care about.

---

## Explicit non-claims

- No Xcode build, Simulator run, archive, TestFlight upload, or App Store Connect submission was performed.
- Catalog and pathway JSON were last generated on 12 Nov 2026 and inspected (839 colleges; 3,342 pathway rows = 3,276 Japan including JP_SYSTEM + 66 official HK including HK_SYSTEM; unique ids). Unit tests were added or updated (including Week 3 reminder and CRM metric tests, and Week 4 string-catalog tests) but have not been executed here.
- The app icon was drawn and placed in the asset catalog. It was not installed on a device.
- Store listing and privacy documents are drafts in `Store/`. They were not submitted.
