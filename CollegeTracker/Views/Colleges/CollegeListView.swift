// CollegeListView.swift
import SwiftUI
import SwiftData

struct CollegeListView: View {
    let profile: UserProfile
    @State private var showAddCollege = false
    @State private var searchText = ""
    @State private var selectedStatus: ApplicationStatus? = nil
    @State private var showCompare = false
    @State private var compareSelection: Set<College> = []
    @State private var isCompareMode = false

    var filteredColleges: [College] {
        var result = profile.colleges
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if let status = selectedStatus {
            result = result.filter { $0.status == status }
        }
        return result.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status filter chips
                StatusFilterBar(selected: $selectedStatus)

                List {
                    ForEach(filteredColleges) { college in
                        if isCompareMode {
                            Button {
                                if compareSelection.contains(college) {
                                    compareSelection.remove(college)
                                } else if compareSelection.count < 3 {
                                    compareSelection.insert(college)
                                }
                            } label: {
                                HStack {
                                    CollegeRowView(college: college)
                                    Spacer()
                                    Image(systemName: compareSelection.contains(college) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(compareSelection.contains(college) ? .blue : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(destination: CollegeDetailView(college: college)) {
                                CollegeRowView(college: college)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                    .onDelete { indexSet in
                        deleteColleges(at: indexSet, from: filteredColleges)
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search colleges")
            }
            .navigationTitle("Colleges (\(profile.colleges.count))")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isCompareMode ? "Done" : "Compare") {
                        isCompareMode.toggle()
                        if !isCompareMode { compareSelection.removeAll() }
                    }
                    .foregroundStyle(.blue)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddCollege = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if isCompareMode && compareSelection.count >= 2 {
                    CompareButton(count: compareSelection.count) {
                        showCompare = true
                    }
                    .padding(.bottom, 20)
                }
            }
            .sheet(isPresented: $showAddCollege) {
                AddCollegeView(profile: profile)
            }
            .sheet(isPresented: $showCompare) {
                CollegeCompareView(colleges: Array(compareSelection))
            }
        }
    }

    @Environment(\.modelContext) private var context

    private func deleteColleges(at offsets: IndexSet, from list: [College]) {
        for index in offsets {
            let college = list[index]
            NotificationService.shared.cancelAllReminders(for: college)
            context.delete(college)
        }
        try? context.save()
    }
}

// MARK: - Status Filter Bar

struct StatusFilterBar: View {
    @Binding var selected: ApplicationStatus?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", color: .blue, selected: selected == nil) {
                    selected = nil
                }
                ForEach(ApplicationStatus.allCases) { status in
                    FilterChip(label: status.rawValue, color: status.color,
                                selected: selected == status) {
                        selected = selected == status ? nil : status
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}

struct FilterChip: View {
    let label: String
    let color: Color
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? color : color.opacity(0.1))
                .foregroundStyle(selected ? .white : color)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Compare Button

struct CompareButton: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                Text("Compare \(count) Schools")
                    .font(.headline)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(color: .blue.opacity(0.4), radius: 12, y: 4)
        }
    }
}

// MARK: - Add College View

struct AddCollegeView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var status: ApplicationStatus = .researching
    @State private var acceptanceRate = ""
    @State private var ranking = ""
    @State private var portalURL = ""
    @State private var notes = ""

    // Initial deadline
    @State private var addDeadline = true
    @State private var deadlineType: DeadlineType = .regularDecision
    @State private var deadlineDate = Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                Section("School Info") {
                    TextField("College name", text: $name)
                    Picker("Status", selection: $status) {
                        ForEach(ApplicationStatus.allCases) { s in
                            Label(s.rawValue, systemImage: s.icon).tag(s)
                        }
                    }
                }

                Section("Details (optional)") {
                    HStack {
                        Text("Acceptance Rate")
                        Spacer()
                        TextField("e.g. 8.7", text: $acceptanceRate)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        Text("%").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("US News Rank")
                        Spacer()
                        TextField("e.g. 3", text: $ranking)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    TextField("Application portal URL", text: $portalURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }

                Section("First Deadline") {
                    Toggle("Add a deadline", isOn: $addDeadline)
                    if addDeadline {
                        Picker("Type", selection: $deadlineType) {
                            ForEach(DeadlineType.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        DatePicker("Date", selection: $deadlineDate, displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Add College")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }.disabled(name.isEmpty)
                }
            }
        }
    }

    private func save() {
        let college = College(name: name.trimmingCharacters(in: .whitespaces))
        college.status = status
        college.acceptanceRate = Double(acceptanceRate)
        college.ranking = Int(ranking)
        college.portalURL = portalURL.isEmpty ? nil : portalURL
        college.notes = notes
        college.profile = profile

        if addDeadline {
            let deadline = Deadline(type: deadlineType, date: deadlineDate)
            deadline.college = college
            college.deadlines.append(deadline)
            NotificationService.shared.scheduleReminders(for: deadline, collegeName: college.name)
        }

        profile.colleges.append(college)
        context.insert(college)
        try? context.save()
        dismiss()
    }
}
