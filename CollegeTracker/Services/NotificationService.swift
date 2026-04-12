// NotificationService.swift
import UserNotifications
import SwiftUI

class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error { print("Notification permission error: \(error)") }
            }
    }

    // Schedule reminders at 30d, 7d, 1d, and day-of
    func scheduleReminders(for deadline: Deadline, collegeName: String) {
        let intervals: [(days: Int, title: String)] = [
            (30, "📅 30 days until deadline"),
            (7,  "⏰ 1 week until deadline"),
            (1,  "⚠️ Deadline tomorrow!"),
            (0,  "🚨 Deadline today!")
        ]

        for interval in intervals {
            guard let reminderDate = Calendar.current.date(
                byAdding: .day, value: -interval.days, to: deadline.date),
                  reminderDate > .now else { continue }

            let content = UNMutableNotificationContent()
            content.title = interval.title
            content.body  = "\(collegeName) — \(deadline.displayTitle)"
            content.sound = interval.days <= 1 ? .defaultCritical : .default
            content.userInfo = ["deadlineID": deadline.id.uuidString]

            var components = Calendar.current.dateComponents(
                [.year, .month, .day], from: reminderDate)
            components.hour   = 9
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let requestID = "\(deadline.id.uuidString)-\(interval.days)"
            let request = UNNotificationRequest(identifier: requestID,
                                                content: content,
                                                trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelReminders(for deadline: Deadline) {
        let ids = [30, 7, 1, 0].map { "\(deadline.id.uuidString)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func cancelAllReminders(for college: College) {
        let ids = college.deadlines.flatMap { deadline in
            [30, 7, 1, 0].map { "\(deadline.id.uuidString)-\($0)" }
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func pendingCount() async -> Int {
        await UNUserNotificationCenter.current().pendingNotificationRequests().count
    }
}
