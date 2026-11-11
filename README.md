# 🎓 College Tracker

An advanced iOS 17+ college application management app for students and counselors. Track deadlines, manage essays with AI-powered feedback, compare schools side-by-side, and visualize your progress — all synced across devices via iCloud.

**Ship status:** see [SHIP_STATUS.md](SHIP_STATUS.md). The app is a student-first client for the bundled Hong Kong + Japan catalog (830 schools) with searchable add, catalog facts, and JUPAS / EJU (and related) pathway screens. Counselor CloudKit sharing and essay AI are deferred.

> Bundle ID and CloudKit container follow the existing Xcode project: `edu.asu.jwang875.CollegeTracker` / `iCloud.edu.asu.jwang875.CollegeTracker`. Confirm before App Store Connect whether to keep this ASU-era identifier or migrate to `com.jianwang.CollegeTracker`.

---

## ✨ Features

### For Students
- **Application dashboard** — Greeting, upcoming deadline carousel, college status board, and stats at a glance
- **College catalog** — Search and add from 830 bundled Hong Kong + Japan schools (college-data). Custom entry remains as a fallback.
- **9 application statuses** — Researching → In Progress → Submitted → Interviewing → Accepted / Waitlisted / Deferred / Rejected → Enrolled
- **Deadline tracking** — Region-aware types: JUPAS and Non-JUPAS for Hong Kong; EJU, Common Test, Comprehensive (AO), and School Recommendation for Japan; plus scholarship, financial aid, interview, custom, and US ED/EA/RD. Urgency color-coding (red < 7 days, amber < 30 days, green otherwise).
- **Smart notifications** — Automatic reminders at 30 days, 1 week, 1 day, and day-of for every deadline
- **Document vault** — Region-aware types including JUPAS applications, personal statements, school reports, EJU scores, transcripts, recommendations, and (still available) Common App / supplemental essays.
- **Essay editor** — Full-screen editor with live word count progress bar and word limit tracking
- **AI essay feedback** — Claude-powered analysis with score (X/10), strengths, areas to improve, specific suggestions, and encouragement
- **College comparison** — Side-by-side table for up to 3 schools
- **Progress charts** — Donut chart of application statuses, quick stats grid

### For Counselors
- **Multi-student support** — Counselor role with managed student IDs
- **CloudKit sharing** — Share a student's record zone via the native iOS sharing UI
- **Same powerful views** — All student features available when viewing a student's profile

---

## 🏗️ Architecture

Pattern: **MVVM** with SwiftData persistence and CloudKit automatic sync.

```
CollegeTracker/
├── App/
│   └── CollegeTrackerApp.swift        @main, SwiftData + CloudKit ModelContainer,
│                                       UNUserNotificationCenterDelegate setup
│
├── Models/
│   ├── Models.swift                   All SwiftData models and enums:
│   ├── CatalogCollege.swift           Bundled HK + Japan catalog row (Codable)
│   └── AdmissionPathway.swift         JUPAS / EJU / other pathway rows + region helper
│
├── Resources/
│   ├── universities_hk_japan_v1.json  830-school HK + Japan catalog (incl. majors + notes)
│   └── admissions_pathways_v1.json    HK + Japan admissions pathways (~3.3k rows)
│
├── Services/
│   ├── CollegeCatalogStore.swift      Loads and searches the bundled catalog
│   ├── AdmissionsStore.swift          Looks up pathways by catalog id
│   ├── AIFeedbackService.swift        Anthropic API integration — structured essay
│                                       feedback with score parsing (deferred)
│   ├── CloudKitService.swift          iCloud container `iCloud.edu.asu.jwang875.CollegeTracker`
│   └── NotificationService.swift      Multi-interval deadline reminders (30d/7d/1d/0d)
│
├── Views/
│   ├── RootView.swift                 Onboarding flow, role selection, MainTabView
│   ├── Dashboard/
│   │   └── DashboardView.swift        Greeting, stat cards, deadline timeline
│   │                                   carousel, college list
│   ├── Colleges/
│   │   ├── CollegeListView.swift      Searchable list, status filter chips,
│   │   │                              compare mode, catalog add-college sheet
│   │   ├── CatalogCollegePicker.swift Search + region chips for the bundled catalog
│   │   ├── PathwaySection.swift       Catalog facts + JUPAS / EJU pathway cards
│   │   └── CollegeDetailView.swift    Segmented tabs: pathways, deadlines, documents, notes
│   ├── Documents/
│   │   ├── DocumentVaultView.swift    Cross-college document vault with type filters
│   │   │                              and AI feedback nudge banner
│   │   └── EssayEditorView.swift      Full-screen editor, word count progress bar
│   ├── AIFeedback/
│   │   └── EssayFeedbackView.swift    Focus area picker, AI request, score badge,
│   │                                   structured feedback sections, history log
│   └── Charts/
│       └── ProgressDashboardView.swift  Overall progress ring, status donut chart,
│                                         deadlines-by-month bar chart, essay stats,
│                                         quick stats grid
│
└── Shared/
    └── Extensions.swift               Color(hex:), date formatting, cardStyle()
```

