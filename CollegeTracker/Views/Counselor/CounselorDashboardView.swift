// CounselorDashboardView.swift
import SwiftUI
import SwiftData
import Charts

// MARK: - Counselor Dashboard

struct CounselorDashboardView: View {
    let counselor: UserProfile
    @Query private var allProfiles: [UserProfile]
    @Environment(\.modelContext) private var context
    @State private var showAddStudent = false

    var managedStudents: [UserProfile] {
        allProfiles.filter {
            $0.role == .student && counselor.managedStudentIDs.contains($0.id.uuidString)
        }
        .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Group {
                if managedStudents.isEmpty {
                    EmptyStateView(
                        icon: "person.2.fill",
                        title: "No students yet",
                        subtitle: "Tap + to add your first student"
                    )
                } else {
                    List {
                        ForEach(managedStudents) { student in
                            NavigationLink(destination: StudentDetailView(student: student)) {
                                StudentRowView(student: student)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: removeStudents)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Students")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddStudent = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddStudent) {
                AddStudentView(counselor: counselor)
            }
        }
    }

    private func removeStudents(at offsets: IndexSet) {
        let students = managedStudents
        for index in offsets {
            counselor.managedStudentIDs.removeAll { $0 == students[index].id.uuidString }
        }
        try? context.save()
    }
}

// MARK: - Student Row

struct StudentRowView: View {
    let student: UserProfile

    private var colleges: [College] { student.colleges }

    private var overallProgress: Double {
        guard !colleges.isEmpty else { return 0 }
        let weights: [ApplicationStatus: Double] = [
            .researching: 0.1, .inProgress: 0.3, .submitted: 0.6,
            .interviewing: 0.75, .accepted: 1.0, .waitlisted: 0.8,
            .deferred: 0.65, .rejected: 1.0, .enrolled: 1.0
        ]
        return colleges.reduce(0.0) { $0 + (weights[$1.status] ?? 0) } / Double(colleges.count)
    }

    private var nearestDeadline: (deadline: Deadline, college: College)? {
        colleges.flatMap { c in
            c.deadlines.filter { !$0.isComplete && $0.date >= .now }.map { (deadline: $0, college: c) }
        }
        .min { $0.deadline.date < $1.deadline.date }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 46, height: 46)
                Text(student.name.prefix(1).uppercased())
                    .font(.title3.bold())
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.subheadline.bold())
                if let next = nearestDeadline {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar").font(.caption2)
                        Text(next.college.name + " · " + next.deadline.urgencyLabel).font(.caption)
                    }
                    .foregroundStyle(next.deadline.urgencyColor)
                } else {
                    Text("\(colleges.count) school\(colleges.count == 1 ? "" : "s") tracked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 4)
                    .frame(width: 36, height: 36)
                Circle()
                    .trim(from: 0, to: overallProgress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(overallProgress * 100))%")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.blue)
            }
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Add Student

struct AddStudentView: View {
    let counselor: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Student Info") {
                    TextField("Student name", text: $name)
                }
                Section {
                    Text("This creates a local student profile you can track. The student can sign in on their own device and their data will sync via iCloud.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let student = UserProfile(name: name.trimmingCharacters(in: .whitespaces), role: .student)
        context.insert(student)
        counselor.managedStudentIDs.append(student.id.uuidString)
        try? context.save()
        dismiss()
    }
}

// MARK: - Student Detail (read-only)

struct StudentDetailView: View {
    let student: UserProfile

    private var colleges: [College] { student.colleges }

    private var upcomingDeadlines: [(deadline: Deadline, college: College)] {
        colleges.flatMap { c in
            c.deadlines
                .filter { !$0.isComplete && $0.date >= Calendar.current.startOfDay(for: .now) }
                .map { (deadline: $0, college: c) }
        }
        .sorted { $0.deadline.date < $1.deadline.date }
        .prefix(8)
        .map { $0 }
    }

    private var essays: [Document] {
        colleges.flatMap(\.documents).filter(\.type.supportsAIFeedback)
    }

    private var overallProgress: Double {
        guard !colleges.isEmpty else { return 0 }
        let weights: [ApplicationStatus: Double] = [
            .researching: 0.1, .inProgress: 0.3, .submitted: 0.6,
            .interviewing: 0.75, .accepted: 1.0, .waitlisted: 0.8,
            .deferred: 0.65, .rejected: 1.0, .enrolled: 1.0
        ]
        return colleges.reduce(0.0) { $0 + (weights[$1.status] ?? 0) } / Double(colleges.count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                StudentHeaderCard(student: student, progress: overallProgress, collegeCount: colleges.count)
                    .padding(.horizontal)

                if !upcomingDeadlines.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Upcoming Deadlines", icon: "calendar.badge.clock")
                            .padding(.horizontal)
                        DeadlineTimelineView(items: upcomingDeadlines)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Colleges (\(colleges.count))", icon: "building.columns")
                        .padding(.horizontal)
                    if colleges.isEmpty {
                        EmptyStateView(
                            icon: "building.columns",
                            title: "No colleges added",
                            subtitle: "The student hasn't added any schools yet"
                        )
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(colleges.sorted { $0.createdAt > $1.createdAt }) { college in
                                CounselorCollegeRowView(college: college)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }

                if !essays.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Essays (\(essays.count))", icon: "doc.text.fill")
                            .padding(.horizontal)
                        LazyVStack(spacing: 8) {
                            ForEach(essays) { doc in
                                CounselorEssayRowView(document: doc)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(student.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Student Header Card

struct StudentHeaderCard: View {
    let student: UserProfile
    let progress: Double
    let collegeCount: Int

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 64, height: 64)
                Text(student.name.prefix(1).uppercased())
                    .font(.largeTitle.bold())
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(student.name)
                    .font(.title2.bold())
                Text("Added \(student.createdAt.mediumFormatted)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Label("\(collegeCount) school\(collegeCount == 1 ? "" : "s")", systemImage: "building.columns.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("\(Int(progress * 100))% complete", systemImage: "chart.pie.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Counselor College Row (read-only)

struct CounselorCollegeRowView: View {
    let college: College

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: college.logoColorHex).opacity(0.2))
                    .frame(width: 42, height: 42)
                Text(college.abbreviation)
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: college.logoColorHex))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(college.name)
                    .font(.subheadline.bold())
                if let deadline = college.nearestDeadline {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar").font(.caption2)
                        Text(deadline.displayTitle + " · " + deadline.date.shortFormatted).font(.caption)
                    }
                    .foregroundStyle(deadline.urgencyColor)
                } else {
                    Text("No upcoming deadlines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: college.status.icon).font(.caption2)
                Text(college.status.rawValue).font(.caption2.bold())
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

// MARK: - Counselor Essay Row (read-only)

struct CounselorEssayRowView: View {
    let document: Document

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: document.type.icon)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(document.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text("\(document.wordCount) words")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !document.feedbackHistory.isEmpty {
                        Label("\(document.feedbackHistory.count) AI feedback", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                }
            }

            Spacer()

            if let college = document.college {
                Text(college.abbreviation)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: college.logoColorHex).opacity(0.15))
                    .foregroundStyle(Color(hex: college.logoColorHex))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Counselor Overview

struct CounselorOverviewView: View {
    let counselor: UserProfile
    @Query private var allProfiles: [UserProfile]

    var managedStudents: [UserProfile] {
        allProfiles.filter {
            $0.role == .student && counselor.managedStudentIDs.contains($0.id.uuidString)
        }
    }

    private var allColleges: [College] { managedStudents.flatMap(\.colleges) }

    private var statusBreakdown: [(status: ApplicationStatus, count: Int)] {
        ApplicationStatus.allCases.compactMap { status in
            let count = allColleges.filter { $0.status == status }.count
            return count > 0 ? (status, count) : nil
        }
    }

    private var upcomingDeadlines: [(deadline: Deadline, college: College, student: UserProfile)] {
        managedStudents.flatMap { student in
            student.colleges.flatMap { college in
                college.deadlines
                    .filter { !$0.isComplete && $0.date >= Calendar.current.startOfDay(for: .now) }
                    .map { (deadline: $0, college: college, student: student) }
            }
        }
        .sorted { $0.deadline.date < $1.deadline.date }
        .prefix(10)
        .map { $0 }
    }

    private var overdueCount: Int {
        allColleges.flatMap(\.deadlines).filter { !$0.isComplete && $0.date < .now }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary stats
                    HStack(spacing: 12) {
                        StatCard(value: managedStudents.count, label: "Students", icon: "person.2.fill", color: .blue)
                        StatCard(value: allColleges.count, label: "Schools", icon: "building.columns.fill", color: .purple)
                        StatCard(value: overdueCount, label: "Overdue", icon: "exclamationmark.circle.fill",
                                 color: overdueCount > 0 ? .red : .secondary)
                    }
                    .padding(.horizontal)

                    // Upcoming deadlines across all students
                    if !upcomingDeadlines.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "All Upcoming Deadlines", icon: "calendar.badge.clock")
                                .padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(upcomingDeadlines, id: \.deadline.id) { item in
                                        CounselorDeadlineCard(
                                            deadline: item.deadline,
                                            collegeName: item.college.name,
                                            studentName: item.student.name,
                                            collegeColor: Color(hex: item.college.logoColorHex)
                                        )
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    // Status breakdown across all students
                    if !statusBreakdown.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Applications by Status", icon: "chart.pie.fill")
                            HStack(alignment: .center, spacing: 20) {
                                Chart(statusBreakdown, id: \.status) { item in
                                    SectorMark(
                                        angle: .value("Count", item.count),
                                        innerRadius: .ratio(0.55),
                                        angularInset: 2
                                    )
                                    .foregroundStyle(item.status.color)
                                    .cornerRadius(4)
                                }
                                .frame(width: 130, height: 130)
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(statusBreakdown, id: \.status) { item in
                                        HStack(spacing: 8) {
                                            Circle().fill(item.status.color).frame(width: 10, height: 10)
                                            Text(item.status.rawValue).font(.caption)
                                            Spacer()
                                            Text("\(item.count)").font(.caption.bold())
                                        }
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .cardStyle()
                        .padding(.horizontal)
                    }

                    if managedStudents.isEmpty {
                        EmptyStateView(
                            icon: "chart.pie",
                            title: "No data yet",
                            subtitle: "Add students from the Students tab to see their progress here"
                        )
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Overview")
        }
    }
}

// MARK: - Counselor Deadline Card (shows student name)

struct CounselorDeadlineCard: View {
    let deadline: Deadline
    let collegeName: String
    let studentName: String
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
            HStack(spacing: 4) {
                Image(systemName: "person.fill").font(.caption2).foregroundStyle(.secondary)
                Text(studentName).font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .frame(width: 160)
        .cardStyle()
    }
}
