// NotificationRouter.swift
import Foundation

struct DeadlineNotificationLink: Equatable {
    let collegeID: UUID?
    let deadlineID: UUID
}

/// Keys stored on a local deadline reminder. Tapping the notification rebuilds `DeadlineNotificationLink`.
enum NotificationPayload {
    static let deadlineIDKey = "deadlineID"
    static let collegeIDKey = "collegeID"

    static func userInfo(deadlineID: UUID, collegeID: UUID?) -> [String: String] {
        var info = [deadlineIDKey: deadlineID.uuidString]
        if let collegeID {
            info[collegeIDKey] = collegeID.uuidString
        }
        return info
    }

    static func link(from userInfo: [AnyHashable: Any]) -> DeadlineNotificationLink? {
        guard let rawDeadline = userInfo[deadlineIDKey] as? String,
              let deadlineID = UUID(uuidString: rawDeadline) else {
            return nil
        }
        let collegeID = (userInfo[collegeIDKey] as? String).flatMap(UUID.init(uuidString:))
        return DeadlineNotificationLink(collegeID: collegeID, deadlineID: deadlineID)
    }
}

/// Holds the reminder the student just tapped until the colleges tab consumes it.
@MainActor
final class NotificationRouter: ObservableObject {
    static let shared = NotificationRouter()

    @Published private(set) var link: DeadlineNotificationLink?

    func open(userInfo: [AnyHashable: Any]) {
        link = NotificationPayload.link(from: userInfo)
    }

    func clear() {
        link = nil
    }
}
