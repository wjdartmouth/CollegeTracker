// CollegeTrackerApp.swift
import SwiftUI
import SwiftData
import UserNotifications

@main
struct CollegeTrackerApp: App {
    @State private var notificationDelegate = NotificationDelegate()

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
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    NotificationService.shared.requestPermission()
                    UNUserNotificationCenter.current().delegate = notificationDelegate
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// Handles foreground notifications
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }
}

#Preview {
    RootView()
}
