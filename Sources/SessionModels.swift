import Foundation

enum SessionMode: String, CaseIterable, Identifiable {
    case interview = "Interview"
    case meeting = "Meeting"
    case social = "Social"

    var id: String { rawValue }

    var systemHint: String {
        switch self {
        case .interview:
            return "You are a real-time interview coach. Provide concise, high-impact talking points and suggested answers."
        case .meeting:
            return "You are a real-time meeting assistant. Provide concise points, clarifying questions, and next steps."
        case .social:
            return "You are a real-time social coach. Provide fun, tasteful facts and questions to keep the conversation interesting (not cringey)."
        }
    }
}

struct CoachSuggestion: Identifiable, Equatable {
    let id = UUID()
    let createdAt = Date()
    let bullets: [String]
    let title: String
    let language: DetectedLanguage?
}

struct SessionSummary {
    let notes: String
    let actionItems: [String]
    let followUps: [String]
}
