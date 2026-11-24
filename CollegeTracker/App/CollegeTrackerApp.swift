// CollegeTrackerApp.swift
import SwiftUI
import SwiftData
import UserNotifications
import Combine

@main
struct CollegeTrackerApp: App {
    @State private var notificationDelegate: NotificationDelegate

    init() {
        let delegate = NotificationDelegate()
        // Set before the first frame so a cold start from a reminder still receives the tap.
        UNUserNotificationCenter.current().delegate = delegate
        _notificationDelegate = State(initialValue: delegate)
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            College.self,
            Deadline.self,
            Document.self,
            EssayFeedback.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // CloudKit entitlements / container may be missing until Signing & Capabilities is set on a Mac.
            let local = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [local])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    UNUserNotificationCenter.current().delegate = notificationDelegate
                    NotificationService.shared.requestPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// Handles foreground notifications
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    // Provide the required publisher for ObservableObject conformance
    let objectWillChange = ObservableObjectPublisher()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        await MainActor.run {
            NotificationRouter.shared.open(userInfo: info)
        }
    }
}

#Preview {
    RootView()
}