### Key Patterns

| Pattern | Where Used | Why |
|---|---|---|
| `SwiftData` | All 5 models | iOS 17 native persistence with CloudKit auto-sync |
| `@Query` | All list views | Live model fetching that auto-refreshes UI on changes |
| `@Bindable` | Detail views | Direct two-way binding to SwiftData model objects |
| `CloudKit (.automatic)` | `ModelContainer` | Zero-code iCloud sync — SwiftData handles it |
| `Anthropic API` | `AIFeedbackService` | On-demand essay analysis via `claude-sonnet` |
| `UNUserNotificationCenter` | `NotificationService` | Multi-interval deadline reminders |
| `Charts` framework | `ProgressDashboardView` | Donut + bar charts from native iOS 16 Charts |

---

## 📦 Data Models

### `UserProfile`
The top-level user record. Owns all colleges via a cascade-delete relationship.
- `role: UserRole` — `.student` or `.counselor`
- `managedStudentIDs: [String]` — counselor-only: CloudKit record IDs of students being managed

### `College`
One school in the student's list.
- `status: ApplicationStatus` — one of 9 statuses from Researching to Enrolled
- `acceptanceRate: Double?` — for comparison and charts
- `ranking: Int?` / `qsRankText` — QS World rank from the bundled catalog
- `portalURL: String?` — opens in Safari from the detail view
- Cascades to `[Deadline]` and `[Document]` on delete

### `Deadline`
A specific due date tied to a college.
- `type: DeadlineType` — Region-aware list (JUPAS, Non-JUPAS, EJU, Common Test, Comprehensive (AO), School Recommendation, plus scholarship / interview / custom and US ED/EA/RD)
- `daysRemaining` — computed from today, drives urgency color
- `urgencyColor` — red (≤7 days), amber (≤30 days), green (>30 days)

### `Document`
An essay, transcript, or other file attached to a college.
- `wordLimit: Int?` — if set, shows a live progress bar in the editor
- `wordCountStatus` — `.ok`, `.nearLimit` (>90%), `.over` (>100%)
- `feedbackHistory: [EssayFeedback]` — full AI review history, cascade-deleted

### `EssayFeedback`
One AI review session.
- `focusArea: String` — which aspect Claude was asked to evaluate
- `score: Int?` — parsed X/10 from the response
- `wordCountAtTime: Int` — word count when feedback was requested

---

## 🤖 AI Essay Feedback

`AIFeedbackService` calls the Anthropic API (`claude-sonnet-4-20250514`) with a structured system prompt that forces a consistent response format:

```
SCORE: X/10
STRENGTHS:
- ...
IMPROVEMENTS:
- ...
SUGGESTIONS:
- ...
ENCOURAGEMENT: ...
```

The service then parses that format using regex and string extraction into a `ParsedFeedback` struct, which drives the structured UI in `EssayFeedbackView` — score badge, strengths list, improvements list, suggestions list, and encouragement quote.

**Available focus areas:**
Overall Review · Structure & Flow · Authentic Voice · Prompt Alignment · Grammar & Style · Conciseness

> ⚠️ The Anthropic API key is handled by the backend proxy in the Claude.ai environment. For standalone use, add your API key to the `URLRequest` headers in `AIFeedbackService.swift`.

---

## Bundled catalog and pathways

