// CatalogCollege.swift
import Foundation

/// A row from the bundled HK + Japan college catalog (college-data `universities_hk_japan_v1`).
struct CatalogCollege: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let officialEnglishName: String
    let localNativeName: String
    let city: String
    let countryRegion: String
    let website: String
    let type: String
    let foundedYear: String
    let qsWurRank: String
    let qsRankYear: String
    let tuitionApproxUsd: String
    let tuitionCurrency: String
    let majorsFaculties: String?
    let admissionsNotes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case officialEnglishName = "official_english_name"
        case localNativeName = "local_native_name"
        case city
        case countryRegion = "country_region"
        case website
        case type
        case foundedYear = "founded_year"
        case qsWurRank = "qs_wur_rank"
        case qsRankYear = "qs_rank_year"
        case tuitionApproxUsd = "tuition_approx_usd"
        case tuitionCurrency = "tuition_currency"
        case majorsFaculties = "majors_faculties"
        case admissionsNotes = "admissions_notes"
    }

    init(
        id: String,
        officialEnglishName: String,
        localNativeName: String,
        city: String,
        countryRegion: String,
        website: String,
        type: String,
        foundedYear: String,
        qsWurRank: String,
        qsRankYear: String,
        tuitionApproxUsd: String,
        tuitionCurrency: String,
        majorsFaculties: String? = nil,
        admissionsNotes: String? = nil
    ) {
        self.id = id
        self.officialEnglishName = officialEnglishName
        self.localNativeName = localNativeName
        self.city = city
        self.countryRegion = countryRegion
        self.website = website
        self.type = type
        self.foundedYear = foundedYear
        self.qsWurRank = qsWurRank
        self.qsRankYear = qsRankYear
        self.tuitionApproxUsd = tuitionApproxUsd
        self.tuitionCurrency = tuitionCurrency
        self.majorsFaculties = majorsFaculties
        self.admissionsNotes = admissionsNotes
    }

    var displayName: String { officialEnglishName }

    var locationLine: String {
        [city, countryRegion].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var qsRankDisplay: String? {
        let trimmed = qsWurRank.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
    }

    /// QS overall rank when the catalog value is a single integer (e.g. "17"). Bands like "711-720" return nil.
    var numericQSRank: Int? {
        Int(qsWurRank.trimmingCharacters(in: .whitespacesAndNewlines))
    }


    var majorList: [String] {
        (majorsFaculties ?? "")
            .split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Catalog tuition is stored as an approximate USD figure (e.g. "~23300").
    var tuitionDisplay: String? {
        let raw = tuitionApproxUsd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        let digits = raw.replacingOccurrences(of: "~", with: "").replacingOccurrences(of: ",", with: "")
        if let value = Double(digits) {
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            let formatted = formatter.string(from: NSNumber(value: value)) ?? digits
            return "≈ US$\(formatted)"
        }
        return raw
    }

    var isHongKong: Bool {
        countryRegion.localizedCaseInsensitiveContains("Hong Kong") || id.uppercased().hasPrefix("HK")
    }

    var isJapan: Bool {
        countryRegion.caseInsensitiveCompare("Japan") == .orderedSame || id.uppercased().hasPrefix("JP")
    }

    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return true }
        let lower = q.lowercased()
        return id.lowercased().contains(lower)
            || officialEnglishName.lowercased().contains(lower)
            || localNativeName.lowercased().contains(lower)
            || city.lowercased().contains(lower)
            || countryRegion.lowercased().contains(lower)
            || type.lowercased().contains(lower)
    }

    func relevance(to query: String) -> Int {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return 0 }
        if id.lowercased() == q { return 100 }
        if officialEnglishName.lowercased() == q { return 90 }
        if localNativeName.lowercased() == q { return 88 }
        if officialEnglishName.lowercased().hasPrefix(q) { return 80 }
        if localNativeName.lowercased().hasPrefix(q) { return 75 }
        if id.lowercased().hasPrefix(q) { return 70 }
        if officialEnglishName.lowercased().contains(q) { return 50 }
        if localNativeName.lowercased().contains(q) { return 45 }
        if city.lowercased().contains(q) { return 30 }
        if countryRegion.lowercased().contains(q) { return 20 }
        if type.lowercased().contains(q) { return 10 }
        return 0
    }
}

/// On-disk wrapper for `universities_hk_japan_v1.json`.
struct CollegeCatalogFile: Codable, Sendable {
    let version: String
    let source: String
    let generated: String
    let regionFocus: String?
    let count: Int?
    let colleges: [CatalogCollege]

    enum CodingKeys: String, CodingKey {
        case version, source, generated, count, colleges
        case regionFocus = "region_focus"
    }
}
