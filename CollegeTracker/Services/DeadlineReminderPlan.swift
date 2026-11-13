// DeadlineReminderPlan.swift
import Foundation

/// Pure reminder policy for local (non-critical) deadline notifications.
enum DeadlineReminderPlan {
    static let leadDays = [30, 7, 1, 0]
    static let reminderHour = 9
    static let reminderMinute = 0

    static func requestID(deadlineID: UUID, daysBefore: Int) -> String {
        "\(deadlineID.uuidString)-\(daysBefore)"
    }

    static func requestIDs(deadlineID: UUID) -> [String] {
        leadDays.map { requestID(deadlineID: deadlineID, daysBefore: $0) }
    }

    /// Titles name the deadline type (JUPAS, EJU, etc.) rather than a generic "deadline".
    static func title(daysBefore: Int, displayTitle: String) -> String {
        switch daysBefore {
        case 30: return "\(displayTitle) in 30 days"
        case 7:  return "\(displayTitle) in 1 week"
        case 1:  return "\(displayTitle) is tomorrow"
        case 0:  return "\(displayTitle) is today"
        default: return displayTitle
        }
    }

    static func body(collegeName: String, dateText: String) -> String {
        "\(collegeName) · \(dateText)"
    }

    /// Lead times whose 9:00 fire date is still in the future.
    static func upcomingLeadDays(deadlineDate: Date, now: Date = .now, calendar: Calendar = .current) -> [Int] {
        leadDays.filter { days in
            guard let reminderDay = calendar.date(byAdding: .day, value: -days, to: deadlineDate) else {
                return false
            }
            var components = calendar.dateComponents([.year, .month, .day], from: reminderDay)
            components.hour = reminderHour
            components.minute = reminderMinute
            guard let fireDate = calendar.date(from: components) else { return false }
            return fireDate > now
        }
    }

    static func shouldSchedule(isComplete: Bool, deadlineDate: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        !isComplete && !upcomingLeadDays(deadlineDate: deadlineDate, now: now, calendar: calendar).isEmpty
    }
}
