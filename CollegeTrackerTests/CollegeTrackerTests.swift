//
//  CollegeTrackerTests.swift
//  CollegeTrackerTests
//

import Foundation
import Testing
@testable import CollegeTracker

struct CollegeCatalogStoreTests {

    private func sampleData() -> Data {
        let json = """
        {
          "version": "test",
          "source": "inline",
          "generated": "2026-11-10",
          "region_focus": "Hong Kong SAR + Japan",
          "count": 2,
          "colleges": [
            {
              "id": "HK001",
              "official_english_name": "The University of Hong Kong",
              "local_native_name": "香港大學",
              "city": "Hong Kong",
              "country_region": "Hong Kong SAR",
              "website": "https://www.hku.hk",
              "type": "Public (UGC-funded)",
              "founded_year": "1911",
              "qs_wur_rank": "17",
              "qs_rank_year": "QS WUR 2025",
              "tuition_approx_usd": "~23300",
              "tuition_currency": "HKD"
            },
            {
              "id": "JP001",
              "official_english_name": "The University of Tokyo",
              "local_native_name": "東京大学",
              "city": "Tokyo",
              "country_region": "Japan",
              "website": "https://www.u-tokyo.ac.jp",
              "type": "National",
              "founded_year": "1877",
              "qs_wur_rank": "32",
              "qs_rank_year": "QS WUR 2025",
              "tuition_approx_usd": "~3600",
              "tuition_currency": "JPY"
            }
          ]
        }
        """
        return Data(json.utf8)
    }

    @Test func decodesCatalogAndSearchesByNameCityRegionAndId() throws {
        let store = try CollegeCatalogStore(data: sampleData())
        #expect(store.colleges.count == 2)
        #expect(store.college(id: "HK001")?.officialEnglishName == "The University of Hong Kong")
        #expect(store.search("香港").map(\.id) == ["HK001"])
        #expect(store.search("tokyo").map(\.id) == ["JP001"])
        #expect(store.search("HK001").map(\.id) == ["HK001"])
        #expect(store.search("Hong Kong SAR").map(\.id) == ["HK001"])
        #expect(store.search("", region: "Japan").map(\.id) == ["JP001"])
        #expect(store.search("university").map(\.id) == ["HK001", "JP001"])
        #expect(store.colleges[0].numericQSRank == 17)
    }

    @Test func numericRankIgnoresBands() {
        let band = CatalogCollege(
            id: "JP999",
            officialEnglishName: "Banded University",
            localNativeName: "",
            city: "Osaka",
            countryRegion: "Japan",
            website: "",
            type: "Private",
            foundedYear: "",
            qsWurRank: "711-720",
            qsRankYear: "QS WUR 2025",
            tuitionApproxUsd: "",
            tuitionCurrency: "JPY"
        )
        #expect(band.numericQSRank == nil)
        #expect(band.qsRankDisplay == "711-720")
    }
}

struct AdmissionsStoreTests {

