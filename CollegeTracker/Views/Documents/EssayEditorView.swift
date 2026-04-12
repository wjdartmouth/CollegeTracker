// EssayEditorView.swift
import SwiftUI
import SwiftData

struct EssayEditorView: View {
    @Bindable var document: Document
    @Environment(\.modelContext) private var context
    @State private var showFeedback = false
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 0) {
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if document.type.supportsAIFeedback {
                    Button {
                        showFeedback = true
                    } label: {
                        Label("AI Feedback", systemImage: "sparkles")
                    }
                    .disabled(document.content.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showFeedback) {
            EssayFeedbackView(document: document)
        }
    }

    private func scheduleSave() {
        // Debounced save via Task
        Task {
            try? await Task.sleep(for: .seconds(1))
            try? context.save()
        }
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
                Label(document.type.rawValue, systemImage: document.type.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Group {
                    if let limit = document.wordLimit {
                        Text("\(document.wordCount)")
                            .foregroundStyle(document.wordCountStatus.color) +
                        Text(" / \(limit) words")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(document.wordCount) words")
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
