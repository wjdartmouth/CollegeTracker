// CollegeDetailView.swift
import SwiftUI
import SwiftData

struct CollegeDetailView: View {
    @Bindable var college: College
    @Environment(\.modelContext) private var context
    @State private var showAddDeadline = false
    @State private var showAddDocument = false
    @State private var showEditNotes = false
    @State private var selectedTab = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                CollegeHeaderCard(college: college)

                // Tabs
                Picker("Section", selection: $selectedTab) {
                    Text("Pathways").tag(0)
                    Text("Deadlines").tag(1)
                    Text("Documents").tag(2)
                    Text("Notes").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedTab {
                case 0: PathwaySection(college: college)
                case 1: DeadlinesSection(college: college, showAdd: $showAddDeadline)
                case 2: DocumentsSection(college: college, showAdd: $showAddDocument)
                case 3: NotesSection(college: college)
                default: EmptyView()
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(college.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        if let url = URL(string: college.portalURL ?? ""), !college.portalURL.isNil {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Portal", systemImage: "safari")
                    }
                    .disabled(college.portalURL == nil)

                    Picker("Status", selection: $college.status) {
                        ForEach(ApplicationStatus.allCases) { s in
                            Label(s.rawValue, systemImage: s.icon).tag(s)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddDeadline) {
            AddDeadlineView(college: college)
        }
        .sheet(isPresented: $showAddDocument) {
            AddDocumentView(college: college)
        }
    }
}

extension Optional where Wrapped == String {
    var isNil: Bool { self == nil }
}

// MARK: - Header Card

struct CollegeHeaderCard: View {
    @Bindable var college: College

    var body: some View {
        VStack(spacing: 16) {
            // Logo placeholder
            ZStack {
                Circle()
                    .fill(Color(hex: college.logoColorHex).opacity(0.15))
                    .frame(width: 72, height: 72)
                Text(college.abbreviation)
                    .font(.title2.bold())
                    .foregroundStyle(Color(hex: college.logoColorHex))
            }

            if let native = college.localNativeName, !native.isEmpty {
                Text(native)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let location = college.locationLine {
                Text(location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Status picker
            Menu {
                ForEach(ApplicationStatus.allCases) { status in
                    Button {
                        college.status = status
                    } label: {
                        Label(status.rawValue, systemImage: status.icon)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: college.status.icon)
                    Text(college.status.rawValue)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(college.status.color.opacity(0.15))
                .foregroundStyle(college.status.color)
                .clipShape(Capsule())
            }

            // Stats row
            if college.acceptanceRate != nil || college.rankDisplay != nil {
                HStack(spacing: 24) {
                    if let rate = college.acceptanceRate {
                        VStack {
                            Text("\(rate, specifier: "%.1f")%")
                                .font(.headline.bold())
                            Text("Accept Rate")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let rank = college.rankDisplay {
                        VStack {
                            Text(rank)
                                .font(.headline.bold())
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                                .multilineTextAlignment(.center)
                            Text("QS Rank")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    VStack {
                        Text("\(college.documents.count)")
                            .font(.headline.bold())
                        Text("Docs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .cardStyle()
        .padding(.horizontal)
    }
}

// MARK: - Deadlines Section

struct DeadlinesSection: View {
    @Bindable var college: College
    @Binding var showAdd: Bool
    @Environment(\.modelContext) private var context

    var sortedDeadlines: [Deadline] {
        college.deadlines.sorted { $0.date < $1.date }
    }

    private var emptyDeadlineSubtitle: String {
        switch CatalogRegion.of(college) {
        case .hongKong: return "Tap + to add a JUPAS or Non-JUPAS deadline"
        case .japan: return "Tap + to add an EJU, Common Test, or other deadline"
        case .other: return "Tap + to add a deadline"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Deadlines")
                    .font(.headline)
                Spacer()
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)

            if sortedDeadlines.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.plus",
                    title: "No deadlines",
                    subtitle: emptyDeadlineSubtitle
                )
            } else {
                ForEach(sortedDeadlines) { deadline in
                    DeadlineRowView(deadline: deadline, collegeName: college.name)
                        .contextMenu {
                            Button(role: .destructive) {
                                NotificationService.shared.cancelReminders(for: deadline)
                                context.delete(deadline)
                                try? context.save()
                            } label: {
                                Label("Delete deadline", systemImage: "trash")
                            }
                        }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct DeadlineRowView: View {
    @Bindable var deadline: Deadline
    let collegeName: String

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(deadline.urgencyColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: deadline.type.icon)
                    .font(.subheadline)
                    .foregroundStyle(deadline.urgencyColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(deadline.displayTitle)
                    .font(.subheadline.bold())
                Text(deadline.date.mediumFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Days remaining badge
            Text(deadline.urgencyLabel)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(deadline.urgencyColor.opacity(0.15))
                .foregroundStyle(deadline.urgencyColor)
                .clipShape(Capsule())

            // Complete toggle — keep local reminders in sync
            Button {
                deadline.isComplete.toggle()
                if deadline.isComplete {
                    NotificationService.shared.cancelReminders(for: deadline)
                } else {
                    NotificationService.shared.scheduleReminders(for: deadline, collegeName: collegeName)
                }
            } label: {
                Image(systemName: deadline.isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(deadline.isComplete ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Documents Section

struct DocumentsSection: View {
    @Bindable var college: College
    @Binding var showAdd: Bool
    @Environment(\.modelContext) private var context

    private var emptyDocumentSubtitle: String {
        switch CatalogRegion.of(college) {
        case .hongKong: return "Tap + to add a JUPAS application, personal statement, or school report"
        case .japan: return "Tap + to add a personal statement, EJU scores, or transcript"
        case .other: return "Tap + to add a document"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Documents")
                    .font(.headline)
                Spacer()
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)

            if college.documents.isEmpty {
                EmptyStateView(icon: "doc.badge.plus", title: "No documents", subtitle: emptyDocumentSubtitle)
            } else {
                ForEach(college.documents.sorted { $0.lastEdited > $1.lastEdited }) { doc in
                    NavigationLink(destination: EssayEditorView(document: doc)) {
                        DocumentRowView(document: doc)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct DocumentRowView: View {
    let document: Document

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: document.type.icon)
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(document.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(document.type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if let limit = document.wordLimit {
                    Text("\(document.wordCount)/\(limit)")
                        .font(.caption.bold())
                        .foregroundStyle(document.wordCountStatus.color)
                } else {
                    Text("\(document.wordCount)w")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if document.type.supportsAIFeedback && !document.feedbackHistory.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("\(document.feedbackHistory.count)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.purple)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Notes Section

struct NotesSection: View {
    @Bindable var college: College

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .padding(.horizontal)

            TextEditor(text: $college.notes)
                .frame(minHeight: 200)
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

            Text("Jot down impressions, visit notes, or research.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }
}

// MARK: - Add Deadline View

struct AddDeadlineView: View {
    let college: College
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var type: DeadlineType
    @State private var customLabel = ""
    @State private var date = Calendar.current.date(byAdding: .month, value: 2, to: .now) ?? .now
    @State private var notify = true

    init(college: College) {
        self.college = college
        _type = State(initialValue: DeadlineType.defaultType(for: college))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(DeadlineType.suggested(for: college)) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    if type == .custom {
                        TextField("Label", text: $customLabel)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section {
                    Toggle("Notify me", isOn: $notify)
                    if notify {
                        Text("Local reminders at 9:00 — 30 days, 1 week, 1 day, and the day of the deadline. These are regular notifications, not Critical Alerts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Add Deadline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(type == .custom && customLabel.isEmpty)
                }
            }
        }
    }

    private func save() {
        let deadline = Deadline(type: type, date: date, label: customLabel)
        deadline.college = college
        college.deadlines.append(deadline)
        context.insert(deadline)
        if notify {
            NotificationService.shared.scheduleReminders(for: deadline, collegeName: college.name)
        }
        try? context.save()
        dismiss()
    }
}

// MARK: - Add Document View

struct AddDocumentView: View {
    let college: College
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var type: DocumentType
    @State private var title = ""
    @State private var wordLimit = ""

    init(college: College) {
        self.college = college
        _type = State(initialValue: DocumentType.defaultType(for: college))
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $type) {
                    ForEach(DocumentType.suggested(for: college)) { t in
                        Label(t.rawValue, systemImage: t.icon).tag(t)
                    }
                }

                TextField("Title / Prompt snippet", text: $title)

                HStack {
                    Text("Word Limit")
                    Spacer()
                    TextField("Optional", text: $wordLimit)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }.disabled(title.isEmpty)
                }
            }
        }
    }

    private func save() {
        let doc = Document(type: type, title: title)
        doc.wordLimit = Int(wordLimit)
        doc.college = college
        college.documents.append(doc)
        context.insert(doc)
        try? context.save()
        dismiss()
    }
}

// MARK: - College Compare View

struct CollegeCompareView: View {
    let colleges: [College]
    @Environment(\.dismiss) private var dismiss

    private let rows: [(label: String, value: (College) -> String)] = [
        ("Status",          { $0.status.rawValue }),
        ("Acceptance Rate", { $0.acceptanceRate.map { String(format: "%.1f%%", $0) } ?? "—" }),
        ("QS Rank",         { $0.rankDisplay ?? "—" }),
        ("Location",        { $0.locationLine ?? "—" }),
        ("Deadlines",       { "\($0.deadlines.count)" }),
        ("Documents",       { "\($0.documents.count)" }),
        ("Nearest Deadline",{ $0.nearestDeadline.map { $0.date.shortFormatted } ?? "None" }),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header row
                    HStack(spacing: 0) {
                        Text("").frame(width: 130, alignment: .leading).padding(12)
                        ForEach(colleges) { college in
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle().fill(Color(hex: college.logoColorHex).opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    Text(college.abbreviation)
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color(hex: college.logoColorHex))
                                }
                                Text(college.name)
                                    .font(.caption2.bold())
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                        }
                    }
                    .background(Color(.systemGroupedBackground))

                    Divider()

                    // Data rows
                    ForEach(rows, id: \.label) { row in
                        HStack(spacing: 0) {
                            Text(row.label)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .frame(width: 130, alignment: .leading)
                                .padding(12)
                            ForEach(colleges) { college in
                                Text(row.value(college))
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                            }
                        }
                        Divider()
                    }
                }
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