    private func sampleData() -> Data {
        let json = """
        {
          "version": "test",
          "source": "inline",
          "generated": "2026-11-11",
          "region_focus": "Hong Kong SAR + Japan",
          "count": 8,
          "pathways_by_id": {
            "HK001": [
              {
                "student_category": "local_jupas",
                "pathway_name": "JUPAS (HKDSE)",
                "exams_required": "HKDSE via JUPAS",
                "typical_timeline": "JUPAS calendar",
                "language_requirements": "English",
                "notes": "Local HKDSE",
                "confidence": "high"
              },
              {
                "student_category": "international_non_jupas",
                "pathway_name": "Non-JUPAS / International",
                "exams_required": "IB / A-Level",
                "typical_timeline": "Oct–Nov main round",
                "language_requirements": "English",
                "notes": "Direct apply",
                "confidence": "high"
              }
            ],
            "JP001": [
              {
                "student_category": "japanese_domestic",
                "pathway_name": "一般選抜",
                "exams_required": "Common Test",
                "typical_timeline": "January",
                "language_requirements": "Japanese",
                "notes": "",
                "confidence": "high"
              },
              {
                "student_category": "international_eju",
                "pathway_name": "私費留学生",
                "exams_required": "EJU",
                "typical_timeline": "EJU Jun/Nov",
                "language_requirements": "Japanese",
                "notes": "Verify 募集要項",
                "confidence": "high"
              }
            ],
            "JP_SYSTEM": [
              {
                "student_category": "international_eju",
                "pathway_name": "National EJU norm",
                "exams_required": "EJU",
                "typical_timeline": "June / November",
                "language_requirements": "Japanese",
                "notes": "Fallback",
                "confidence": "medium"
              }
            ],
            "HK_SYSTEM": [
              {
                "student_category": "international_non_jupas",
                "pathway_name": "HK system international norm",
                "exams_required": "IB / A-Level",
                "typical_timeline": "Autumn main round",
                "language_requirements": "English",
                "notes": "Fallback",
                "confidence": "medium"
              },
              {
                "student_category": "non_jupas_local",
                "pathway_name": "HK system local non-JUPAS norm",
                "exams_required": "Direct / E-APP",
                "typical_timeline": "Autumn",
                "language_requirements": "English or Chinese",
                "notes": "Fallback",
                "confidence": "medium"
              },
              {
                "student_category": "jupas_local",
                "pathway_name": "HK system JUPAS norm",
                "exams_required": "HKDSE via JUPAS",
                "typical_timeline": "JUPAS calendar",
                "language_requirements": "English",
                "notes": "Fallback",
                "confidence": "medium"
              }
            ]
          }
        }
        """
        return Data(json.utf8)
    }

    @Test func decodesPathwaysAndSortsInternationalFirst() throws {
        let store = try AdmissionsStore(data: sampleData())
        let hk = store.pathways(forCatalogId: "HK001")
        #expect(hk.map(\.studentCategory) == ["international_non_jupas", "local_jupas"])
        #expect(hk[0].categoryTitle == "Non-JUPAS / International")

        let jp = store.pathways(forCatalogId: "jp001")
        #expect(jp.map(\.studentCategory) == ["international_eju", "japanese_domestic"])
        #expect(jp[0].categoryTitle == "International (EJU)")
    }

    @Test func japanMissingIdFallsBackToSystemNorms() throws {
        let store = try AdmissionsStore(data: sampleData())
        let rows = store.pathways(forCatalogId: "JP999")
        #expect(rows.count == 1)
        #expect(rows[0].pathwayName == "National EJU norm")
        #expect(store.pathways(forCatalogId: nil).isEmpty)
    }

