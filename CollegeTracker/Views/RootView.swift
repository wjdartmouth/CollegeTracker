// RootView.swift
import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var context
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if let profile = profiles.first {
                MainTabView(profile: profile)
            } else {
                OnboardingView()
            }
        }
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var role: UserRole = .student

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Hero
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)
                    Text(L10n.tr("College Tracker"))
                        .font(.largeTitle.bold())
                    Text(L10n.tr("Your college journey, organized and intelligent."))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Role picker — counselor tools are deferred (no fake iCloud sharing).
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.tr("I am a..."))
                        .font(.headline)
                    HStack(spacing: 12) {
                        RolePill(role: .student, selected: role == .student) {
                            role = .student
                        }
                        CounselorComingSoonPill()
                    }
                }
                .padding(.horizontal)

                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.tr("Your name"))
                        .font(.headline)
                    TextField(L10n.tr("e.g. Alex Johnson"), text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    createProfile()
                } label: {
                    Text(L10n.tr("Get Started"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    private func createProfile() {
        let profile = UserProfile(name: name.trimmingCharacters(in: .whitespaces), role: .student)
        context.insert(profile)
        try? context.save()
    }
}

struct RolePill: View {
    let role: UserRole
    let selected: Bool
    let onTap: () -> Void

    var label: String { role == .student ? L10n.tr("Student") : L10n.tr("Counselor") }
    var icon: String  { role == .student ? "person.fill" : "person.2.fill" }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                Text(label)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(selected ? Color.blue : Color(.systemGray6))
            .foregroundStyle(selected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        if profile.role == .counselor {
            CounselorComingSoonView(profile: profile)
        } else {
            StudentTabView(profile: profile)
        }
    }
}

struct CounselorComingSoonPill: View {
    var body: some View {
        HStack {
            Image(systemName: "person.2.fill")
            Text(L10n.tr("Counselor"))
            Text(L10n.tr("Coming soon"))
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.2))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .foregroundStyle(.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel(L10n.tr("Counselor, coming soon"))
    }
}

struct CounselorComingSoonView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "person.2.slash")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text(L10n.tr("Counselor tools are coming soon"))
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(L10n.tr("Student–counselor CloudKit sharing is deferred for the first release. Existing counselor profiles can continue as a student to track applications locally."))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button(L10n.tr("Continue as student")) {
                    profile.role = .student
                    try? profile.modelContext?.save()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
            .navigationTitle(L10n.tr("Counselor"))
        }
    }
}

enum StudentTab: Int {
    case dashboard = 0
    case colleges = 1
    case documents = 2
    case progress = 3
    case settings = 4
}

@MainActor
final class StudentTabRouter: ObservableObject {
    static let shared = StudentTabRouter()
    @Published var requested: StudentTab?

    func select(_ tab: StudentTab) {
        requested = tab
    }
}

struct StudentTabView: View {
    let profile: UserProfile
    @State private var selectedTab = StudentTab.dashboard.rawValue
    @ObservedObject private var notificationRouter = NotificationRouter.shared
    @ObservedObject private var tabRouter = StudentTabRouter.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(profile: profile)
                .tabItem { Label(L10n.tr("Dashboard"), systemImage: "square.grid.2x2.fill") }
                .tag(StudentTab.dashboard.rawValue)

            CollegeListView(profile: profile)
                .tabItem { Label(L10n.tr("Colleges"), systemImage: "building.columns.fill") }
                .tag(StudentTab.colleges.rawValue)

            DocumentVaultView(profile: profile)
                .tabItem { Label(L10n.tr("Documents"), systemImage: "folder.fill") }
                .tag(StudentTab.documents.rawValue)

            ProgressDashboardView(profile: profile)
                .tabItem { Label(L10n.tr("Progress"), systemImage: "chart.pie.fill") }
                .tag(StudentTab.progress.rawValue)

            SettingsView(profile: profile)
                .tabItem { Label(L10n.tr("Settings"), systemImage: "gearshape.fill") }
                .tag(StudentTab.settings.rawValue)
        }
        .onChange(of: tabRouter.requested) { _, tab in
            if let tab {
                selectedTab = tab.rawValue
                tabRouter.requested = nil
            }
        }
        .onAppear {
            if notificationRouter.link != nil {
                selectedTab = StudentTab.colleges.rawValue
            }
            NotificationService.shared.requestPermissionAndReschedule(colleges: profile.colleges)
        }
        .onChange(of: notificationRouter.link) { _, link in
            if link != nil {
                selectedTab = StudentTab.colleges.rawValue
            }
        }
    }
}

struct CounselorTabView: View {
    let counselor: UserProfile
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CounselorDashboardView(counselor: counselor)
                .tabItem { Label(L10n.tr("Students"), systemImage: "person.2.fill") }
                .tag(0)

            CounselorOverviewView(counselor: counselor)
                .tabItem { Label(L10n.tr("Overview"), systemImage: "chart.pie.fill") }
                .tag(1)
        }
    }
}
