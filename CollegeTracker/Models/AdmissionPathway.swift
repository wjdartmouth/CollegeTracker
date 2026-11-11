// AdmissionPathway.swift
import Foundation

/// One admissions pathway for a catalog school (JUPAS, EJU, returnee, etc.).
struct AdmissionPathway: Codable, Hashable, Identifiable, Sendable {
    let studentCategory: String
    let pathwayName: String
    let examsRequired: String
    let typicalTimeline: String
    let languageRequirements: String
    let notes: String
    let confidence: String

    var id: String { "\(studentCategory)|\(pathwayName)" }

    enum CodingKeys: String, CodingKey {
        case studentCategory = "student_category"
        case pathwayName = "pathway_name"
        case examsRequired = "exams_required"
        case typicalTimeline = "typical_timeline"
        case languageRequirements = "language_requirements"
        case notes, confidence
    }

    var categoryTitle: String {
        switch studentCategory {
        case "local_jupas": return "JUPAS (HKDSE)"
        case "international_non_jupas": return "Non-JUPAS / International"
        case "direct_application": return "Direct application"
        case "japanese_domestic": return "Domestic (Japan)"
        case "international_eju": return "International (EJU)"
        case "international_qualifications": return "International qualifications"
        case "overseas_returnee": return "Overseas returnee"
        default:
            return studentCategory
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }

    var confidenceTitle: String {
        switch confidence.lowercased() {
        case "high": return "High confidence"
        case "medium": return "Medium confidence"
        case "low": return "Low confidence"
        default: return confidence.capitalized
        }
    }

    /// Preferred display order for HK / Japan student categories.
    var categorySortIndex: Int {
        switch studentCategory {
        case "international_non_jupas": return 0
        case "local_jupas": return 1
        case "direct_application": return 2
        case "international_eju": return 10
        case "international_qualifications": return 11
        case "overseas_returnee": return 12
        case "japanese_domestic": return 13
        default: return 50
        }
    }
}

/// On-disk wrapper for `admissions_pathways_v1.json`.
struct AdmissionsPathwaysFile: Codable, Sendable {
    let version: String
    let source: String
    let generated: String
    let regionFocus: String?
    let count: Int?
    let pathwaysById: [String: [AdmissionPathway]]

    enum CodingKeys: String, CodingKey {
        case version, source, generated, count
        case regionFocus = "region_focus"
        case pathwaysById = "pathways_by_id"
    }
}

enum CatalogRegion: Equatable {
    case hongKong
    case japan
    case other

    static func resolve(catalogId: String?, countryRegion: String?) -> CatalogRegion {
        let id = catalogId?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        let region = countryRegion ?? ""
        if id.hasPrefix("HK") || region.localizedCaseInsensitiveContains("Hong Kong") {
            return .hongKong
        }
        if id.hasPrefix("JP") || region.caseInsensitiveCompare("Japan") == .orderedSame {
            return .japan
        }
        return .other
    }

    static func of(_ college: College) -> CatalogRegion {
        resolve(catalogId: college.catalogId, countryRegion: college.countryRegion)
    }

    static func of(_ college: CatalogCollege) -> CatalogRegion {
        resolve(catalogId: college.id, countryRegion: college.countryRegion)
    }
}
