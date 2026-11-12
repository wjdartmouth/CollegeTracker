// AdmissionsStore.swift
import Foundation

/// Loads bundled HK + Japan admissions pathways and looks them up by catalog id.
final class AdmissionsStore {
    static let shared: AdmissionsStore = .loadFromBundle()

    static let bundledResourceName = "admissions_pathways_v1"
    static let systemJapanCatalogId = "JP_SYSTEM"
    static let systemHongKongCatalogId = "HK_SYSTEM"

    let pathwaysById: [String: [AdmissionPathway]]
    let version: String
    let source: String
    let loadError: String?

    init(
        pathwaysById: [String: [AdmissionPathway]],
        version: String = "unknown",
        source: String = "inline",
        loadError: String? = nil
    ) {
        self.pathwaysById = pathwaysById
        self.version = version
        self.source = source
        self.loadError = loadError
    }

    convenience init(data: Data) throws {
        let file = try JSONDecoder().decode(AdmissionsPathwaysFile.self, from: data)
        self.init(pathwaysById: file.pathwaysById, version: file.version, source: file.source)
    }

    static func loadFromBundle(_ bundle: Bundle = .main) -> AdmissionsStore {
        guard let url = bundle.url(forResource: bundledResourceName, withExtension: "json") else {
            return AdmissionsStore(
                pathwaysById: [:],
                version: "missing",
                source: bundledResourceName,
                loadError: "Bundled pathways \(bundledResourceName).json was not found."
            )
        }
        do {
            return try AdmissionsStore(data: Data(contentsOf: url))
        } catch {
            return AdmissionsStore(
                pathwaysById: [:],
                version: "invalid",
                source: url.lastPathComponent,
                loadError: error.localizedDescription
            )
        }
    }

    /// Pathways for a catalog school, sorted for student display.
    /// Japan schools fall back to national-norm (`JP_SYSTEM`) rows if the id is missing.
    /// Hong Kong schools fall back to (`HK_SYSTEM`) rows the same way.
    func pathways(forCatalogId id: String?) -> [AdmissionPathway] {
        guard let raw = id?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return []
        }
        let key = pathwaysById.keys.first { $0.caseInsensitiveCompare(raw) == .orderedSame } ?? raw
        if let rows = pathwaysById[key], !rows.isEmpty {
            return rows.sorted {
                if $0.categorySortIndex != $1.categorySortIndex {
                    return $0.categorySortIndex < $1.categorySortIndex
                }
                return $0.pathwayName.localizedCaseInsensitiveCompare($1.pathwayName) == .orderedAscending
            }
        }
        if raw.uppercased().hasPrefix("JP"), let fallback = pathwaysById[Self.systemJapanCatalogId] {
            return fallback.sorted { $0.categorySortIndex < $1.categorySortIndex }
        }
        if raw.uppercased().hasPrefix("HK"), let fallback = pathwaysById[Self.systemHongKongCatalogId] {
            return fallback.sorted { $0.categorySortIndex < $1.categorySortIndex }
        }
        return []
    }
}
