# Privacy policy (draft) — College Tracker

**Status:** Draft for the Hong Kong and Japan App Store listing. Not published. Not legal advice. Jian should host this text (or a reviewed version of it) at a stable URL before submission.

**App:** College Tracker (日本語: 進学トラッカー, 繁體中文: 升學追蹤)  
**Bundle ID:** `edu.asu.jwang875.CollegeTracker`  
**Draft date:** 15 November 2026  
**Operator:** the developer of College Tracker. This draft does not invent a company name, email address, phone number, or Japanese business address. The contact method for the published policy is the support URL on the App Store product page, which the developer will set in App Store Connect.

This policy is written for students in Hong Kong and Japan. The interface languages are English, Japanese, and Traditional Chinese.

---

## What the app is

College Tracker is a student app for keeping track of university applications in Hong Kong and Japan: schools from a bundled catalog, deadlines, documents, notes, and local reminders. There is no College Tracker account. Counselor sharing is not available in this version.

## Data that stays on your device

The app stores, on this iPhone, the name you type at setup, the schools you add, deadlines, documents (including any text you type), and notes. That store is Apple’s SwiftData database in the app’s sandbox.

The developer does not receive that on-device store. It is not used for advertising or tracking.

## iCloud (optional, private)

The project is written so that, once the iCloud capability is enabled, the same store can sync through CloudKit to **your** private iCloud database (`iCloud.edu.asu.jwang875.CollegeTracker`). The developer does not have a server that reads that database.

As of this draft, the Xcode project does not yet contain an iCloud entitlement. Until that capability is added and you are signed into iCloud, the data remains only on the device. If sync fails, the app falls back to the local store.

Turning off iCloud for the app, or deleting the app, is how you remove that copy from the device. iCloud copies follow your Apple ID settings, which Apple controls.

## Notifications

Deadline reminders are scheduled **on the device** with Apple’s local notification system. They fire at 9:00 local time (30 days, 7 days, 1 day, and the day of an incomplete deadline that is still in the future). They are ordinary notifications, not Critical Alerts. The app does not send the content of a reminder to the developer. iOS asks you for notification permission; you can change that later in Settings.

## Catalog

School names, pathway descriptions, and related facts ship inside the app. The app does not download a Mainland China catalog and does not contact a College Tracker server for catalog updates.

Tapping a school website opens that address in the browser. That request is between you and the university’s site.

## Essay feedback screen (read before you ship)

The app includes an AI Feedback screen. If you use it, the app sends the essay text, an optional prompt, the word count, the focus you picked, and the school name to Anthropic’s API at `api.anthropic.com`, so that service can generate feedback. The developer does not operate that API. No Anthropic API key is bundled in the repository, so the request cannot succeed until a key is configured.

This screen is **not** described as a v1 feature in the App Store listing draft. If you remove the screen before release, delete this section and remove `NSPrivacyCollectedDataTypeOtherUserContent` from `CollegeTracker/PrivacyInfo.xcprivacy` and from the App Privacy answers.

## Tracking, ads, and accounts

- The app does not track you across apps or websites.
- It does not show ads.
- It does not ask you to create a College Tracker account.
- It does not sell personal data.

## Hong Kong

The Personal Data (Privacy) Ordinance (Cap. 486) applies to personal data that a data user collects. For the on-device store and private iCloud sync, the developer does not collect that data. If the AI Feedback screen ships and you use it, the essay content leaves the device and is handled by Anthropic under their terms; that is the disclosure for this draft. You can use the rest of the app without opening that screen.

## Japan

The Act on the Protection of Personal Information (個人情報保護法) applies when a business operator handles personal information. Data that never leaves your device, and data that syncs only to your private iCloud database, is not received by the developer. The same AI Feedback disclosure above is the exception if that screen ships.

### 特定商取引法

This version is free and has no in-app purchases, so this draft does not include a 特定商取引法 seller display. **Do not invent a Japanese business name, address, phone number, or representative.** If a paid app or in-app purchase is added later, publish that notation with the real business details before the paid version is available in Japan, and update this policy.

## Children

Students using the app may be under 18. The app does not create an account and does not ask for a date of birth. Do not type information into the AI Feedback screen if you do not want that text sent to Anthropic.

## Changes

If the shipped app starts collecting something this draft does not describe, update the hosted policy, `PrivacyInfo.xcprivacy`, and the App Privacy answers together before the binary that does so is released.

## Contact

Use the support URL on the App Store page. This draft intentionally has no email address and no postal address.
