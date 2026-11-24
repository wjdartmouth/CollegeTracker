// CollegeDetailView.swift
import SwiftUI
import SwiftData

enum CollegeSection: Int, Hashable {
    case pathways = 0
    case deadlines = 1
    case documents = 2
    case notes = 3
}

struct CollegeRoute: Hashable {
    var collegeID: UUID
    var section: CollegeSection
    var deadlineID: UUID?
}

struct CollegeDetailView: View {
    @Bindable var college: College
    @Environment(\.modelContext) private var context
    @State private var showAddDeadline = false
    @State private var showAddDocument = false
    @State private var showEditNotes = false
    @State private var selectedTab: Int
    private let highlightedDeadlineID: UUID?

    init(college: College, initialSection: CollegeSection = .pathways, highlightedDeadlineID: UUID? = nil) {
        self.college = college
        _selectedTab = State(initialValue: initialSection.rawValue)
        self.highlightedDeadlineID = highlightedDeadlineID
    }

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                CollegeHeaderCard(college: college)

                // Tabs
                Picker(L10n.tr("Section"), selection: $selectedTab) {
                    Text(L10n.tr("Pathways")).tag(0)
                    Text(L10n.tr("Deadlines")).tag(1)
                    Text(L10n.tr("Documents")).tag(2)
                    Text(L10n.tr("Notes")).tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedTab {
                case CollegeSection.pathways.rawValue: PathwaySection(college: college)
                case CollegeSection.deadlines.rawValue:
                    DeadlinesSection(
                        college: college,
                        showAdd: $showAddDeadline,
                        highlightedDeadlineID: highlightedDeadlineID
                    )
                case CollegeSection.documents.rawValue: DocumentsSection(college: college, showAdd: $showAddDocument)
                case CollegeSection.notes.rawValue: NotesSection(college: college)
                default: EmptyView()
                }
            }
            .padding(.bottom, 32)
        }
        .task(id: highlightedDeadlineID) {
            guard let id = highlightedDeadlineID, selectedTab == CollegeSection.deadlines.rawValue else { return }
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation {
                proxy.scrollTo(id, anchor: .center)
            }
        }
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
                        Label(L10n.tr("Open Portal"), systemImage: "safari")
                    }
                    .disabled(college.portalURL == nil)

                    Picker(L10n.tr("Status"), selection: $college.status) {
                        ForEach(ApplicationStatus.allCases) { s in
                            Label(s.localizedTitle, systemImage: s.icon).tag(s)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel(L10n.tr("More actions"))
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
            if let location = college.localizedLocationLine {
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
                        Label(status.localizedTitle, systemImage: status.icon)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: college.status.icon)
                    Text(college.status.localizedTitle)
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
                            Text(L10n.tr("Accept Rate"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let rank = college.localizedRankDisplay {
                        VStack {
                            Text(rank)
                                .font(.headline.bold())
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                                .multilineTextAlignment(.center)
                            Text(L10n.tr("QS Rank"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    VStack {
                        Text("\(college.documents.count)")
                            .font(.headline.bold())
                        Text(L10n.tr("Docs"))
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
    var highlightedDeadlineID: UUID? = nil
    @Environment(\.modelContext) private var context

    var sortedDeadlines: [Deadline] {
        college.deadlines.sorted { $0.date < $1.date }
    }

    private var emptyDeadlineSubtitle: String {
        switch CatalogRegion.of(college) {
        case .hongKong: return L10n.tr("Tap + to add a JUPAS or Non-JUPAS deadline")
        case .japan: return L10n.tr("Tap + to add an EJU, Common Test, or other deadline")
        case .other: return L10n.tr("Tap + to add a deadline")
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L10n.tr("Deadlines"))
                    .font(.headline)
                Spacer()
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
                .accessibilityLabel(L10n.tr("Add deadline"))
            }
            .padding(.horizontal)

            if sortedDeadlines.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.plus",
                    title: L10n.tr("No deadlines"),
                    subtitle: emptyDeadlineSubtitle
                )
            } else {
                ForEach(sortedDeadlines) { deadline in
                    DeadlineRowView(deadline: deadline, collegeName: college.name, collegeID: college.id)
                        .id(deadline.id)
                        .overlay {
                            if deadline.id == highlightedDeadlineID {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.blue, lineWidth: 2)
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                NotificationService.shared.cancelReminders(for: deadline)
                                context.delete(deadline)
                                try? context.save()
                            } label: {
                                Label(L10n.tr("Delete deadline"), systemImage: "trash")
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
    var collegeID: UUID? = nil

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
                    NotificationService.shared.scheduleReminders(
                        for: deadline,
                        collegeName: collegeName,
                        collegeID: collegeID ?? deadline.college?.id
                    )
                }
            } label: {
                Image(systemName: deadline.isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(deadline.isComplete ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel(deadline.isComplete ? L10n.tr("Mark incomplete") : L10n.tr("Mark complete"))
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
        case .hongKong: return L10n.tr("Tap + to add a JUPAS application, personal statement, or school report")
        case .japan: return L10n.tr("Tap + to add a personal statement, EJU scores, or transcript")
        case .other: return L10n.tr("Tap + to add a document")
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L10n.tr("Documents"))
                    .font(.headline)
                Spacer()
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
                .accessibilityLabel(L10n.tr("Add document"))
            }
            .padding(.horizontal)

            if college.documents.isEmpty {
                EmptyStateView(icon: "doc.badge.plus", title: L10n.tr("No documents"), subtitle: emptyDocumentSubtitle)
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
                Text(document.type.localizedTitle)
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
                    Text(L10n.format("%lldw", document.wordCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            Text(L10n.tr("Notes"))
                .font(.headline)
                .padding(.horizontal)

            TextEditor(text: $college.notes)
                .frame(minHeight: 200)
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .accessibilityLabel(L10n.tr("Notes"))

            Text(L10n.tr("Jot down impressions, visit notes, or research."))
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
                    Picker(L10n.tr("Type"), selection: $type) {
                        ForEach(DeadlineType.suggested(for: college)) { t in
                            Label(t.localizedTitle, systemImage: t.icon).tag(t)
                        }
                    }
                    if type == .custom {
                        TextField(L10n.tr("Label"), text: $customLabel)
                    }
                    DatePicker(L10n.tr("Date"), selection: $date, displayedComponents: .date)
                }

                Section {
                    Toggle(L10n.tr("Notify me"), isOn: $notify)
                    if notify {
                        Text(L10n.tr("Local reminders at 9:00 — 30 days, 1 week, 1 day, and the day of the deadline. These are regular notifications, not Critical Alerts."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(L10n.tr("Add Deadline"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.tr("Cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("Add")) { save() }
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
            NotificationService.shared.scheduleReminders(for: deadline, collegeName: college.name, collegeID: college.id)
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
                Picker(L10n.tr("Type"), selection: $type) {
                    ForEach(DocumentType.suggested(for: college)) { t in
                        Label(t.localizedTitle, systemImage: t.icon).tag(t)
                    }
                }

                TextField(L10n.tr("Title / Prompt snippet"), text: $title)

                HStack {
                    Text(L10n.tr("Word Limit"))
                    Spacer()
                    TextField(L10n.tr("Optional"), text: $wordLimit)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(L10n.tr("Add Document"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.tr("Cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("Add")) { save() }.disabled(title.isEmpty)
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

    private var rows: [(label: String, value: (College) -> String)] {
        [
            (L10n.tr("Status"), { $0.status.localizedTitle }),
            (L10n.tr("Acceptance Rate"), { $0.acceptanceRate.map { String(format: "%.1f%%", $0) } ?? "—" }),
            (L10n.tr("QS Rank"), { $0.localizedRankDisplay ?? "—" }),
            (L10n.tr("Location"), { $0.localizedLocationLine ?? "—" }),
            (L10n.tr("Deadlines"), { "\($0.deadlines.count)" }),
            (L10n.tr("Documents"), { "\($0.documents.count)" }),
            (L10n.tr("Nearest Deadline"), { $0.nearestDeadline.map { $0.date.shortFormatted } ?? L10n.tr("None") }),
        ]
    }

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
            .navigationTitle(L10n.tr("Compare"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("Done")) { dismiss() }
                }
            }
        }
    }
}
