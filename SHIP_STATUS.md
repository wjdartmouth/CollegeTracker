# CollegeTracker ship status

**Thesis:** CollegeTracker is the mobile client for the [college-data](https://github.com/wjdartmouth/college-data) catalog (Hong Kong + Japan first). US Common App polish, counselor CloudKit sharing, and essay AI are deferred unless asked.

**Deadline:** Sunday 21 December 2026
**Today (this update):** Tuesday 24 November 2026 — 27 days left. Weeks 1–4 are on `main` ([PR #5](https://github.com/wjdartmouth/CollegeTracker/pull/5), merge commit `10025473`). The 16 November Week 5 QA docs (`58d0e79`) are included here. This update is pre-TestFlight hardening. **GitHub Actions were explicitly skipped:** no workflow files were added or edited, and CI was not set up or waited on.
**Plan:** 6-week ship. Weeks 1–4 are on `main`.

This document is a code/repo status report. **This environment has no Mac Xcode.** Do not treat anything here as an Xcode build, Simulator, TestFlight, or App Store Connect success.

---

## Week 1 (merged to `main`, PR #2)

1. **Bundled HK + Japan catalog** — originally 830 schools (12 Hong Kong SAR + 818 Japan); later refreshed (see Week 2).
2. **Searchable add-college picker** with custom-entry fallback and duplicate catalog-id checks.
3. Empty `StudentDetailView.swift` stub deleted (real view lives in counselor code, which is gated).
4. CloudKit container renamed from `iCloud.com.yourname.collegetracker` to `iCloud.edu.asu.jwang875.CollegeTracker`. ModelContainer falls back to local SwiftData if CloudKit configuration fails.
5. Counselor gated as Coming soon; no fake local-UUID iCloud sharing.
6. Hygiene: `.gitignore` excludes `xcuserdata/`, single canonical `README.md`, stub `PrivacyInfo.xcprivacy`, catalog unit tests (not executed here).

See [PR #2](https://github.com/wjdartmouth/CollegeTracker/pull/2) (merged to `main` on 11 November 2026).

---

## Week 2 (on `main` via the Week 3 merge path)

Week 2 theme is HK/JP pathway detail screens and region-aware deadline / document types. The original Week 2 commit lived on `ship/week2-pathways` and was first merged only into `ship/week1-catalog` via [PR #3](https://github.com/wjdartmouth/CollegeTracker/pull/3). It reached `main` with the Week 3 work.

1. **Catalog facts on the school screen**
   - Regenerated `universities_hk_japan_v1.json` with `majors_faculties` and `admissions_notes`: **839 schools (21 Hong Kong SAR + 818 Japan)**.
   - New Hong Kong schools HK013–HK021: Saint Francis University, THEi, Tung Wah College, UOW College Hong Kong, Gratia Christian College, HKCT Institute of Higher Education, Hong Kong Nang Yan College of Higher Education, Yew Chung College of Early Childhood Education, and The Hong Kong Academy for Performing Arts.
   - Detail header / Pathways tab shows type, founded year, approximate USD tuition, website, and faculties.
2. **Bundled admissions pathways**
   - Resource: `admissions_pathways_v1.json` (~2.8 MB, 3,342 rows, 841 ids).
   - Japan: joined from college-data `universities_japan_admissions_v1.csv` (4 student categories per school: domestic, EJU, international qualifications, overseas returnee), plus `JP_SYSTEM` national-norm fallback.
   - Hong Kong: official `universities_hk_admissions_v1.csv` (66 rows: 3 categories × 21 schools, plus 3 `HK_SYSTEM` fallback rows). Categories are `jupas_local`, `non_jupas_local`, and `international_non_jupas`.
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

## Week 3 (student CRM polish, merged to `main`, PR #4, 13 Nov 2026)

Week 3 theme is polish the student dashboard / progress / local notifications so they work for JUPAS and EJU (not only ED/EA/RD), and keep counselor gated.

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

See [PR #4](https://github.com/wjdartmouth/CollegeTracker/pull/4) (merged to `main` on 13 November 2026).

---

## Week 4 (localization, icon, privacy, store drafts — merged to `main`, PR #5, 16 Nov 2026)

Week 4 prepared the student app for an HK/Japan listing: English, Japanese, and Traditional Chinese; an App Store icon; an audited privacy manifest; and drafts to paste into App Store Connect. Branched from `main` at `47688e4`. Jian merged [PR #5](https://github.com/wjdartmouth/CollegeTracker/pull/5) at 07:41 HKT on 16 November 2026 (merge commit `10025473`).

1. **Localization**
   - `CollegeTracker/Localizable.xcstrings` — English source keys with complete `ja` and `zh-Hant`. No `zh-Hans`.
   - `CollegeTracker/InfoPlist.xcstrings` — display name only: College Tracker / 進学トラッカー / 升學追蹤. No protected-resource usage strings (none apply; see the privacy audit).
   - `CollegeTracker/Shared/L10n.swift` — UI, notification titles, and the existing region-aware JUPAS / EJU wording go through the catalog. Stored enum raw values are unchanged, so old SwiftData records still decode.
   - Project `knownRegions` includes `ja` and `zh-Hant`.
   - `LocalizationCatalogTests` checks that every catalog key has en / ja / `zh-Hant` and that status, deadline, document, pathway, and reminder keys are present. **Not executed here.**
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
   - `Store/WEEK5_MAC_CHECKLIST.md` — Mac checklist only. Nothing on it was run in Week 4.
5. **Not done in Week 4:** no Xcode build, Simulator, privacy report, TestFlight, or App Store Connect session. Bundle ID and CloudKit container were not rewritten.

---

## Week 5 (started 16 Nov 2026, ahead of the ~8–14 Dec window)

Week 5 theme is an end-to-end QA checklist, Mac / TestFlight steps for Jian, and bug fixes. This update is documentation only.

1. **Status refresh** — this file now records PR #5 on `main` and the 35-day countdown.
2. **End-to-end QA list** — `Store/WEEK5_QA_CHECKLIST.md` covers the student MVP flows to tick on a device or Simulator. None of those checks were run here.
3. **Mac checklist** — `Store/WEEK5_MAC_CHECKLIST.md` intro updated so it starts from current `main` (`10025473`), not from an unmerged Week 4 branch.
4. **college-data** — `main` is `eb07b17a` (13 November 2026). Commits since the 12 November catalog regen are Mainland China tuition, names, and websites. That data stays out of the HK + Japan MVP bundle. Last bundled HK/JP refresh already includes HK013–HK021 / HKAPA. No catalog regen in this update.
5. **Still not done here:** no Xcode build, Simulator language pass, unit-test run, privacy report, TestFlight upload, or App Store Connect session.

---

## Pre-TestFlight hardening (24 Nov 2026)

Branched from `ship/week5-qa-docs` (`58d0e79`). That commit was a clean fast-forward of `main` (`10025473`): Week 5 checklists and this status file only. Those docs are in this branch so the pull request into `main` brings them along.

GitHub Actions were explicitly skipped. Nothing under `.github/workflows` was added, edited, or enabled. CI was not set up and was not waited on.

1. **Essay AI is not in the v1 UI**
   - `EssayFeedbackView` stays in the tree and is not presented. An essay-shaped document shows a non-interactive **AI Feedback · Coming soon** banner, the same idea as the counselor gate.
   - The document vault no longer nudges students to request feedback, and document rows no longer show a sparkles count.
   - `AIFeedbackService.networkEnabled` is `false`. `getFeedback` throws before `URLSession`, so the POST to `api.anthropic.com` does not run.
   - `NSPrivacyCollectedDataTypeOtherUserContent` was removed. `NSPrivacyCollectedDataTypes` is empty. `Store/APP_PRIVACY.md` and `Store/PRIVACY_POLICY.md` match that.
2. **Settings tab**
   - Reminder status: On, Off, or Not yet asked. If iOS has not asked, the student can turn reminders on from here. If iOS has denied them, the button opens iOS Settings. Launch still requests permission, as in Week 3.
   - The dashboard “reminders are off” banner opens this tab.
   - In-app privacy policy (no postal address, no invented Japanese business address).
   - Version row reads the bundle short version and build (`1.0 (1)` in the project file).
   - New strings are in `Localizable.xcstrings` for English, Japanese, and Traditional Chinese. No `zh-Hans`.
3. **Notification taps open the school**
   - Before this change, `NotificationDelegate` only presented a banner in the foreground. The payload had a deadline id and nothing consumed it.
   - Reminders now store `deadlineID` and `collegeID`. A tap switches to Colleges and pushes that school’s Deadlines section, scrolling to the deadline when it is still on the phone. Dashboard deadline cards open the same place.
4. **Small student-flow polish**
   - Colleges and Documents distinguish “nothing here yet” from “nothing matched the search”. Progress has an empty state when there are no schools.
   - Accessibility labels on the school overflow menu, the notes field, deadline cards, and the reminders-off banner.
5. **Not done here:** no Xcode build, Simulator, unit-test execution, privacy report, TestFlight, or App Store Connect session. Bundle ID `edu.asu.jwang875.CollegeTracker` and CloudKit container `iCloud.edu.asu.jwang875.CollegeTracker` were not rewritten. Mainland China catalog data was not pulled. Counselor stays Coming soon. Notifications stay regular local alerts, not Critical Alerts. No in-app purchase.

---

## Identifiers (confirm before ASC)

| Item | Current value in repo | Note |
|------|------------------------|------|
| App bundle ID | `edu.asu.jwang875.CollegeTracker` | Unchanged. Do not rewrite it after the App Store Connect record exists. |
| CloudKit container | `iCloud.edu.asu.jwang875.CollegeTracker` | Unchanged. **No `.entitlements` file and no iCloud capability in the pbxproj yet.** |
| Suggested alternative | `com.jianwang.CollegeTracker` / `iCloud.com.jianwang.CollegeTracker` | Only switch if Jian wants a personal team ID before creating the App Store Connect record. Changing later is painful. |
| Development Team | not set in the pbxproj | Must be selected on a Mac. |
| iOS deployment target | 26.2 | As set in the pbxproj (Xcode 26). Confirm this is intended. README previously said 17.0; 17+ is the API floor, 26.2 is the current project setting. |
| App icon | 1024×1024 light, dark, tinted | `AppIcon.appiconset`. Not viewed on a device. |
| Localization | `en`, `ja`, `zh-Hant` | `Localizable.xcstrings` and `InfoPlist.xcstrings`. No zh-Hans. |
| Privacy manifest | No collected data types | Essay AI POST is not reachable. `PrivacyInfo.xcprivacy` and `Store/APP_PRIVACY.md`. Xcode privacy report not run. |

---

## Remaining MVP gaps

- Weeks 1–4 are on `main` (`10025473`). This branch adds the Week 5 checklists and the 24 Nov hardening. It is not merged. Mac / TestFlight work has not started.
- GitHub Actions remain unset on purpose. Do not treat a missing workflow as an oversight for this pass.
- No in-app catalog refresh / remote update path (data is compile-time bundled). college-data gained Mainland China tuition/name polish on 12–13 November after the last catalog refresh; that data is out of the HK+Japan MVP bundle and was not pulled in.
- SwiftData schema added optional College fields in Week 1; existing installs will migrate, but this was not run on a device.
- Counselor dashboard code remains in the tree but is unreachable from onboarding (Coming soon). Copy is localized.
- Essay AI source remains in the tree and is unreachable in the shipping UI. The network call does not run. The privacy manifest no longer declares Other User Content. Do not flip `AIFeedbackService.networkEnabled` or reattach the screen without putting that collected-data type back.
- Settings (reminders, privacy policy, version) is in the student tabs. It has not been smoke-tested in Xcode.
- Localization and the app icon are in the repo. They have not been smoke-tested in Xcode.
- No entitlements / Push Notifications / iCloud capability wired in Xcode. Development Team is unset.
- Tests were written but **not executed** (no Xcode on this box), including the string-catalog tests and the new essay-AI / notification-payload / privacy-manifest tests.
- Pathway timelines are descriptive text, not auto-created `Deadline` rows (calendars change every year).
- Store listing, privacy policy, and App Privacy answers are drafts under `Store/`. They have not been pasted into App Store Connect. The privacy policy has no hosted URL yet. The in-app policy is the student-readable copy and matches the “data not collected” draft.

---

## Blockers that need Jian’s Mac / Apple ID

1. Open the project in Xcode, select a Development Team, and confirm the bundle ID stays `edu.asu.jwang875.CollegeTracker` unless you deliberately choose otherwise **before** creating the App Store Connect record.
2. Signing & Capabilities: add **iCloud (CloudKit)** with container `iCloud.edu.asu.jwang875.CollegeTracker` (or the chosen replacement) and **Push Notifications** only if CloudKit sync needs it. This will create an entitlements file. Do not enable Critical Alerts.
3. Build and run from current `main`: confirm both JSON files are in the app bundle, picker search works, a catalog school’s Pathways tab shows official JUPAS / non-JUPAS or EJU routes plus type / tuition / majors (including one of the new HK013–HK021 schools), and that adding a JUPAS or EJU deadline schedules regular 9:00 local reminders (no Critical Alerts prompt). Repeat in English, Japanese, and Traditional Chinese.
4. Run `CollegeTrackerTests` (catalog, pathways, reminder plan, CRM metrics, string catalog, essay-AI gate, notification payload, privacy manifest).
5. Confirm the 1024×1024 icon on the home screen (light, dark, tinted). The images are already in the asset catalog.
6. App Store Connect: create the app record for the confirmed bundle ID. Paste `Store/APP_STORE_LISTING.md`. Host `Store/PRIVACY_POLICY.md` first.
7. Generate an Xcode privacy report and match it to `PrivacyInfo.xcprivacy` and `Store/APP_PRIVACY.md` before submission.

The Mac steps are `Store/WEEK5_MAC_CHECKLIST.md`. The student-flow ticks are `Store/WEEK5_QA_CHECKLIST.md`. Checking an item there means you did it on a Mac. This file does not.

---

## Next 1–3 actions

1. Review this pull request into `main`. It includes the Week 5 checklists and the 24 Nov hardening. Do not merge it from this environment.
2. On a Mac, work through `Store/WEEK5_MAC_CHECKLIST.md` and `Store/WEEK5_QA_CHECKLIST.md`: team, bundle ID, CloudKit capability, en/ja/zh-Hant smoke test (including Settings), local notifications and a reminder tap, unit tests, privacy report, TestFlight. Leave GitHub Actions off for this pass.
3. Confirm the bundle ID stays `edu.asu.jwang875.CollegeTracker` before creating the App Store Connect record. App Privacy answers are now **Data Not Collected**.

---

## Explicit non-claims

- No Xcode build, Simulator run, archive, TestFlight upload, or App Store Connect submission was performed.
- GitHub Actions were not added, edited, enabled, or waited on.
- Catalog and pathway JSON were last generated on 12 November 2026 and inspected (839 colleges; 3,342 pathway rows = 3,276 Japan including JP_SYSTEM + 66 official HK including HK_SYSTEM; unique ids). Unit tests were added or updated (including Week 3 reminder and CRM metric tests, Week 4 string-catalog tests, and 24 Nov essay-AI, notification-payload, and privacy-manifest tests) but have not been executed here.
- The app icon was drawn and placed in the asset catalog. It was not installed on a device.
- Store listing and privacy documents are drafts in `Store/`. They were not submitted.
