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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Type filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: L10n.tr("All"), color: .blue, selected: selectedType == nil) {
                            selectedType = nil
                        }
                        ForEach(DocumentType.allCases) { type in
                            FilterChip(label: type.localizedTitle, color: .blue,
                                        selected: selectedType == type) {
                                selectedType = selectedType == type ? nil : type
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
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
                .searchable(text: $searchText, prompt: L10n.tr("Search documents"))
                .overlay {
                    if filteredDocuments.isEmpty {
                        EmptyStateView(
                            icon: "folder",
                            title: allDocuments.isEmpty ? L10n.tr("No documents") : L10n.tr("No matching documents"),
                            subtitle: allDocuments.isEmpty
                                ? L10n.tr("Add essays from a college's page")
                                : L10n.tr("Try another name or document type")
                        )
                    }
                }
            }
            .navigationTitle(L10n.tr("Document Vault"))
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
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: document.type.icon)
                    .foregroundStyle(.blue)
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
                    Text(document.type.localizedTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let limit = document.wordLimit {
                    Text(L10n.format("%lld/%lldw", document.wordCount, limit))
                        .font(.caption.bold())
                        .foregroundStyle(document.wordCountStatus.color)
                } else {
                    Text(L10n.format("%lldw", document.wordCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