    @Test func hongKongMissingIdFallsBackToSystemNorms() throws {
        let store = try AdmissionsStore(data: sampleData())
        let fallback = store.pathways(forCatalogId: "HK999")
        #expect(fallback.map(\.pathwayName) == [
            "HK system international norm",
            "HK system local non-JUPAS norm",
            "HK system JUPAS norm"
        ])
        // A school with its own rows must not receive the system fallback.
        let hku = store.pathways(forCatalogId: "HK001")
        #expect(hku.count == 2)
        #expect(hku.map(\.pathwayName).contains("HK system JUPAS norm") == false)
    }

    @Test func officialHongKongCategoriesTitleAndSort() throws {
        let json = """
        {
          "version": "test",
          "source": "inline",
          "generated": "2026-11-12",
          "pathways_by_id": {
            "HK013": [
              {
                "student_category": "jupas_local",
                "pathway_name": "SSSDP Year 1 via JUPAS",
                "exams_required": "HKDSE via JUPAS",
                "typical_timeline": "JUPAS calendar",
                "language_requirements": "English",
                "notes": "",
                "confidence": "high"
              },
              {
                "student_category": "non_jupas_local",
                "pathway_name": "Local non-JUPAS",
                "exams_required": "Direct / E-APP",
                "typical_timeline": "Autumn",
                "language_requirements": "English",
                "notes": "",
                "confidence": "high"
              },
              {
                "student_category": "international_non_jupas",
                "pathway_name": "International qualifications",
                "exams_required": "IB / A-Level",
                "typical_timeline": "Autumn main round",
                "language_requirements": "English",
                "notes": "",
                "confidence": "high"
              }
            ]
          }
        }
        """
        let store = try AdmissionsStore(data: Data(json.utf8))
        let rows = store.pathways(forCatalogId: "HK013")
        #expect(rows.map(\.studentCategory) == [
            "international_non_jupas",
            "non_jupas_local",
            "jupas_local"
        ])
        #expect(rows.map(\.categoryTitle) == [
            "Non-JUPAS / International",
            "Non-JUPAS (local)",
            "JUPAS (HKDSE)"
        ])
        // Old hardcoded slugs remain mapped for back-compat with earlier samples.
        let oldSlug = AdmissionPathway(
            studentCategory: "local_jupas",
            pathwayName: "JUPAS (HKDSE)",
            examsRequired: "HKDSE",
            typicalTimeline: "JUPAS calendar",
            languageRequirements: "English",
            notes: "",
            confidence: "high"
        )
        #expect(oldSlug.categoryTitle == "JUPAS (HKDSE)")
        #expect(oldSlug.categorySortIndex == 2)
    }
}

struct RegionAwareTypesTests {

    @Test func hongKongDefaultsPreferJUPAS() {
        #expect(DeadlineType.defaultType(for: .hongKong) == .jupas)
        #expect(DeadlineType.suggested(for: .hongKong).first == .jupas)
        #expect(DocumentType.suggested(for: .hongKong).first == .jupasApplication)
        #expect(CatalogRegion.resolve(catalogId: "HK001", countryRegion: nil) == .hongKong)
    }

    @Test func japanDefaultsPreferEJU() {
        #expect(DeadlineType.defaultType(for: .japan) == .eju)
        #expect(DeadlineType.suggested(for: .japan).contains(.commonTest))
        #expect(DocumentType.suggested(for: .japan).first == .personalStatement)
        #expect(CatalogRegion.resolve(catalogId: "JP001", countryRegion: "Japan") == .japan)
    }

    @Test func catalogTuitionAndMajorsParse() {
        let hku = CatalogCollege(
            id: "HK001",
            officialEnglishName: "The University of Hong Kong",
            localNativeName: "香港大學",
            city: "Hong Kong",
            countryRegion: "Hong Kong SAR",
            website: "https://www.hku.hk",
            type: "Public (UGC-funded)",
            foundedYear: "1911",
            qsWurRank: "17",
            qsRankYear: "QS WUR 2025",
            tuitionApproxUsd: "~23300",
            tuitionCurrency: "HKD",
            majorsFaculties: "Arts; Law; Medicine",
            admissionsNotes: "Local HKDSE via JUPAS."
        )
        #expect(hku.tuitionDisplay == "≈ US$23,300")
        #expect(hku.majorList == ["Arts", "Law", "Medicine"])
        #expect(hku.isHongKong)
        #expect(!hku.isJapan)
    }
}


struct DeadlineReminderPlanTests {

