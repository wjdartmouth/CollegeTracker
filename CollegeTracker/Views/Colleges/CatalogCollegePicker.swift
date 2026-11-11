// CatalogCollegePicker.swift
import SwiftUI

/// Searchable HK + Japan catalog picker used by the add-college flow.
struct CatalogCollegePicker: View {
    let alreadyAddedCatalogIDs: Set<String>
    let onSelect: (CatalogCollege) -> Void
    let onCustom: () -> Void

    @State private var query = ""
    @State private var region: String? = nil

    private var store: CollegeCatalogStore { .shared }

    private var results: [CatalogCollege] {
        store.search(query, region: region)
    }

    var body: some View {
        VStack(spacing: 0) {
            regionBar

            if let error = store.loadError {
                ContentUnavailableView(
                    "Catalog unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                List(results) { college in
                    let added = alreadyAddedCatalogIDs.contains(college.id)
                    Button {
                        guard !added else { return }
                        onSelect(college)
                    } label: {
                        CatalogCollegeRow(college: college, alreadyAdded: added)
                    }
                    .disabled(added)
                }
                .listStyle(.plain)
            }
        }
        .searchable(text: $query, prompt: "Search name, city, region, or id")
        .navigationTitle("Choose a college")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("School not listed? Add custom") {
                    onCustom()
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Text("\(results.count) of \(store.colleges.count)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(10)
        }
    }

    private var regionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", color: .blue, selected: region == nil) {
                    region = nil
                }
                ForEach(store.regions, id: \.self) { item in
                    FilterChip(label: item, color: .blue, selected: region == item) {
                        region = region == item ? nil : item
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}

struct CatalogCollegeRow: View {
    let college: CatalogCollege
    var alreadyAdded: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(college.officialEnglishName)
                    .font(.subheadline.bold())
                    .foregroundStyle(alreadyAdded ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                if !college.localNativeName.isEmpty {
                    Text(college.localNativeName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text([college.locationLine, college.id].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                if let rank = college.qsRankDisplay {
                    Text(rank.hasPrefix("Not") || rank.hasPrefix("Unlisted") ? rank : "QS \(rank)")
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
                if alreadyAdded {
                    Text("Added")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
