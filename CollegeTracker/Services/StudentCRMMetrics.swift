// StudentCRMMetrics.swift
import Foundation

enum StudentCRMMetrics {
    struct MonthBucket: Equatable {
        let year: Int
        let month: Int
        let label: String
        let count: Int
    }

    struct DocumentStats: Equatable {
        let total: Int
        let started: Int
        let wordCount: Int
        let jupasApplications: Int
        let personalStatements: Int
        let ejuScores: Int
    }

    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func isUpcoming(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        date >= startOfDay(now, calendar: calendar)
    }

    static func isOverdue(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        date < startOfDay(now, calendar: calendar)
    }

    /// Chronological month buckets (not alphabetical "MMM" sort).
    static func deadlinesByMonth(
        items: [(date: Date, isComplete: Bool)],
        now: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> [MonthBucket] {
        let upcoming = items.filter { !$0.isComplete && isUpcoming($0.date, now: now, calendar: calendar) }
        var counts: [Date: Int] = [:]
        for item in upcoming {
            let comps = calendar.dateComponents([.year, .month], from: item.date)
            guard let start = calendar.date(from: comps) else { continue }
            counts[start, default: 0] += 1
        }
        let years = Set(counts.keys.compactMap { calendar.component(.year, from: $0) })
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateFormat = years.count > 1 ? "MMM yyyy" : "MMM"
        return counts.keys.sorted().map { start in
            MonthBucket(
                year: calendar.component(.year, from: start),
                month: calendar.component(.month, from: start),
                label: formatter.string(from: start),
                count: counts[start] ?? 0
            )
        }
    }

    static func documentStats(from items: [(type: DocumentType, wordCount: Int)]) -> DocumentStats {
        DocumentStats(
            total: items.count,
            started: items.filter { $0.wordCount > 0 }.count,
            wordCount: items.reduce(0) { $0 + $1.wordCount },
            jupasApplications: items.filter { $0.type == .jupasApplication }.count,
            personalStatements: items.filter { $0.type == .personalStatement }.count,
            ejuScores: items.filter { $0.type == .ejuScores }.count
        )
    }
}