    @Test func requestIDsAreStableAndCoverAllLeadTimes() {
        let id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        #expect(DeadlineReminderPlan.requestIDs(deadlineID: id) == [
            "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE-30",
            "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE-7",
            "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE-1",
            "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE-0"
        ])
        #expect(DeadlineReminderPlan.leadDays == [30, 7, 1, 0])
        #expect(DeadlineReminderPlan.reminderHour == 9)
    }

    @Test func titlesNameJUPASAndEJUTypes() {
        // Lock the English format keys. `title()` fills those keys from the string catalog,
        // so a Japanese test scheme must not be required to keep this green.
        #expect(DeadlineReminderPlan.titleFormat(daysBefore: 30) == "%@ in 30 days")
        #expect(DeadlineReminderPlan.titleFormat(daysBefore: 7) == "%@ in 1 week")
        #expect(DeadlineReminderPlan.titleFormat(daysBefore: 1) == "%@ is tomorrow")
        #expect(DeadlineReminderPlan.titleFormat(daysBefore: 0) == "%@ is today")
        #expect(DeadlineReminderPlan.titleFormat(daysBefore: 3) == nil)
        #expect(String(format: DeadlineReminderPlan.titleFormat(daysBefore: 30)!, "JUPAS") == "JUPAS in 30 days")
        #expect(String(format: DeadlineReminderPlan.titleFormat(daysBefore: 7)!, "EJU") == "EJU in 1 week")
        #expect(String(format: DeadlineReminderPlan.titleFormat(daysBefore: 1)!, "Non-JUPAS") == "Non-JUPAS is tomorrow")
        #expect(String(format: DeadlineReminderPlan.titleFormat(daysBefore: 0)!, "Common Test") == "Common Test is today")
        #expect(DeadlineReminderPlan.body(collegeName: "The University of Hong Kong", dateText: "Dec 3, 2026")
                == "The University of Hong Kong · Dec 3, 2026")
    }

    @Test func skipsCompletedAndPastFireDates() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 13, hour: 10, minute: 0))!

        let future = calendar.date(from: DateComponents(year: 2026, month: 12, day: 13, hour: 23, minute: 59))!
        #expect(DeadlineReminderPlan.shouldSchedule(isComplete: false, deadlineDate: future, now: now, calendar: calendar))
        #expect(DeadlineReminderPlan.upcomingLeadDays(deadlineDate: future, now: now, calendar: calendar) == [30, 7, 1, 0])

        #expect(DeadlineReminderPlan.shouldSchedule(isComplete: true, deadlineDate: future, now: now, calendar: calendar) == false)

        // Before 9:00, both the 1-day and day-of reminders are still schedulable.
        let morning = calendar.date(from: DateComponents(year: 2026, month: 11, day: 13, hour: 8, minute: 0))!
        let tomorrow = calendar.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: 23, minute: 59))!
        #expect(DeadlineReminderPlan.upcomingLeadDays(deadlineDate: tomorrow, now: morning, calendar: calendar) == [1, 0])
        // After 9:00, the 1-day fire date has passed.
        #expect(DeadlineReminderPlan.upcomingLeadDays(deadlineDate: tomorrow, now: now, calendar: calendar) == [0])

        // 10:00 is already after the 9:00 day-of fire time.
        let today = calendar.date(from: DateComponents(year: 2026, month: 11, day: 13, hour: 23, minute: 59))!
        #expect(DeadlineReminderPlan.upcomingLeadDays(deadlineDate: today, now: now, calendar: calendar).isEmpty)
        #expect(DeadlineReminderPlan.shouldSchedule(isComplete: false, deadlineDate: today, now: now, calendar: calendar) == false)
    }
}

struct StudentCRMMetricsTests {

    @Test func monthBucketsSortChronologicallyNotAlphabetically() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 13))!
        let dec = calendar.date(from: DateComponents(year: 2026, month: 12, day: 1))!
        let jan = calendar.date(from: DateComponents(year: 2027, month: 1, day: 15))!
        let apr = calendar.date(from: DateComponents(year: 2027, month: 4, day: 2))!
        let past = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!

        let buckets = StudentCRMMetrics.deadlinesByMonth(
            items: [
                (date: apr, isComplete: false),
                (date: dec, isComplete: false),
                (date: jan, isComplete: false),
                (date: jan, isComplete: false),
                (date: past, isComplete: false),
                (date: dec, isComplete: true)
            ],
            now: now,
            calendar: calendar,
            locale: Locale(identifier: "en_US_POSIX")
        )
        #expect(buckets.map(\.month) == [12, 1, 4])
        #expect(buckets.map(\.count) == [1, 2, 1])
        #expect(buckets.map(\.label) == ["Dec 2026", "Jan 2027", "Apr 2027"])
        #expect(StudentCRMMetrics.isOverdue(past, now: now, calendar: calendar))
        #expect(StudentCRMMetrics.isUpcoming(dec, now: now, calendar: calendar))
    }

    @Test func documentStatsCountHKAndJapanTypes() {
        let stats = StudentCRMMetrics.documentStats(from: [
            (.jupasApplication, 0),
            (.jupasApplication, 120),
            (.personalStatement, 500),
            (.ejuScores, 0),
            (.transcript, 10)
        ])
        #expect(stats.total == 5)
        #expect(stats.started == 3)
        #expect(stats.wordCount == 630)
        #expect(stats.jupasApplications == 2)
        #expect(stats.personalStatements == 1)
        #expect(stats.ejuScores == 1)
    }
}

