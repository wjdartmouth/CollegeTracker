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
    @State private var step = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Hero
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)
                    Text("College Tracker")
                        .font(.largeTitle.bold())
                    Text("Your college journey, organized and intelligent.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Role picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("I am a...")
                        .font(.headline)
                    HStack(spacing: 12) {
                        ForEach([UserRole.student, .counselor], id: \.self) { r in
                            RolePill(role: r, selected: role == r) {
                                role = r
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your name")
                        .font(.headline)
                    TextField("e.g. Alex Johnson", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    createProfile()
                } label: {
                    Text("Get Started")
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
        let profile = UserProfile(name: name.trimmingCharacters(in: .whitespaces), role: role)
        context.insert(profile)
        try? context.save()
    }
}

struct RolePill: View {
    let role: UserRole
    let selected: Bool
    let onTap: () -> Void

    var label: String { role == .student ? "Student" : "Counselor" }
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
    let profile: UserProfile

    var body: some View {
        if profile.role == .counselor {
            CounselorTabView(counselor: profile)
        } else {
            StudentTabView(profile: profile)
        }
    }
}

struct StudentTabView: View {
    let profile: UserProfile
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(profile: profile)
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
                .tag(0)

            CollegeListView(profile: profile)
                .tabItem { Label("Colleges", systemImage: "building.columns.fill") }
                .tag(1)

            DocumentVaultView(profile: profile)
                .tabItem { Label("Documents", systemImage: "folder.fill") }
                .tag(2)

            ProgressDashboardView(profile: profile)
                .tabItem { Label("Progress", systemImage: "chart.pie.fill") }
                .tag(3)
        }
    }
}

struct CounselorTabView: View {
    let counselor: UserProfile
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CounselorDashboardView(counselor: counselor)
                .tabItem { Label("Students", systemImage: "person.2.fill") }
                .tag(0)

            CounselorOverviewView(counselor: counselor)
                .tabItem { Label("Overview", systemImage: "chart.pie.fill") }
                .tag(1)
        }
    }
}
