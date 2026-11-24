# Privacy manifest audit and App Privacy answers

Audited from the source tree on 24 November 2026. This was **not** an Xcode privacy report, an archive, or an App Store Connect submission. Before upload, generate the privacy report in Xcode and reconcile it with this file. The Week 5 checklist says the same thing.

Bundle ID and CloudKit container were not changed:

- `edu.asu.jwang875.CollegeTracker`
- `iCloud.edu.asu.jwang875.CollegeTracker`

## What the code actually does

| Behavior | In the target today | Collected by the developer? |
| --- | --- | --- |
| SwiftData store of profile, schools, deadlines, documents, notes | Yes | No. Stays on device. |
| CloudKit private database (`cloudKitDatabase: .automatic`), falling back to local if configuration fails | Code is present. No entitlements file yet, so a build without the capability stays local. | No. Private iCloud database; the developer has no server that reads it. |
| Local notifications (`UserNotifications`), sound `.default`, not Critical Alerts | Yes | No. Scheduled on device. |
| `UIApplication.shared.open` for a school URL the student taps | Yes | No. The browser loads the university site. |
| `URLSession` POST to `https://api.anthropic.com/v1/messages` | The method is still in `AIFeedbackService`, and `networkEnabled` is `false`. `getFeedback` throws before the request. The student UI does not present `EssayFeedbackView`. | No. Essay text is not sent. Do not declare Other User Content. |
| Counselor CloudKit sharing | Code exists and is not reachable from onboarding (Coming soon). | Not a v1 path. |
| UserDefaults, file timestamps (`stat`, `NSFileModificationDate`, and the rest of that list), system boot time, disk space, active keyboards | Not called by this target | Do not declare a required-reason API for them. |
| Tracking, advertising, contacts, photos, camera, microphone, location, calendars, Bluetooth, Health | Not used | No usage strings, no tracking domains. |

`NSUserNotificationsUsageDescription` is not an Info.plist key. Local notification permission uses the system prompt. No other protected-resource usage description applies, so `InfoPlist.xcstrings` localizes only `CFBundleDisplayName` and `CFBundleName`.

Mainland China catalog data is not in the bundle and is not fetched.

## PrivacyInfo.xcprivacy

File: `CollegeTracker/PrivacyInfo.xcprivacy`.

- `NSPrivacyTracking`: false
- `NSPrivacyTrackingDomains`: empty
- `NSPrivacyAccessedAPITypes`: empty. This is intentional after the audit, not an untouched stub. If Xcode’s privacy report later names an API this review missed, add that reason then. Do not add `NSPrivacyAccessedAPICategoryUserDefaults` or file-timestamp reasons unless the report shows the app calls them.
- `NSPrivacyCollectedDataTypes`: empty. Essay AI no longer leaves the device, so Other User Content is not declared. If a later release turns `AIFeedbackService.networkEnabled` on, add `NSPrivacyCollectedDataTypeOtherUserContent` (not linked, not tracking, app functionality) before that binary ships, and update this file with it.

## App Store Connect — App Privacy

Answer from the binary you submit. For the tree as of this draft:

**Data Used to Track You:** none.

**Data Linked to You:** none. There is no account, and the on-device store is not sent to the developer.

**Data Not Linked to You:** none.

**Data Not Collected:**

- Name (the setup name stays on device / private iCloud)
- Deadlines, school list, notes, and documents, including essay text
- Precise or coarse location
- Contacts, photos, audio, browsing history
- Identifiers for tracking, device ID for advertising
- Purchase history (the app is free and has no in-app purchases)
- Other User Content (essay feedback does not ship, and the Anthropic POST does not run)

**Tracking:** No.

## Usage descriptions

None are required for the APIs in use. Do not add camera, photo, location, or tracking purpose strings. The localized display name is:

| Key | en | ja | zh-Hant |
| --- | --- | --- | --- |
| CFBundleDisplayName / CFBundleName | College Tracker | 進学トラッカー | 升學追蹤 |
