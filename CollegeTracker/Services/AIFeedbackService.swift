// AIFeedbackService.swift
import Foundation

// MARK: - Focus Area

enum FocusArea: String, CaseIterable, Identifiable {
    case overall      = "Overall Review"
    case structure    = "Structure & Flow"
    case voice        = "Authentic Voice"
    case prompt       = "Prompt Alignment"
    case grammar      = "Grammar & Style"
    case conciseness  = "Conciseness"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overall:     return "sparkles"
        case .structure:   return "list.bullet.indent"
        case .voice:       return "waveform"
        case .prompt:      return "target"
        case .grammar:     return "textformat.abc"
        case .conciseness: return "scissors"
        }
    }

    var description: String {
        switch self {
        case .overall:     return "Comprehensive feedback on all aspects"
        case .structure:   return "How well the essay flows and is organized"
        case .voice:       return "Whether your unique personality comes through"
        case .prompt:      return "How well you answered the prompt"
        case .grammar:     return "Grammatical correctness and writing style"
        case .conciseness: return "Trimming unnecessary words and improving impact"
        }
    }
}

// MARK: - Feedback Request

struct FeedbackRequest {
    let essayText: String
    let wordLimit: Int?
    let collegeName: String?
    let promptText: String?
    let focusArea: FocusArea
}

// MARK: - Anthropic API Types

private struct AnthropicRequest: Encodable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [Message]

    struct Message: Encodable {
        let role: String
        let content: String
    }
}

private struct AnthropicResponse: Decodable {
    struct Content: Decodable {
        let type: String
        let text: String?
    }
    let content: [Content]
}

// MARK: - Parsed Feedback

struct ParsedFeedback {
    let score: Int?
    let strengths: [String]
    let improvements: [String]
    let suggestions: [String]
    let encouragement: String
    let rawText: String
}

// MARK: - AI Feedback Service

class AIFeedbackService {
    static let shared = AIFeedbackService()
    private init() {}

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    func getFeedback(for request: FeedbackRequest) async throws -> EssayFeedback {
        let systemPrompt = """
        You are an expert college admissions counselor with 15+ years helping students get into top universities.
        You give specific, actionable, encouraging feedback on college essays.

        Always respond in this EXACT format:
        SCORE: X/10
        STRENGTHS:
        - [strength 1]
        - [strength 2]
        - [strength 3]
        IMPROVEMENTS:
        - [improvement 1]
        - [improvement 2]
        - [improvement 3]
        SUGGESTIONS:
        - [specific line-level suggestion 1]
        - [specific line-level suggestion 2]
        ENCOURAGEMENT: [one warm, specific sentence]
        """

        let userPrompt = buildPrompt(for: request)

        let requestBody = AnthropicRequest(
            model: "claude-sonnet-4-20250514",
            max_tokens: 1000,
            system: systemPrompt,
            messages: [.init(role: "user", content: userPrompt)]
        )

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.apiError("Server returned an error. Check your API key.")
        }

        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        let rawText = decoded.content.compactMap(\.text).joined()
        let parsed = parseFeedback(rawText)

        let feedback = EssayFeedback(
            focusArea: request.focusArea.rawValue,
            feedback: rawText,
            score: parsed.score,
            wordCount: request.essayText.wordCount
        )
        return feedback
    }

    // MARK: - Private helpers

    private func buildPrompt(for request: FeedbackRequest) -> String {
        var parts: [String] = []
        parts.append("Please review this college essay focusing on: **\(request.focusArea.rawValue)**")
        if let college = request.collegeName { parts.append("College: \(college)") }
        if let limit = request.wordLimit { parts.append("Word limit: \(limit) (current: \(request.essayText.wordCount))") }
        if let prompt = request.promptText { parts.append("Essay prompt: \(prompt)") }
        parts.append("\nESSAY:\n\(request.essayText)")
        return parts.joined(separator: "\n")
    }

    func parseFeedback(_ text: String) -> ParsedFeedback {
        func extractScore(_ t: String) -> Int? {
            let pattern = #"SCORE:\s*(\d+)/10"#
            guard let range = t.range(of: pattern, options: .regularExpression) else { return nil }
            let match = String(t[range])
            return match.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }.first
        }

        func extractList(after keyword: String, before nextKeyword: String, in text: String) -> [String] {
            guard let start = text.range(of: keyword + "\n")?.upperBound else { return [] }
            let remaining = String(text[start...])
            let end = remaining.range(of: nextKeyword)?.lowerBound ?? remaining.endIndex
            let block = String(remaining[..<end])
            return block.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "- ", with: "") }
                .filter { !$0.isEmpty }
        }

        func extractLine(after keyword: String, in text: String) -> String {
            guard let range = text.range(of: keyword) else { return "" }
            let rest = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            return rest.components(separatedBy: "\n").first ?? ""
        }

        return ParsedFeedback(
            score: extractScore(text),
            strengths: extractList(after: "STRENGTHS:", before: "IMPROVEMENTS:", in: text),
            improvements: extractList(after: "IMPROVEMENTS:", before: "SUGGESTIONS:", in: text),
            suggestions: extractList(after: "SUGGESTIONS:", before: "ENCOURAGEMENT:", in: text),
            encouragement: extractLine(after: "ENCOURAGEMENT: ", in: text),
            rawText: text
        )
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case apiError(String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .apiError(let msg): return msg
        case .parseError: return "Could not parse AI response."
        }
    }
}
