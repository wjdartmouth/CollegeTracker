// EssayEditorView.swift
import SwiftUI
import SwiftData

struct EssayEditorView: View {
    @Bindable var document: Document
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(spacing: 0) {
            if document.type.supportsAIFeedback {
                EssayAIComingSoonBanner()
            }

            // Word count bar
            WordCountBar(document: document)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

            Divider()

            // Editor
            TextEditor(text: $document.content)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .onChange(of: document.content) { _, _ in
                    document.lastEdited = .now
                    scheduleSave()
                }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func scheduleSave() {
        // Debounced save via Task
        Task {
            try? await Task.sleep(for: .seconds(1))
            try? context.save()
        }
    }
}

// MARK: - Essay AI gate

/// Visible, non-interactive stand-in for essay AI. Does not present `EssayFeedbackView`.
struct EssayAIComingSoonBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
            Text(L10n.tr("AI Feedback"))
            Text(L10n.tr("Coming soon"))
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.2))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
            Spacer(minLength: 0)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.tr("AI Feedback, coming soon"))
        .accessibilityHint(L10n.tr("Essay feedback is coming soon. This version does not send essay text off this iPhone."))
    }
}

// MARK: - Word Count Bar

struct WordCountBar: View {
    let document: Document

    var progress: Double {
        guard let limit = document.wordLimit, limit > 0 else { return 0 }
        return min(Double(document.wordCount) / Double(limit), 1.0)
    }

    var barColor: Color {
        document.wordCountStatus.color == .secondary ? .blue : document.wordCountStatus.color
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Label(document.type.localizedTitle, systemImage: document.type.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Group {
                    if let limit = document.wordLimit {
                        Text("\(document.wordCount)")
                            .foregroundStyle(document.wordCountStatus.color) +
                        Text(L10n.format(" / %lld words", limit))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(L10n.format("%lld words", document.wordCount))
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption.bold())
            }

            if document.wordLimit != nil {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(barColor)
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(.easeInOut(duration: 0.2), value: progress)
                    }
                }
                .frame(height: 4)
            }
        }
    }
}