struct LocalizationCatalogTests {
    private func repoFile(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(name)
    }

    private func loadStrings(at url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return root?["strings"] as? [String: Any] ?? [:]
    }

    private func value(_ entry: Any?, language: String) -> String? {
        guard let entry = entry as? [String: Any],
              let localizations = entry["localizations"] as? [String: Any],
              let languageEntry = localizations[language] as? [String: Any],
              let unit = languageEntry["stringUnit"] as? [String: Any],
              let value = unit["value"] as? String else {
            return nil
        }
        return value
    }

    private func specifierCount(_ text: String) -> Int {
        var count = 0
        var index = text.startIndex
        while index < text.endIndex {
            if text[index] == "%" {
                let next = text.index(after: index)
                if next < text.endIndex, text[next] == "%" {
                    index = text.index(after: next)
                    continue
                }
                count += 1
            }
            index = text.index(after: index)
        }
        return count
    }

    @Test func stringCatalogCoversEnglishJapaneseAndTraditionalChinese() throws {
        let strings = try loadStrings(at: repoFile("CollegeTracker/Localizable.xcstrings"))
        #expect(strings.isEmpty == false)
        for (key, entry) in strings {
            let entry = entry as? [String: Any]
            let localizations = entry?["localizations"] as? [String: Any]
            #expect(localizations?["zh-Hans"] == nil, "No Simplified Chinese: \(key)")
            for language in ["en", "ja", "zh-Hant"] {
                let translated = value(entry, language: language)
                #expect(translated?.isEmpty == false, "\(language) missing for \(key)")
            }
            let en = value(entry, language: "en") ?? ""
            let ja = value(entry, language: "ja") ?? ""
            let zh = value(entry, language: "zh-Hant") ?? ""
            #expect(en == key)
            #expect(specifierCount(en) == specifierCount(ja))
            #expect(specifierCount(en) == specifierCount(zh))
        }
    }

    @Test func infoPlistCatalogLocalizesDisplayNameOnly() throws {
        let strings = try loadStrings(at: repoFile("CollegeTracker/InfoPlist.xcstrings"))
        #expect(Set(strings.keys) == ["CFBundleDisplayName", "CFBundleName"])
        for key in strings.keys {
            #expect(value(strings[key], language: "en") == "College Tracker")
            #expect(value(strings[key], language: "ja") == "進学トラッカー")
            #expect(value(strings[key], language: "zh-Hant") == "升學追蹤")
        }
    }

