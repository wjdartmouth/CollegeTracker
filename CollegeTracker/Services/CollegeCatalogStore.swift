// CollegeCatalogStore.swift
import Foundation

/// Loads the bundled HK + Japan catalog and searches by name, native name, city, region, or catalog id.
final class CollegeCatalogStore {
    static let shared: CollegeCatalogStore = .loadFromBundle()

    static let bundledResourceName = "universities_hk_japan_v1"

    let colleges: [CatalogCollege]
    let version: String
    let source: String
    let loadError: String?

    var regions: [String] {
        Array(Set(colleges.map(\.countryRegion).filter { !$0.isEmpty })).sorted()
    }

    init(colleges: [CatalogCollege], version: String = "unknown", source: String = "inline", loadError: String? = nil) {
        self.colleges = colleges
        self.version = version
        self.source = source
        self.loadError = loadError
    }

    convenience init(data: Data) throws {
        let file = try JSONDecoder().decode(CollegeCatalogFile.self, from: data)
        self.init(colleges: file.colleges, version: file.version, source: file.source)
    }

    static func loadFromBundle(_ bundle: Bundle = .main) -> CollegeCatalogStore {
        guard let url = bundle.url(forResource: bundledResourceName, withExtension: "json") else {
            return CollegeCatalogStore(
                colleges: [],
                version: "missing",
                source: bundledResourceName,
                loadError: "Bundled catalog \(bundledResourceName).json was not found."
            )
        }
        do {
            return try CollegeCatalogStore(data: Data(contentsOf: url))
        } catch {
            return CollegeCatalogStore(
                colleges: [],
                version: "invalid",
                source: url.lastPathComponent,
                loadError: error.localizedDescription
            )
        }
    }

    func college(id: String) -> CatalogCollege? {
        colleges.first { $0.id.caseInsensitiveCompare(id) == .orderedSame }
    }

    /// Search by English name, local/native name, city, country/region, type, or catalog id.
    /// Empty query returns the (optionally region-filtered) catalog sorted by region, then QS rank, then name.
    func search(_ query: String, region: String? = nil) -> [CatalogCollege] {
        var results = colleges
        if let region, !region.isEmpty {
            results = results.filter { $0.countryRegion == region }
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return results.sorted(by: Self.defaultSort)
        }

        results = results.filter { $0.matches(trimmed) }
        return results.sorted { lhs, rhs in
            let l = lhs.relevance(to: trimmed)
            let r = rhs.relevance(to: trimmed)
            if l != r { return l > r }
            return Self.defaultSort(lhs, rhs)
        }
    }

    private static func defaultSort(_ lhs: CatalogCollege, _ rhs: CatalogCollege) -> Bool {
        if lhs.countryRegion != rhs.countryRegion {
            return lhs.countryRegion < rhs.countryRegion
        }
        let lRank = lhs.numericQSRank ?? Int.max
        let rRank = rhs.numericQSRank ?? Int.max
        if lRank != rRank { return lRank < rRank }
        return lhs.officialEnglishName.localizedCaseInsensitiveCompare(rhs.officialEnglishName) == .orderedAscending
    }
}
