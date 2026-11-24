# Week 5 end-to-end QA checklist

Student MVP flows to tick on a device or Simulator after a signed build from current `main` (`10025473`). Signing, CloudKit capability, privacy report, and TestFlight steps are in [`WEEK5_MAC_CHECKLIST.md`](WEEK5_MAC_CHECKLIST.md).

This environment has no Xcode. **None of the boxes below have been checked here.** Check a box only after you see the behavior on a Mac.

The catalog under test is the 12 November 2026 bundle: 839 schools (21 Hong Kong SAR + 818 Japan) and 3,342 pathway rows. Do not expect Mainland China schools from later college-data commits.

---

## 1. Onboarding and counselor gate

- [ ] First launch asks for a name and offers Student, plus Counselor marked Coming soon.
- [ ] Continuing as Student reaches the student tabs (Dashboard, Colleges, Documents, Progress, Settings).
- [ ] The Counselor chip cannot start a counselor session from onboarding.
- [ ] If an existing counselor profile is present, the gate explains that CloudKit sharing is deferred and **Continue as student** switches the profile to student.

## 2. Catalog add and school screen

- [ ] Colleges → add opens the searchable catalog picker (not a free-text-only form). Region chips can narrow to Hong Kong or Japan.
- [ ] Search finds a well-known HK school and a well-known Japan school.
- [ ] Adding an HK013–HK021 school works (for example The Hong Kong Academy for Performing Arts).
- [ ] Adding the same catalog school twice is blocked (duplicate catalog id).
- [ ] Custom entry still works for a school that is not in the catalog.
- [ ] School detail has Pathways | Deadlines | Documents | Notes.
- [ ] Pathways show category, exams, typical timeline, language, expandable notes, and confidence.
- [ ] Disclaimer is visible: these are typical catalog routes, not official deadlines — verify JUPAS / the university guide / 募集要項.
- [ ] Header / Pathways facts include type, founded year, approximate USD tuition, website, and faculties when the catalog has them.
- [ ] An HK school lists official JUPAS / Non-JUPAS (and international) routes. A Japan school lists EJU (and the other catalog categories).

## 3. Deadlines, documents, and region defaults

- [ ] Adding a deadline on an HK school defaults the type to JUPAS. On a Japan school it defaults to EJU.
- [ ] HK type list leads with JUPAS / Non-JUPAS; Japan leads with EJU / Common Test / Comprehensive (AO) / School Recommendation. ED/EA/RD remain available.
- [ ] Document types include Personal Statement, JUPAS Application, School Report, and EJU Scores, with Common App types still at the end of the list.
- [ ] Completing a deadline, then un-completing it, updates the dashboard / progress counts as expected.
- [ ] Deleting a deadline from the context menu removes it from the list.

## 4. Dashboard and progress

- [ ] Empty library (no schools) is understandable; it does not look broken.
- [ ] With schools but no deadlines, a prompt points at the JUPAS / EJU Deadlines tab and mentions 9:00 local reminders.
- [ ] Stats are Schools / In Progress / Upcoming (incomplete deadlines from today onward).
- [ ] An incomplete deadline in the past appears under Overdue on the dashboard. The progress overdue stat matches (start-of-day).
- [ ] Progress shows a status breakdown, deadlines grouped by month in calendar order (not April-before-January string sort), and document progress (started vs total, including JUPAS / personal statement / EJU counts). Essay AI coverage is not the center of the tab.

## 5. Local notifications (no Critical Alerts)

- [ ] The system prompt is the ordinary notification prompt, not Critical Alerts.
- [ ] With permission allowed and “Notify me” on, a future JUPAS or EJU deadline schedules regular alerts at 9:00 local time, 30 / 7 / 1 / 0 days ahead, only for fire dates still in the future. The sound is the default sound.
- [ ] Reminder titles name the type (for example “JUPAS in 1 week”, “EJU is tomorrow”).
- [ ] Completing a deadline cancels its pending reminders. Un-completing schedules them again. Deleting a deadline cancels them.
- [ ] Opening the student tabs reschedules reminders for incomplete upcoming deadlines (permission granted later, or reminders lost after reinstall).
- [ ] If permission is denied, the dashboard banner explains how to enable regular reminders and opens the in-app Settings tab. The banner does not appear while permission is still undetermined (first launch).
- [ ] Settings shows On, Off, or Not yet asked. Off offers a button that opens iOS Settings. Not yet asked can request permission. These stay regular notifications, not Critical Alerts.
- [ ] Tapping a delivered reminder opens Colleges on that school’s Deadlines section. A deadline card on the dashboard opens the same place.

## 6. Documents, essay AI, and Settings

- [ ] The document vault lists documents across schools and can open the editor with a live word count when a limit is set.
- [ ] An essay-shaped document shows AI Feedback as Coming soon. It does not open a feedback screen and does not send the essay anywhere. The vault does not nudge you to request AI feedback.
- [ ] Settings includes a privacy policy you can read in the app, and a version row. The policy does not list a postal address.
- [ ] `PrivacyInfo.xcprivacy` has an empty collected-data list (no Other User Content). Confirm the Xcode privacy report matches `Store/APP_PRIVACY.md` on the Mac checklist.

## 7. Localization and icon

- [ ] English, Japanese, and Traditional Chinese schemes each show translated onboarding, tabs (including Settings), catalog picker, pathway disclaimer, empty-deadline copy, the in-app privacy policy, and (if triggered) the notification-denied banner and a reminder title.
- [ ] Home-screen name is College Tracker / 進学トラッカー / 升學追蹤 in those languages. Do not add a Simplified Chinese scheme for this pass.
- [ ] Home-screen icon renders in light, dark, and tinted modes from the 1024×1024 asset catalog images.

## 8. Automated tests

- [ ] `CollegeTrackerTests` pass: catalog, pathways, reminder plan, CRM metrics, string-catalog completeness (en / ja / zh-Hant), the essay-AI gate, notification payload round-trip, and the privacy manifest having no collected types.

If a box fails, note the build, language, and steps in the pull request or in `SHIP_STATUS.md`. Do not mark this checklist done from a repo-only reading.
