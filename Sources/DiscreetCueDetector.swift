import Foundation

struct DiscreetCueDetector {
    /// Extract a “question to answer” from the transcript.
    /// MVP heuristics:
    /// - If the last sentence ends with '?' -> take it.
    /// - If it contains Spanish/English cue phrases like:
    ///   "quieres saber ..." / "do you know ..." / "you want to know ..."
    static func extractQuestion(from transcript: String) -> String? {
        let t = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 10 else { return nil }

        // Take last ~200 chars to focus on the recent utterance.
        let tail = String(t.suffix(220))

        // 1) If it ends with question mark
        if let lastQ = lastSentenceEndingWithQuestionMark(in: tail) {
            return lastQ
        }

        // 2) Cue phrases
        let lowered = tail.lowercased()
        let cues = [
            "quieres saber",
            "quieres que te diga",
            "me puedes decir",
            "do you know",
            "you want to know",
            "can you tell me",
            "what should i say"
        ]
        guard cues.contains(where: { lowered.contains($0) }) else { return nil }

        // If there's no '?', we attempt to extract the clause after the cue.
        for cue in cues {
            if let range = lowered.range(of: cue) {
                let after = tail[range.upperBound...]
                let cleaned = after
                    .replacingOccurrences(of: ":", with: "")
                    .replacingOccurrences(of: "?", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.count >= 8 {
                    // Rebuild as a question.
                    return cleaned.hasSuffix("?") ? String(cleaned) : String(cleaned) + "?"
                }
            }
        }

        return nil
    }

    private static func lastSentenceEndingWithQuestionMark(in text: String) -> String? {
        // Find last '?'
        guard let idx = text.lastIndex(of: "?") else { return nil }
        let prefix = text[..<text.index(after: idx)]

        // Find sentence start (after last period/newline)
        let separators: [Character] = [".", "\n", "!", "¿"]
        if let start = prefix.lastIndex(where: { separators.contains($0) }) {
            let s = prefix[prefix.index(after: start)...]
            return s.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(prefix).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
