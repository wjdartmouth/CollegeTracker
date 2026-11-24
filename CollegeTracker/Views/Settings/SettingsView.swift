// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    let profile: UserProfile
    @State private var authorization: NotificationService.AuthorizationState = .unknown

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent(L10n.tr("Your name"), value: profile.name)
                } header: {
                    Text(L10n.tr("About"))
                }

                Section {
                    LabeledContent(L10n.tr("Deadline reminders"), value: statusText)
                        .accessibilityLabel(L10n.tr("Deadline reminders"))
                        .accessibilityValue(statusText)

                    Text(detailText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if authorization == .unknown {
                        Button(L10n.tr("Turn on deadline reminders")) {
                            turnOnReminders()
                        }
                    } else if authorization == .denied {
                        Button(L10n.tr("Open iOS Settings")) {
                            openSystemSettings()
                        }
                    }
                } header: {
                    Text(L10n.tr("Reminders"))
                }

                Section {
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label(L10n.tr("Privacy Policy"), systemImage: "hand.raised.fill")
                    }
                } header: {
                    Text(L10n.tr("Privacy"))
                }

                Section {
                    LabeledContent(L10n.tr("Version"), value: AppVersion.marketingAndBuild)
                }
            }
            .navigationTitle(L10n.tr("Settings"))
            .onAppear { refresh(rescheduleIfAllowed: true) }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                refresh()
            }
        }
    }

    private var statusText: String {
        switch authorization {
        case .allowed: return L10n.tr("On")
        case .denied: return L10n.tr("Off")
        case .unknown: return L10n.tr("Not yet asked")
        }
    }

    private var detailText: String {
        switch authorization {
        case .allowed:
            return L10n.tr("Reminders are on. They stay on this iPhone at 9:00 and are regular notifications, not Critical Alerts.")
        case .denied:
            return L10n.tr("Reminders are off. Turn them on in iOS Settings. These are regular notifications, not Critical Alerts.")
        case .unknown:
            return L10n.tr("Deadline reminders ask for permission the first time. They are regular local notifications at 9:00, not Critical Alerts.")
        }
    }

    private func refresh(rescheduleIfAllowed: Bool = false) {
        NotificationService.shared.currentAuthorizationState { state in
            authorization = state
            if rescheduleIfAllowed, state == .allowed {
                NotificationService.shared.rescheduleReminders(for: profile.colleges)
            }
        }
    }

    private func turnOnReminders() {
        NotificationService.shared.requestPermission { granted in
            Task { @MainActor in
                if granted {
                    NotificationService.shared.rescheduleReminders(for: profile.colleges)
                }
                refresh()
            }
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

enum AppVersion {
    static var marketingAndBuild: String {
        let marketing = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(marketing) (\(build))"
    }
}

struct PrivacyPolicyView: View {
    private struct SectionText: Identifiable {
        let id: String
        let title: String
        let body: String
    }

    private var sections: [SectionText] {
        [
            SectionText(
                id: "device",
                title: L10n.tr("On this iPhone"),
                body: L10n.tr("College Tracker keeps your schools, deadlines, documents, and notes on this iPhone. There is no account, and the developer does not receive that store.")
            ),
            SectionText(
                id: "icloud",
                title: L10n.tr("Private iCloud"),
                body: L10n.tr("If iCloud is turned on for this app, the same store can sync to your private iCloud database. The developer does not read that database.")
            ),
            SectionText(
                id: "reminders",
                title: L10n.tr("Local reminders"),
                body: L10n.tr("Deadline reminders are scheduled on this device. They are ordinary notifications, not Critical Alerts. Reminder text is not sent to the developer.")
            ),
            SectionText(
                id: "catalog",
                title: L10n.tr("Bundled catalog"),
                body: L10n.tr("School names and pathway notes are bundled in the app. The app does not download a catalog and does not contact a College Tracker server.")
            ),
            SectionText(
                id: "essay",
                title: L10n.tr("Essay feedback"),
                body: L10n.tr("Essay feedback is coming soon. This version does not send essay text off this iPhone.")
            ),
            SectionText(
                id: "tracking",
                title: L10n.tr("Tracking and ads"),
                body: L10n.tr("The app does not track you, show ads, or sell personal data.")
            ),
            SectionText(
                id: "contact",
                title: L10n.tr("Contact"),
                body: L10n.tr("Questions go to the support link on the App Store page. This screen does not list a postal address.")
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.title)
                            .font(.headline)
                        Text(section.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding()
        }
        .navigationTitle(L10n.tr("Privacy Policy"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