The app ships Hong Kong + Japan data from [college-data](https://github.com/wjdartmouth/college-data) as two JSON files under `CollegeTracker/Resources/`:

- `universities_hk_japan_v1.json` — 830 schools, including majors and admissions notes
- `admissions_pathways_v1.json` — Japan join table (EJU / domestic / international qualifications / returnee) plus structured JUPAS / Non-JUPAS (or direct application) rows for the 12 Hong Kong schools

The Xcode project uses a file-system synchronized group, so new files in `Resources/` are picked up automatically. To regenerate after a college-data update:

```bash
python3 scripts/generate_bundled_data.py
```

The script looks for a sibling `college-data` or `college-data-git` checkout, or `COLLEGE_DATA_DIR`. Pathway timelines are descriptive; they are not turned into deadline records automatically.

---

## 🚀 Getting Started

### Requirements

- Xcode 15+
- iOS 17.0+ deployment target
- Apple Developer account (paid — required for iCloud + CloudKit on device)

---

### 1. Create the Xcode Project

1. Xcode → **File → New → Project → iOS → App**
2. Configure:
   - **Product Name**: `CollegeTracker`
   - **Bundle Identifier**: `edu.asu.jwang875.CollegeTracker`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: None *(SwiftData is configured manually)*
3. Replace the generated `ContentView.swift` and `App.swift` with files from this project

---

### 2. Add All Source Files

Drag each file into the correct group in Xcode's project navigator. Ensure **Copy items if needed** and **CollegeTracker** target membership are both checked for every file.

---

### 3. Configure iCloud + CloudKit

SwiftData's `.automatic` CloudKit configuration handles sync automatically — no custom sync code needed.

1. Select the `CollegeTracker` target → **Signing & Capabilities**
2. Add **iCloud** capability
3. Under **CloudKit**, click **+** and add container: `iCloud.edu.asu.jwang875.CollegeTracker`
4. Add **Push Notifications** capability (required for CloudKit push-based sync)

---

### 4. Configure Notifications

No extra capability needed beyond Push Notifications (added above). The `NotificationService` requests permission on first launch automatically.

---

### 5. Set Deployment Target

Go to **Build Settings → Deployment → iOS Deployment Target** and set it to **iOS 17.0**.

Required for SwiftData, `@Bindable`, `@Query`, and the Charts framework.

---

## ⚙️ Configuration Checklist

- [ ] CloudKit container ID — confirm `iCloud.edu.asu.jwang875.CollegeTracker` (or migrate to `iCloud.com.jianwang.CollegeTracker` before creating the App Store record)
- [ ] Bundle ID — confirm `edu.asu.jwang875.CollegeTracker` (or migrate to `com.jianwang.CollegeTracker` before creating the App Store record)
- [ ] Development Team — set in both Signing & Capabilities
- [ ] Anthropic API key — add to `AIFeedbackService.swift` `URLRequest` headers for standalone use:
  ```swift
  urlRequest.setValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "x-api-key")
  urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
  ```
- [ ] App icon — add to `Assets.xcassets`

---

## 📐 Data Flow

```
User adds a college
    ↓
AddCollegeView saves College + optional Deadline to SwiftData
    ↓
SwiftData syncs to iCloud CloudKit container (automatic)
    ↓
NotificationService.scheduleReminders() — 4 notifications per deadline
    ↓
DashboardView @Query refreshes automatically

User requests AI essay feedback
    ↓
EssayFeedbackView → AIFeedbackService.getFeedback()
    ↓
POST /v1/messages → Anthropic API (claude-sonnet-4-20250514)
    ↓
Response parsed → EssayFeedback SwiftData record saved
    ↓
feedbackHistory renders score badge + structured sections
```

---

## 🗺️ Roadmap

- [ ] Common App essay prompt library
- [ ] Acceptance odds calculator based on GPA / test scores
- [ ] Counselor dashboard — view all managed students in one place
- [ ] Document file attachments (PDF upload for transcripts)
- [ ] Calendar view of all deadlines across schools
- [ ] App Store submission checklist per school
- [ ] Export to PDF — full application summary
- [ ] Widgets — upcoming deadline on home screen
- [ ] Siri Shortcuts — "When is my Harvard deadline?"

---

## 🛠 Tech Stack

| Technology | Version | Purpose |
|---|---|---|
| Swift | 5.9+ | Language |
| SwiftUI | iOS 17 | UI framework |
| SwiftData | iOS 17 | Persistence |
| CloudKit | iOS 17 | iCloud sync (via SwiftData `.automatic`) |
| Charts | iOS 16+ | Donut + bar charts |
| UserNotifications | iOS 10+ | Multi-interval deadline reminders |
| Anthropic API | claude-sonnet-4-20250514 | AI essay feedback |

---

## 📄 License

MIT License. Free to use, modify, and distribute.
