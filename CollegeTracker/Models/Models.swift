// Models.swift
import SwiftUI
import SwiftData

// MARK: - UserProfile

enum UserRole: String, Codable {
    case student, counselor
}

@Model
class UserProfile {
    var id: UUID
    var name: String
    var role: UserRole
    var createdAt: Date
    var managedStudentIDs: [String]  // Counselor only
    @Relationship(deleteRule: .cascade) var colleges: [College]

    init(name: String, role: UserRole) {
        self.id = UUID()
        self.name = name
        self.role = role
        self.createdAt = .now
        self.managedStudentIDs = []
        self.colleges = []
    }
}

// MARK: - ApplicationStatus

enum ApplicationStatus: String, Codable, CaseIterable, Identifiable {
    case researching   = "Researching"
    case inProgress    = "In Progress"
    case submitted     = "Submitted"
    case interviewing  = "Interviewing"
    case accepted      = "Accepted"
    case waitlisted    = "Waitlisted"
    case deferred      = "Deferred"
    case rejected      = "Rejected"
    case enrolled      = "Enrolled"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .researching:  return Color(hex: "#8E8E93")
        case .inProgress:   return Color(hex: "#007AFF")
        case .submitted:    return Color(hex: "#5856D6")
        case .interviewing: return Color(hex: "#FF9F0A")
        case .accepted:     return Color(hex: "#34C759")
        case .waitlisted:   return Color(hex: "#FF9F0A")
        case .deferred:     return Color(hex: "#FF6B6B")
        case .rejected:     return Color(hex: "#FF3B30")
        case .enrolled:     return Color(hex: "#30D158")
        }
    }

    var icon: String {
        switch self {
        case .researching:  return "magnifyingglass"
        case .inProgress:   return "pencil.circle"
        case .submitted:    return "paperplane.fill"
        case .interviewing: return "person.2.fill"
        case .accepted:     return "checkmark.seal.fill"
        case .waitlisted:   return "clock.fill"
        case .deferred:     return "arrow.clockwise"
        case .rejected:     return "xmark.circle.fill"
        case .enrolled:     return "graduationcap.fill"
        }
    }
}

// MARK: - College

@Model
class College {
    var id: UUID
    var name: String
    var status: ApplicationStatus
    var notes: String
    var acceptanceRate: Double?
    var ranking: Int?
    var portalURL: String?
    var logoColorHex: String       // Used for placeholder avatar color
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var deadlines: [Deadline]
    @Relationship(deleteRule: .cascade) var documents: [Document]
    var profile: UserProfile?

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.status = .researching
        self.notes = ""
        self.logoColorHex = College.randomColor()
        self.createdAt = .now
        self.deadlines = []
        self.documents = []
    }

    var abbreviation: String {
        name.components(separatedBy: " ")
            .filter { $0.count > 2 }
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()
    }

    var nearestDeadline: Deadline? {
        deadlines.filter { $0.date > .now && !$0.isComplete }
            .sorted { $0.date < $1.date }
            .first
    }

    static func randomColor() -> String {
        let colors = ["#4A90D9", "#7B68EE", "#20B2AA", "#FF7F50", "#9370DB",
                      "#3CB371", "#DC143C", "#DAA520", "#4682B4", "#D2691E"]
        return colors.randomElement()!
    }
}

// MARK: - DeadlineType

enum DeadlineType: String, Codable, CaseIterable, Identifiable {
    case earlyDecision   = "Early Decision"
    case earlyAction     = "Early Action"
    case regularDecision = "Regular Decision"
    case scholarship     = "Scholarship"
    case financialAid    = "Financial Aid"
    case interview       = "Interview"
    case custom          = "Custom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .earlyDecision:   return "star.fill"
        case .earlyAction:     return "bolt.fill"
        case .regularDecision: return "calendar"
        case .scholarship:     return "dollarsign.circle.fill"
        case .financialAid:    return "banknote.fill"
        case .interview:       return "person.fill.viewfinder"
        case .custom:          return "flag.fill"
        }
    }
}

// MARK: - Deadline

@Model
class Deadline {
    var id: UUID
    var type: DeadlineType
    var label: String       // Custom label for "Custom" type
    var date: Date
    var isComplete: Bool
    var college: College?

    init(type: DeadlineType, date: Date, label: String = "") {
        self.id = UUID()
        self.type = type
        self.date = date
        self.label = label
        self.isComplete = false
    }

    var displayTitle: String {
        type == .custom ? label : type.rawValue
    }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now),
                                                to: Calendar.current.startOfDay(for: date)).day ?? 0)
    }

    var urgencyColor: Color {
        if isComplete { return .green }
        switch daysRemaining {
        case 0:    return Color(hex: "#FF3B30")
        case 1..<7:  return Color(hex: "#FF3B30")
        case 7..<30: return Color(hex: "#FF9F0A")
        default:     return Color(hex: "#34C759")
        }
    }

    var urgencyLabel: String {
        if isComplete { return "Done" }
        switch daysRemaining {
        case 0: return "Today!"
        case 1: return "Tomorrow"
        default: return "\(daysRemaining)d left"
        }
    }
}

// MARK: - DocumentType

enum DocumentType: String, Codable, CaseIterable, Identifiable {
    case commonAppEssay     = "Common App Essay"
    case supplementalEssay  = "Supplemental Essay"
    case transcript         = "Transcript"
    case recommendation     = "Recommendation Letter"
    case testScores         = "Test Scores"
    case activitiesResume   = "Activities Resume"
    case other              = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .commonAppEssay:    return "doc.text.fill"
        case .supplementalEssay: return "doc.fill"
        case .transcript:        return "list.bullet.rectangle.fill"
        case .recommendation:    return "envelope.fill"
        case .testScores:        return "checkmark.square.fill"
        case .activitiesResume:  return "person.text.rectangle.fill"
        case .other:             return "paperclip"
        }
    }

    var supportsAIFeedback: Bool {
        self == .commonAppEssay || self == .supplementalEssay
    }
}

// MARK: - Document

@Model
class Document {
    var id: UUID
    var type: DocumentType
    var title: String
    var content: String
    var wordLimit: Int?
    var lastEdited: Date
    var college: College?
    @Relationship(deleteRule: .cascade) var feedbackHistory: [EssayFeedback]

    init(type: DocumentType, title: String) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.content = ""
        self.lastEdited = .now
        self.feedbackHistory = []
    }

    var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }

    var wordCountStatus: WordCountStatus {
        guard let limit = wordLimit else { return .noLimit }
        let ratio = Double(wordCount) / Double(limit)
        if ratio > 1.0 { return .over }
        if ratio > 0.9 { return .nearLimit }
        return .ok
    }

    enum WordCountStatus {
        case noLimit, ok, nearLimit, over
        var color: Color {
            switch self {
            case .noLimit, .ok: return .secondary
            case .nearLimit:    return Color(hex: "#FF9F0A")
            case .over:         return Color(hex: "#FF3B30")
            }
        }
    }
}

// MARK: - EssayFeedback

@Model
class EssayFeedback {
    var id: UUID
    var focusArea: String
    var feedback: String
    var score: Int?
    var wordCountAtTime: Int
    var createdAt: Date
    var document: Document?

    init(focusArea: String, feedback: String, score: Int? = nil, wordCount: Int = 0) {
        self.id = UUID()
        self.focusArea = focusArea
        self.feedback = feedback
        self.score = score
        self.wordCountAtTime = wordCount
        self.createdAt = .now
    }
}
