//
//  CollegeTrackerTests.swift
//  CollegeTrackerTests
//

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
          "count": 5,
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
        #expect(store.pathways(forCatalogId: "HK999").isEmpty)
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
