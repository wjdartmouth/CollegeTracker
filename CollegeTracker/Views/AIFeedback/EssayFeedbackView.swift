// EssayFeedbackView.swift
import SwiftUI
import SwiftData

struct EssayFeedbackView: View {
    let document: Document
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var focusArea: FocusArea = .overall
    @State private var promptText = ""
    @State private var isLoading = false
    @State private var currentFeedback: EssayFeedback?
    @State private var errorMessage: String?
    @State private var showHistory = false

    var latestFeedback: EssayFeedback? {
        document.feedbackHistory.sorted { $0.createdAt > $1.createdAt }.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Essay summary
                    EssaySummaryCard(document: document)
                        .padding(.horizontal)

                    // Focus area picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What should Claude focus on?")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(FocusArea.allCases) { area in
                                    FocusAreaChip(area: area, selected: focusArea == area) {
                                        focusArea = area
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Text(focusArea.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }

                    // Optional prompt
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Essay prompt (optional)")
                            .font(.subheadline.bold())
                        TextField("Paste the prompt here for better feedback...", text: $promptText, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // Get feedback button
                    Button {
                        Task { await requestFeedback() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.85)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isLoading ? "Analyzing..." : "Get AI Feedback")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.purple.opacity(0.7) : Color.purple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isLoading || document.content.isEmpty)
                    .padding(.horizontal)

                    // Error
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                    }

                    // Current feedback result
                    if let feedback = currentFeedback {
                        FeedbackResultView(feedback: feedback)
                            .padding(.horizontal)
                    }

                    // History
                    if !document.feedbackHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Button {
                                showHistory.toggle()
                            } label: {
                                HStack {
                                    Text("Feedback History (\(document.feedbackHistory.count))")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: showHistory ? "chevron.up" : "chevron.down")
                                }
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal)

                            if showHistory {
                                ForEach(document.feedbackHistory.sorted { $0.createdAt > $1.createdAt }) { item in
                                    FeedbackHistoryCard(feedback: item)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("AI Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @MainActor
    private func requestFeedback() async {
        isLoading = true
        errorMessage = nil
        currentFeedback = nil

        let request = FeedbackRequest(
            essayText: document.content,
            wordLimit: document.wordLimit,
            collegeName: document.college?.name,
            promptText: promptText.isEmpty ? nil : promptText,
            focusArea: focusArea
        )

        do {
            let feedback = try await AIFeedbackService.shared.getFeedback(for: request)
            feedback.document = document
            document.feedbackHistory.append(feedback)
            context.insert(feedback)
            try? context.save()
            currentFeedback = feedback
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Essay Summary Card

struct EssaySummaryCard: View {
    let document: Document

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: document.type.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack {
                    if let limit = document.wordLimit {
                        Text("\(document.wordCount) / \(limit) words")
                            .foregroundStyle(document.wordCountStatus.color)
                    } else {
                        Text("\(document.wordCount) words")
                            .foregroundStyle(.secondary)
                    }
                    if let college = document.college {
                        Text("·")
                        Text(college.name)
                    }
                }
                .font(.caption)
            }
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Focus Area Chip

struct FocusAreaChip: View {
    let area: FocusArea
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: area.icon)
                    .font(.caption)
                Text(area.rawValue)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? Color.purple : Color.purple.opacity(0.1))
            .foregroundStyle(selected ? .white : .purple)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Feedback Result View

struct FeedbackResultView: View {
    let feedback: EssayFeedback
    @State private var expanded = true

    var parsed: ParsedFeedback {
        AIFeedbackService.shared.parseFeedback(feedback.feedback)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Score header
            HStack {
                VStack(alignment: .leading) {
                    Text("AI Feedback")
                        .font(.headline)
                    Text(feedback.focusArea + " · " + feedback.createdAt.shortFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let score = feedback.score {
                    ScoreBadge(score: score)
                }
            }

            if expanded {
                // Strengths
                if !parsed.strengths.isEmpty {
                    FeedbackSection(title: "Strengths", icon: "hand.thumbsup.fill",
                                    color: .green, items: parsed.strengths)
                }

                // Improvements
                if !parsed.improvements.isEmpty {
                    FeedbackSection(title: "Areas to Improve", icon: "arrow.up.circle.fill",
                                    color: .orange, items: parsed.improvements)
                }

                // Suggestions
                if !parsed.suggestions.isEmpty {
                    FeedbackSection(title: "Specific Suggestions", icon: "pencil.circle.fill",
                                    color: .blue, items: parsed.suggestions)
                }

                // Encouragement
                if !parsed.encouragement.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "quote.opening")
                            .font(.title3)
                            .foregroundStyle(.purple)
                        Text(parsed.encouragement)
                            .font(.subheadline)
                            .italic()
                    }
                    .padding(14)
                    .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
            }

            Button {
                withAnimation(.spring(duration: 0.3)) { expanded.toggle() }
            } label: {
                Text(expanded ? "Collapse" : "Expand")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .cardStyle()
    }
}

struct FeedbackSection: View {
    let title: String
    let icon: String
    let color: Color
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(.subheadline)
                }
            }
        }
    }
}

struct ScoreBadge: View {
    let score: Int

    var color: Color {
        switch score {
        case 8...10: return .green
        case 6..<8:  return .orange
        default:     return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: 52, height: 52)
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.title3.bold())
                    .foregroundStyle(color)
                Text("/10")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Feedback History Card

struct FeedbackHistoryCard: View {
    let feedback: EssayFeedback

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(feedback.focusArea)
                    .font(.subheadline.bold())
                Text(feedback.createdAt.mediumFormatted + " · \(feedback.wordCountAtTime) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let score = feedback.score {
                Text("\(score)/10")
                    .font(.subheadline.bold())
                    .foregroundStyle(score >= 8 ? .green : score >= 6 ? .orange : .red)
            }
        }
        .padding(14)
        .cardStyle()
    }
}
