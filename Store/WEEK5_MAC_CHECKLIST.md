# Week 5 Mac / Xcode checklist

Checklist only. None of these steps have been run in this environment. There is no Xcode, Simulator, TestFlight, or App Store Connect session here.

Do them on a Mac against current `main` (Week 4, [PR #5](https://github.com/wjdartmouth/CollegeTracker/pull/5), merge commit `10025473`). Use the bundle ID you confirm in step 1. Do not change the bundle ID after the App Store Connect record exists.

Student-flow ticks that are not signing or upload steps live in [`WEEK5_QA_CHECKLIST.md`](WEEK5_QA_CHECKLIST.md).

1. Open `CollegeTracker.xcodeproj` in Xcode. Confirm the target bundle ID is still `edu.asu.jwang875.CollegeTracker`. Confirm the CloudKit container string in code is still `iCloud.edu.asu.jwang875.CollegeTracker`.
2. Select the Development Team. Let automatic signing create the provisioning profile. Do not tick Critical Alerts.
3. Signing & Capabilities: add **iCloud**, enable **CloudKit**, and select the container above. Confirm an entitlements file appears and the container identifier matches. Add **Push Notifications** only if you want CloudKit’s silent push for sync. Deadline reminders are local and do not need a push entitlement.
4. Build and run on a device or simulator. Confirm both JSON files load, search works, and an HK school (including one of HK013–HK021) and a Japan school show pathways. Confirm HK defaults the new deadline to JUPAS and Japan defaults it to EJU.
5. Language schemes, one pass each: English, Japanese, Traditional Chinese. Check onboarding, tabs (including Settings and the in-app privacy policy), the catalog picker, a pathway disclaimer, an empty deadline state, the notification-denied banner, and a scheduled reminder’s title. Do not add a Simplified Chinese scheme.
6. Allow notifications. Add a future JUPAS or EJU deadline with “Notify me” on. Confirm the system prompt is the normal notification prompt, the sound is the default sound, and pending requests are regular alerts at 9:00 (30 / 7 / 1 / 0 days), not Critical Alerts. Tap a reminder and confirm it opens that school’s Deadlines section. Deny permission on a second run and confirm the banner opens the in-app Settings tab, which explains how to allow regular reminders in iOS Settings.
7. Home screen icon: light, dark, and tinted. The asset catalog uses the iOS 26 single 1024×1024 size (`AppIcon.png`, `AppIcon-dark.png`, `AppIcon-tinted.png`).
8. Product → Generate Privacy Report (or the report from an archive). Compare it with `CollegeTracker/PrivacyInfo.xcprivacy` and `Store/APP_PRIVACY.md`. The manifest now collects nothing: essay feedback is Coming soon and does not POST. If the report lists a required-reason API this audit did not see, add that reason before submit. Do not put Other User Content back unless essay AI is actually sending text again.
9. Run the `CollegeTrackerTests` target (catalog, pathways, reminder formats, CRM metrics, string catalog, essay-AI gate, notification payload, privacy manifest).
10. Archive and upload an internal TestFlight build for yourself. Install it. This checklist does not claim that upload happened.
11. In App Store Connect, create the app for the confirmed bundle ID. Paste `Store/APP_STORE_LISTING.md` (English, Japanese, Traditional Chinese). Host `Store/PRIVACY_POLICY.md` and paste that URL. Enter the App Privacy answers from `Store/APP_PRIVACY.md` so they match the binary you uploaded.
12. Leave screenshots, the age-rating questionnaire, and the final submit for the Week 6 pass. Do not submit from this checklist.
