import Foundation

/// Minimal OpenAI client for the Responses API.
/// Notes:
/// - Do NOT hardcode keys in source.
/// - For MVP: read from env var OPENAI_API_KEY (set in Xcode scheme) or inject later via Keychain.
final class OpenAIClient: LLMClientProtocol {
    enum OpenAIError: Error {
        case missingAPIKey
        case badResponse
        case decodingFailed
        case modelRefused
    }

    private let apiKey: String
    private let model: String

    init(apiKey: String, model: String = "gpt-4.1-mini") {
        // MVP choice confirmed: gpt-4.1-mini
        self.apiKey = apiKey
        self.model = model
    }

    static func fromEnvironment(model: String = "gpt-4.1-mini") throws -> OpenAIClient {
        let env = ProcessInfo.processInfo.environment
        guard let key = env["OPENAI_API_KEY"], !key.isEmpty else {
            throw OpenAIError.missingAPIKey
        }
        return OpenAIClient(apiKey: key, model: model)
    }

    // MARK: - LLMClientProtocol

    func suggestions(prompt: String) async throws -> CoachSuggestion {
        let json = try await callResponsesJSON(prompt: prompt)
        return try parseSuggestion(json: json)
    }

    func answer(prompt: String) async throws -> CoachSuggestion {
        let json = try await callResponsesJSON(prompt: prompt)
        return try parseSuggestion(json: json)
    }

    func summary(prompt: String) async throws -> SessionSummary {
        let json = try await callResponsesJSON(prompt: prompt)
        return try parseSummary(json: json)
    }

    // MARK: - Core

    private func callResponsesJSON(prompt: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Force the model to output JSON (as text) so we can decode it.
        let body: [String: Any] = [
            "model": model,
            "input": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "input_text",
                            "text": prompt
                        ]
                    ]
                ]
            ],
            "text": [
                "format": ["type": "json_object"]
            ]
        ]

        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OpenAIError.badResponse
        }

        // Decode just enough to get output text.
        // Responses API can return output as an array of items; we try best-effort extraction.
        let top = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let output = top?["output"] as? [[String: Any]] {
            // Find first output_text.
            for item in output {
                if let content = item["content"] as? [[String: Any]] {
                    for c in content {
                        if (c["type"] as? String) == "output_text", let text = c["text"] as? String {
                            return text
                        }
                    }
                }
            }
        }

        // Fallback: some SDK shapes use output_text at top-level.
        if let text = top?["output_text"] as? String {
            return text
        }

        throw OpenAIError.decodingFailed
    }

    private func parseSuggestion(json: String) throws -> CoachSuggestion {
        struct Payload: Codable {
            let title: String
            let bullets: [String]
        }
        guard let data = json.data(using: .utf8) else { throw OpenAIError.decodingFailed }
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        return CoachSuggestion(bullets: payload.bullets, title: payload.title, language: nil)
    }

    private func parseSummary(json: String) throws -> SessionSummary {
        struct Payload: Codable {
            let notes: String
            let actionItems: [String]
            let followUps: [String]
        }
        guard let data = json.data(using: .utf8) else { throw OpenAIError.decodingFailed }
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        return SessionSummary(notes: payload.notes, actionItems: payload.actionItems, followUps: payload.followUps)
    }
}
