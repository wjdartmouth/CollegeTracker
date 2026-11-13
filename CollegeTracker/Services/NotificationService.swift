// NotificationService.swift
import UserNotifications
import SwiftUI

class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermission() {
        requestPermission { _ in }
    }

    enum AuthorizationState {
        case allowed, denied, unknown
    }

    /// Does not prompt. `notDetermined` is `.unknown` so first-run UI does not show a "denied" banner.
    func currentAuthorizationState(completion: @escaping (AuthorizationState) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let state: AuthorizationState
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                state = .allowed
            case .denied:
                state = .denied
            default:
                state = .unknown
            }
            DispatchQueue.main.async { completion(state) }
        }
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error { print("Notification permission error: \(error)") }
                    completion(granted)
                }
            @unknown default:
                completion(false)
            }
        }
    }

    /// Request (or confirm) notification permission, then rebuild local reminders for every incomplete upcoming deadline.
    func requestPermissionAndReschedule(colleges: [College]) {
        requestPermission { granted in
            guard granted else { return }
            self.rescheduleReminders(for: colleges)
        }
    }

    /// Local reminders only — never `.defaultCritical`. Critical Alerts need a special entitlement this app does not use.
    func scheduleReminders(for deadline: Deadline, collegeName: String) {
        cancelReminders(for: deadline)
        guard DeadlineReminderPlan.shouldSchedule(isComplete: deadline.isComplete, deadlineDate: deadline.date) else {
            return
        }

        let dateText = deadline.date.mediumFormatted
        for days in DeadlineReminderPlan.upcomingLeadDays(deadlineDate: deadline.date) {
            let content = UNMutableNotificationContent()
            content.title = DeadlineReminderPlan.title(daysBefore: days, displayTitle: deadline.displayTitle)
            content.body = DeadlineReminderPlan.body(collegeName: collegeName, dateText: dateText)
            content.sound = .default
            content.userInfo = ["deadlineID": deadline.id.uuidString]

            var components = Calendar.current.dateComponents(
                [.year, .month, .day],
                from: Calendar.current.date(byAdding: .day, value: -days, to: deadline.date) ?? deadline.date
            )
            components.hour = DeadlineReminderPlan.reminderHour
            components.minute = DeadlineReminderPlan.reminderMinute

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: DeadlineReminderPlan.requestID(deadlineID: deadline.id, daysBefore: days),
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelReminders(for deadline: Deadline) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: DeadlineReminderPlan.requestIDs(deadlineID: deadline.id)
        )
    }

    func cancelAllReminders(for college: College) {
        let ids = college.deadlines.flatMap { DeadlineReminderPlan.requestIDs(deadlineID: $0.id) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func rescheduleReminders(for colleges: [College]) {
        for college in colleges {
            cancelAllReminders(for: college)
            for deadline in college.deadlines {
                scheduleReminders(for: deadline, collegeName: college.name)
            }
        }
    }

    func pendingCount() async -> Int {
        await UNUserNotificationCenter.current().pendingNotificationRequests().count
    }
}
