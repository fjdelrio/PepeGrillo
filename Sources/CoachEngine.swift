import Foundation

protocol LLMClientProtocol {
    func suggestions(prompt: String) async throws -> CoachSuggestion
    func answer(prompt: String) async throws -> CoachSuggestion
    func summary(prompt: String) async throws -> SessionSummary
}

final class CoachEngine {
    private let llm: LLMClientProtocol

    init(llm: LLMClientProtocol) {
        self.llm = llm
    }

    func suggest(objective: String, mode: SessionMode, recentTranscript: String, outputMode: OutputMode, language: DetectedLanguage?) async throws -> CoachSuggestion {
        let lang = language == .es ? "Spanish" : (language == .en ? "English" : "Match the conversation language")

        let prompt = """
You are a real-time conversation companion/mentor.

LANGUAGE (STRICT):
\(lang)
- Write ALL output in that language.
- Do NOT mix languages.
- If unsure, default to Spanish.

MODE:
\(mode.systemHint)

OBJECTIVE:
\(objective)

OUTPUT MODE:
\(outputMode.rawValue)

RECENT TRANSCRIPT (may be incomplete):
\(recentTranscript)

TASK:
Return up to \(outputMode.maxBullets) bullets.
- Must be short.
- Must be immediately usable in the next 20-60 seconds.
- Prefer questions, reframes, and crisp talking points.
- For Social mode: avoid cringe; keep it witty but tasteful.
Output JSON with fields: {"title": string, "bullets": [string]}.
"""
        let s = try await llm.suggestions(prompt: prompt)

        // Prefer UI-selected language when explicitly set; otherwise infer from model output.
        let inferred = LanguageDetector.detect(from: ([s.title] + s.bullets).joined(separator: " "))
        let resolvedLang = language ?? inferred

        return CoachSuggestion(bullets: s.bullets, title: s.title, language: resolvedLang)
    }

    func answer(question: String, objective: String, mode: SessionMode, language: DetectedLanguage?) async throws -> CoachSuggestion {
        let lang = language == .es ? "Spanish" : (language == .en ? "English" : "Match the conversation language")

        let prompt = """
You are a discreet in-ear assistant.

LANGUAGE (STRICT):
\(lang)
- Write ALL output in that language.
- Do NOT mix languages.
- If unsure, default to Spanish.

OBJECTIVE:
\(objective)

USER QUESTION TO ANSWER:
\(question)

RULES:
- Give the direct answer first.
- Keep it short.
- If helpful, add 1 follow-up line the user can say next.
Output JSON with fields: {"title": string, "bullets": [string]}.
"""
        let s = try await llm.answer(prompt: prompt)

        let inferred = LanguageDetector.detect(from: ([s.title] + s.bullets).joined(separator: " "))
        let resolvedLang = language ?? inferred

        return CoachSuggestion(bullets: s.bullets, title: s.title, language: resolvedLang)
    }

    func summarize(objective: String, mode: SessionMode, fullTranscript: String) async throws -> SessionSummary {
        let prompt = """
You are a meeting notes assistant (Granola-style).

MODE: \(mode.rawValue)
OBJECTIVE: \(objective)

FULL TRANSCRIPT:
\(fullTranscript)

Return:
- Notes paragraph (compact)
- 3-7 action items
- 2-5 follow-ups
Output JSON with fields: {"notes": string, "actionItems": [string], "followUps": [string]}.
"""
        return try await llm.summary(prompt: prompt)
    }
}

// MARK: - Mock LLM (MVP)

enum LLMClient {
    static let mock: LLMClientProtocol = MockLLMClient()

    struct Resolved {
        let client: LLMClientProtocol
        let label: String
    }

    /// Use OpenAI if OPENAI_API_KEY is present; otherwise fall back to mock.
    static func resolve() -> Resolved {
        if let openAI = try? OpenAIClient.fromEnvironment() {
            return Resolved(client: openAI, label: "OpenAI")
        }
        return Resolved(client: MockLLMClient(), label: "Mock")
    }
}

final class MockLLMClient: LLMClientProtocol {
    func suggestions(prompt: String) async throws -> CoachSuggestion {
        // Simple social-oriented mock.
        let bullets = [
            "Ask: 'What got you into that?'",
            "Mirror + add: 'That’s interesting — is it more about X or Y?'",
            "Offer a fun bridge: 'That reminds me of…' (keep it short)"
        ]
        return CoachSuggestion(bullets: bullets, title: "Nudge", language: nil)
    }

    func answer(prompt: String) async throws -> CoachSuggestion {
        // Mock answer. (Example: America discovery)
        let bullets = [
            "Commonly cited: 1492 (Columbus).",
            "Follow-up: 'But there were Norse voyages earlier (~1000 CE).'"
        ]
        return CoachSuggestion(bullets: bullets, title: "Answer", language: nil)
    }

    func summary(prompt: String) async throws -> SessionSummary {
        return SessionSummary(
            notes: "Summary (mock): key topics + vibe; suggested follow-ups captured.",
            actionItems: ["Send a quick follow-up text", "Share one link/resource"],
            followUps: ["Ask about their current project", "Invite to next meetup"]
        )
    }
}
