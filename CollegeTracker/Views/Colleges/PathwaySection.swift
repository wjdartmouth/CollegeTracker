// PathwaySection.swift
import SwiftUI

/// Catalog facts + admissions pathways for a school added from the HK + Japan catalog.
struct PathwaySection: View {
    let college: College

    private var catalog: CatalogCollege? {
        guard let id = college.catalogId else { return nil }
        return CollegeCatalogStore.shared.college(id: id)
    }

    private var pathways: [AdmissionPathway] {
        AdmissionsStore.shared.pathways(forCatalogId: college.catalogId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let catalog {
                CatalogFactsCard(college: catalog)
            }

            HStack {
                Text("Admissions pathways")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            if pathways.isEmpty {
                EmptyStateView(
                    icon: "map",
                    title: "No pathway data",
                    subtitle: college.catalogId == nil
                        ? "Pathways are available for schools added from the HK + Japan catalog."
                        : "No bundled JUPAS / EJU pathway is on file for this school."
                )
            } else {
                Text("Typical routes from the college-data catalog. Always verify the current JUPAS / university guide or 募集要項 — these are not official deadlines.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                ForEach(pathways) { pathway in
                    PathwayCard(pathway: pathway)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CatalogFactsCard: View {
    let college: CatalogCollege

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !college.type.isEmpty || !college.foundedYear.isEmpty {
                HStack(spacing: 16) {
                    if !college.type.isEmpty {
                        fact("Type", college.type)
                    }
                    if !college.foundedYear.isEmpty {
                        fact("Founded", college.foundedYear)
                    }
                }
            }
            if let tuition = college.tuitionDisplay {
                let currency = college.tuitionCurrency.trimmingCharacters(in: .whitespaces)
                fact("Tuition (approx.)", currency.isEmpty ? tuition : "\(tuition) · listed in \(currency)")
            }
            if !college.website.isEmpty {
                if let url = URL(string: college.website) {
                    Link(destination: url) {
                        Label(college.website, systemImage: "safari")
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }
            }
            if !college.majorList.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Faculties / majors")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(college.majorList.joined(separator: " · "))
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle()
        .padding(.horizontal)
    }

    private func fact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PathwayCard: View {
    let pathway: AdmissionPathway
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pathway.categoryTitle)
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                    Text(pathway.pathwayName)
                        .font(.subheadline.bold())
                }
                Spacer()
                if !pathway.confidence.isEmpty {
                    Text(pathway.confidence.capitalized)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(confidenceColor.opacity(0.15))
                        .foregroundStyle(confidenceColor)
                        .clipShape(Capsule())
                }
            }

            if !pathway.examsRequired.isEmpty {
                labeled("Exams / requirements", pathway.examsRequired)
            }
            if !pathway.typicalTimeline.isEmpty {
                labeled("Typical timeline", pathway.typicalTimeline)
            }
            if !pathway.languageRequirements.isEmpty {
                labeled("Language", pathway.languageRequirements)
            }

            if !pathway.notes.isEmpty {
                if expanded || pathway.notes.count <= 220 {
                    labeled("Notes", pathway.notes)
                } else {
                    labeled("Notes", String(pathway.notes.prefix(220)).trimmingCharacters(in: .whitespaces) + "…")
                }
                if pathway.notes.count > 220 {
                    Button(expanded ? "Show less" : "Show more") {
                        expanded.toggle()
                    }
                    .font(.caption.bold())
                }
            }
        }
        .padding(14)
        .cardStyle()
    }

    private var confidenceColor: Color {
        switch pathway.confidence.lowercased() {
        case "high": return Color(hex: "#34C759")
        case "medium": return Color(hex: "#FF9F0A")
        case "low": return Color(hex: "#FF3B30")
        default: return .secondary
        }
    }

    private func labeled(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(body)
                .font(.subheadline)
        }
    }
}
