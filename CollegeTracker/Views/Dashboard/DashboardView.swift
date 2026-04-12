// DashboardView.swift
import SwiftUI
import SwiftData

struct DashboardView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @State private var showAddCollege = false

    var colleges: [College] { profile.colleges }

    var upcomingDeadlines: [(deadline: Deadline, college: College)] {
        colleges.flatMap { college in
            college.deadlines
                .filter { !$0.isComplete && $0.date >= Calendar.current.startOfDay(for: .now) }
                .map { (deadline: $0, college: college) }
        }
        .sorted { $0.deadline.date < $1.deadline.date }
        .prefix(8)
        .map { $0 }
    }

    var completedCount: Int { colleges.filter { $0.status == .accepted || $0.status == .enrolled }.count }
    var submittedCount: Int { colleges.filter { $0.status == .submitted || $0.status == .interviewing }.count }
    var inProgressCount: Int { colleges.filter { $0.status == .inProgress }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Greeting
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greeting)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text(profile.name)
                            .font(.largeTitle.bold())
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Stats row
                    HStack(spacing: 12) {
                        StatCard(value: colleges.count, label: "Schools", icon: "building.columns.fill", color: .blue)
                        StatCard(value: submittedCount, label: "Submitted", icon: "paperplane.fill", color: .purple)
                        StatCard(value: completedCount, label: "Decisions", icon: "checkmark.seal.fill", color: .green)
                    }
                    .padding(.horizontal)

                    // Upcoming deadlines
                    if !upcomingDeadlines.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Upcoming Deadlines", icon: "calendar.badge.clock")
                            DeadlineTimelineView(items: upcomingDeadlines)
                        }
                        .padding(.horizontal)
                    }

                    // College status board
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SectionHeader(title: "My Colleges", icon: "building.columns")
                            Spacer()
                            Button {
                                showAddCollege = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title3)
                            }
                        }
                        .padding(.horizontal)

                        if colleges.isEmpty {
                            EmptyStateView(
                                icon: "building.columns",
                                title: "No colleges yet",
                                subtitle: "Tap + to add your first school"
                            )
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(colleges.sorted { $0.createdAt > $1.createdAt }) { college in
                                    NavigationLink(destination: CollegeDetailView(college: college)) {
                                        CollegeRowView(college: college)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddCollege = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCollege) {
                AddCollegeView(profile: profile)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
    }
}

// MARK: - Deadline Timeline

struct DeadlineTimelineView: View {
    let items: [(deadline: Deadline, college: College)]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(items, id: \.deadline.id) { item in
                    DeadlineCard(deadline: item.deadline, collegeName: item.college.name,
                                 collegeColor: Color(hex: item.college.logoColorHex))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }
}

struct DeadlineCard: View {
    let deadline: Deadline
    let collegeName: String
    let collegeColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: deadline.type.icon)
                    .font(.caption)
                    .foregroundStyle(collegeColor)
                Spacer()
                Text(deadline.urgencyLabel)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(deadline.urgencyColor.opacity(0.15))
                    .foregroundStyle(deadline.urgencyColor)
                    .clipShape(Capsule())
            }

            Text(collegeName)
                .font(.subheadline.bold())
                .lineLimit(1)
            Text(deadline.displayTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(deadline.date.mediumFormatted)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(width: 160)
        .cardStyle()
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
    }
}

// MARK: - College Row

struct CollegeRowView: View {
    let college: College

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: college.logoColorHex).opacity(0.2))
                    .frame(width: 46, height: 46)
                Text(college.abbreviation)
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: college.logoColorHex))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(college.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                if let deadline = college.nearestDeadline {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(deadline.displayTitle + " · " + deadline.date.shortFormatted)
                            .font(.caption)
                    }
                    .foregroundStyle(deadline.urgencyColor)
                } else {
                    Text("No upcoming deadlines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Status badge
            HStack(spacing: 4) {
                Image(systemName: college.status.icon)
                    .font(.caption2)
                Text(college.status.rawValue)
                    .font(.caption2.bold())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(college.status.color.opacity(0.15))
            .foregroundStyle(college.status.color)
            .clipShape(Capsule())
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}
