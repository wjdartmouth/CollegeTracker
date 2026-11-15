// L10n.swift
import Foundation

/// User-facing copy for College Tracker.
///
/// Keys are the English source strings in `Localizable.xcstrings` (en, ja, zh-Hant).
/// `Bundle.main` resolves the compiled catalog. If a key is missing, the English key is returned,
/// so development-language UI and unit tests still read as English.
enum L10n {
    nonisolated static func tr(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: "Localizable")
    }

    nonisolated static func format(_ key: String, _ args: CVarArg...) -> String {
        let template = tr(key)
        return String(format: template, locale: .current, arguments: args)
    }

    /// English needs distinct one/other strings. Japanese and Traditional Chinese use the same phrase for both keys.
    nonisolated static func plural(_ count: Int, one: String, other: String) -> String {
        format(count == 1 ? one : other, count)
    }

    /// Localizes known catalog place names. Other cities stay as published in the catalog.
    nonisolated static func regionName(_ raw: String) -> String {
        switch raw {
        case "Hong Kong SAR", "Japan", "Hong Kong":
            return tr(raw)
        default:
            return raw
        }
    }
}
