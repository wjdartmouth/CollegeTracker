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
