// ProgressDashboardView.swift
import SwiftUI
import Charts

struct ProgressDashboardView: View {
    let profile: UserProfile

    var colleges: [College] { profile.colleges }

    var statusBreakdown: [(status: ApplicationStatus, count: Int)] {
        ApplicationStatus.allCases.compactMap { status in
            let count = colleges.filter { $0.status == status }.count
            return count > 0 ? (status, count) : nil
        }
    }

    var deadlinesByMonth: [(month: String, count: Int)] {
        let allDeadlines = colleges.flatMap(\.deadlines).filter { $0.date > .now }
        var grouped: [String: Int] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        for deadline in allDeadlines {
            let key = formatter.string(from: deadline.date)
            grouped[key, default: 0] += 1
        }
        return grouped.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    var essayStats: (total: Int, withFeedback: Int, wordCount: Int) {
        let essays = colleges.flatMap(\.documents).filter(\.type.supportsAIFeedback)
        return (
            essays.count,
            essays.filter { !$0.feedbackHistory.isEmpty }.count,
            essays.reduce(0) { $0 + $1.wordCount }
        )
    }

    var overallProgress: Double {
        guard !colleges.isEmpty else { return 0 }
        let weights: [ApplicationStatus: Double] = [
            .researching: 0.1,
            .inProgress: 0.3,
            .submitted: 0.6,
            .interviewing: 0.75,
            .accepted: 1.0,
            .waitlisted: 0.8,
            .deferred: 0.65,
            .rejected: 1.0,
            .enrolled: 1.0
        ]
        let total = colleges.reduce(0.0) { $0 + (weights[$1.status] ?? 0) }
        return total / Double(colleges.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Overall progress ring
                    OverallProgressCard(progress: overallProgress, collegeCount: colleges.count)
                        .padding(.horizontal)

                    // Status donut chart
                    if !statusBreakdown.isEmpty {
                        StatusDonutCard(data: statusBreakdown)
                            .padding(.horizontal)
                    }

                    // Deadlines by month bar chart
                    if !deadlinesByMonth.isEmpty {
                        DeadlineBarChartCard(data: deadlinesByMonth)
                            .padding(.horizontal)
                    }

                    // Essay stats
                    EssayStatsCard(stats: essayStats)
                        .padding(.horizontal)

                    // Quick stats grid
                    QuickStatsGrid(colleges: colleges)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
        }
    }
}

// MARK: - Overall Progress Card

struct OverallProgressCard: View {
    let progress: Double
    let collegeCount: Int

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 10)
                    .frame(width: 90, height: 90)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(colors: [.blue, .purple], center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.title3.bold())
                    Text("Done")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Overall Progress")
                    .font(.headline)
                Text("Tracking \(collegeCount) school\(collegeCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ProgressView(value: progress)
                    .tint(.blue)
            }
        }
        .padding(20)
        .cardStyle()
    }
}

// MARK: - Status Donut Chart

struct StatusDonutCard: View {
    let data: [(status: ApplicationStatus, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Application Status")
                .font(.headline)

            HStack(alignment: .center, spacing: 20) {
                Chart(data, id: \.status) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(item.status.color)
                    .cornerRadius(4)
                }
                .frame(width: 130, height: 130)

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(data, id: \.status) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.status.color)
                                .frame(width: 10, height: 10)
                            Text(item.status.rawValue)
                                .font(.caption)
                            Spacer()
                            Text("\(item.count)")
                                .font(.caption.bold())
                        }
                    }
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

// MARK: - Deadline Bar Chart

struct DeadlineBarChartCard: View {
    let data: [(month: String, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Deadlines by Month")
                .font(.headline)

            Chart(data, id: \.month) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Deadlines", item.count)
                )
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple], startPoint: .bottom, endPoint: .top)
                )
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text("\(item.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 140)
            .chartYAxis(.hidden)
        }
        .padding(20)
        .cardStyle()
    }
}

// MARK: - Essay Stats Card

struct EssayStatsCard: View {
    let stats: (total: Int, withFeedback: Int, wordCount: Int)

    var feedbackRatio: Double {
        stats.total > 0 ? Double(stats.withFeedback) / Double(stats.total) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Essay Progress", systemImage: "doc.text.fill")
                .font(.headline)

            HStack(spacing: 0) {
                EssayStat(value: "\(stats.total)", label: "Essays", color: .blue)
                Divider().frame(height: 40)
                EssayStat(value: "\(stats.withFeedback)", label: "Reviewed", color: .purple)
                Divider().frame(height: 40)
                EssayStat(value: "\(stats.wordCount)", label: "Words", color: .green)
            }

            if stats.total > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("AI Feedback Coverage")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(feedbackRatio * 100))%")
                            .font(.caption.bold())
                            .foregroundStyle(.purple)
                    }
                    ProgressView(value: feedbackRatio)
                        .tint(.purple)
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct EssayStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Stats Grid

struct QuickStatsGrid: View {
    let colleges: [College]

    var acceptedCount: Int  { colleges.filter { $0.status == .accepted || $0.status == .enrolled }.count }
    var submittedCount: Int { colleges.filter { $0.status == .submitted }.count }
    var overdueCount: Int {
        colleges.flatMap(\.deadlines)
            .filter { !$0.isComplete && $0.date < .now }.count
    }
    var completedDeadlines: Int {
        colleges.flatMap(\.deadlines).filter(\.isComplete).count
    }

    var body: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            QuickStat(value: acceptedCount, label: "Accepted / Enrolled",
                      icon: "checkmark.seal.fill", color: .green)
            QuickStat(value: submittedCount, label: "Submitted",
                      icon: "paperplane.fill", color: .purple)
            QuickStat(value: completedDeadlines, label: "Deadlines Met",
                      icon: "calendar.badge.checkmark", color: .blue)
            QuickStat(value: overdueCount, label: "Overdue",
                      icon: "exclamationmark.circle.fill", color: overdueCount > 0 ? .red : .secondary)
        }
    }
}

struct QuickStat: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .cardStyle()
    }
}
