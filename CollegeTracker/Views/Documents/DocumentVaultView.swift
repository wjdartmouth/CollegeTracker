// DocumentVaultView.swift
import SwiftUI

struct DocumentVaultView: View {
    let profile: UserProfile
    @State private var selectedType: DocumentType? = nil
    @State private var searchText = ""

    var allDocuments: [Document] {
        profile.colleges.flatMap(\.documents)
    }

    var filteredDocuments: [Document] {
        var result = allDocuments
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.college?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        return result.sorted { $0.lastEdited > $1.lastEdited }
    }

    var essaysNeedingFeedback: [Document] {
        allDocuments.filter { $0.type.supportsAIFeedback && $0.feedbackHistory.isEmpty && !$0.content.isEmpty }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Type filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", color: .blue, selected: selectedType == nil) {
                            selectedType = nil
                        }
                        ForEach(DocumentType.allCases) { type in
                            FilterChip(label: type.rawValue, color: .blue,
                                        selected: selectedType == type) {
                                selectedType = selectedType == type ? nil : type
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                if !essaysNeedingFeedback.isEmpty && selectedType == nil && searchText.isEmpty {
                    // Nudge banner
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                        Text("\(essaysNeedingFeedback.count) essay\(essaysNeedingFeedback.count == 1 ? "" : "s") ready for AI feedback")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.purple.opacity(0.08))
                }

                List {
                    ForEach(filteredDocuments) { doc in
                        NavigationLink(destination: EssayEditorView(document: doc)) {
                            VaultDocumentRow(document: doc)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search documents")
                .overlay {
                    if filteredDocuments.isEmpty {
                        EmptyStateView(
                            icon: "folder",
                            title: "No documents",
                            subtitle: "Add essays from a college's page"
                        )
                    }
                }
            }
            .navigationTitle("Document Vault")
        }
    }
}

struct VaultDocumentRow: View {
    let document: Document

    var body: some View {
        HStack(spacing: 14) {
            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(document.type.supportsAIFeedback ? Color.purple.opacity(0.1) : Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: document.type.icon)
                    .foregroundStyle(document.type.supportsAIFeedback ? .purple : .blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let college = document.college {
                        Text(college.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                    }
                    Text(document.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let limit = document.wordLimit {
                    Text("\(document.wordCount)/\(limit)w")
                        .font(.caption.bold())
                        .foregroundStyle(document.wordCountStatus.color)
                } else {
                    Text("\(document.wordCount)w")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if document.type.supportsAIFeedback {
                    if document.feedbackHistory.isEmpty {
                        if !document.content.isEmpty {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(.purple.opacity(0.6))
                        }
                    } else {
                        HStack(spacing: 2) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text("\(document.feedbackHistory.count)")
                                .font(.caption2)
                        }
                        .foregroundStyle(.purple)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