    @Test func enumsAndPathwayTitlesAreCatalogKeys() throws {
        let strings = try loadStrings(at: repoFile("CollegeTracker/Localizable.xcstrings"))
        let keys = Set(strings.keys)
        for status in ApplicationStatus.allCases {
            #expect(keys.contains(status.rawValue))
        }
        for type in DeadlineType.allCases {
            #expect(keys.contains(type.rawValue))
        }
        for type in DocumentType.allCases {
            #expect(keys.contains(type.rawValue))
        }
        for area in FocusArea.allCases {
            #expect(keys.contains(area.rawValue))
        }
        let categories = [
            "jupas_local", "local_jupas", "non_jupas_local", "international_non_jupas",
            "direct_application", "japanese_domestic", "international_eju",
            "international_qualifications", "overseas_returnee"
        ]
        for slug in categories {
            let pathway = AdmissionPathway(
                studentCategory: slug,
                pathwayName: "sample",
                examsRequired: "",
                typicalTimeline: "",
                languageRequirements: "",
                notes: "",
                confidence: "high"
            )
            #expect(keys.contains(pathway.categoryTitle))
        }
        for format in [30, 7, 1, 0].compactMap(DeadlineReminderPlan.titleFormat(daysBefore:)) {
            #expect(keys.contains(format))
        }
        let schoolTypes = [
            "National",
            "National (merged into Institute of Science Tokyo)",
            "Private",
            "Public (UGC-funded)",
            "Public (metropolitan)",
            "Public (municipal)",
            "Public (prefectural/municipal)",
            "Publicly-funded (not UGC-funded)",
            "Self-financing (VTC member institution)",
            "Self-financing (private)",
            "Self-financing (publicly owned)"
        ]
        for type in schoolTypes {
            #expect(keys.contains(type))
        }
    }

    @Test func privacyManifestCollectsNothing() throws {
        let url = repoFile("CollegeTracker/PrivacyInfo.xcprivacy")
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("NSPrivacyCollectedDataTypeOtherUserContent") == false)
        #expect(text.contains("<key>NSPrivacyCollectedDataTypes</key>"))
        #expect(text.contains("<key>NSPrivacyTracking</key>"))
        #expect(text.contains("<false/>"))
    }
}

struct EssayAIShippingTests {
    private func repoFile(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(name)
    }

    @Test @MainActor func essayFeedbackScreenIsNotPresented() throws {
        let editor = try String(contentsOf: repoFile("CollegeTracker/Views/Documents/EssayEditorView.swift"), encoding: .utf8)
        let vault = try String(contentsOf: repoFile("CollegeTracker/Views/Documents/DocumentVaultView.swift"), encoding: .utf8)
        let detail = try String(contentsOf: repoFile("CollegeTracker/Views/Colleges/CollegeDetailView.swift"), encoding: .utf8)
        #expect(editor.contains("EssayFeedbackView(") == false)
        #expect(vault.contains("EssayFeedbackView(") == false)
        #expect(detail.contains("EssayFeedbackView(") == false)
        #expect(editor.contains("Coming soon"))
    }

    @Test @MainActor func networkStaysOffAndDoesNotPost() async {
        #expect(AIFeedbackService.networkEnabled == false)
        let request = FeedbackRequest(
            essayText: "A short essay that must stay on device.",
            wordLimit: 100,
            collegeName: "The University of Hong Kong",
            promptText: "Why this school?",
            focusArea: .overall
        )
        do {
            _ = try await AIFeedbackService.shared.getFeedback(for: request)
            Issue.record("v1 must not request essay feedback")
        } catch AIError.unavailable {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

struct NotificationPayloadTests {
    @Test @MainActor func roundTripsCollegeAndDeadline() {
        let deadline = UUID()
        let college = UUID()
        let info = NotificationPayload.userInfo(deadlineID: deadline, collegeID: college)
        #expect(NotificationPayload.link(from: info) == DeadlineNotificationLink(collegeID: college, deadlineID: deadline))
    }

    @Test @MainActor func deadlineAloneStillLinks() {
        let deadline = UUID()
        let link = NotificationPayload.link(from: [NotificationPayload.deadlineIDKey: deadline.uuidString])
        #expect(link?.deadlineID == deadline)
        #expect(link?.collegeID == nil)
    }

    @Test @MainActor func rejectsAMissingOrInvalidDeadline() {
        #expect(NotificationPayload.link(from: [:]) == nil)
        #expect(NotificationPayload.link(from: [NotificationPayload.deadlineIDKey: "not-a-uuid"]) == nil)
    }
}
