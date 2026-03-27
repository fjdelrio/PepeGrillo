import Foundation
import Combine

@MainActor
final class SessionViewModel: ObservableObject {
    // Setup
    @Published var mode: SessionMode = .social
    @Published var objective: String = ""

    // Person memory (local)
    @Published var selectedPersonId: UUID? = nil
    @Published var personName: String = ""
    @Published var personNotes: String = ""
    let peopleStore = PeopleStore()

    // Options
    @Published var outputMode: OutputMode = .nudges
    @Published var languageMode: LanguageMode = .auto
    @Published var speakSuggestions: Bool = true
    @Published var generateSummaryAtEnd: Bool = true

    // Live
    @Published var isListening: Bool = false
    @Published private(set) var transcript: String = ""
    @Published private(set) var suggestions: [CoachSuggestion] = [] // newest first
    @Published private(set) var summary: SessionSummary? = nil

    private let speech = SpeechRecognizer()
    private let coach = CoachEngine(llm: LLMClient.auto)
    private let tts = TTSManager()

    private var lastSuggestionAt: Date = .distantPast
    private var lastAnswerAt: Date = .distantPast
    private var lastAnsweredQuestionFingerprint: String = ""

    private var cancellables: Set<AnyCancellable> = []
    private var isSessionActive = false

    init() {
        // Live transcript stream
        speech.$partialTranscript
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.transcript = text
            }
            .store(in: &cancellables)

        // React to selected person
        $selectedPersonId
            .sink { [weak self] id in
                guard let self else { return }
                if let id, let p = self.peopleStore.people.first(where: { $0.id == id }) {
                    self.personName = p.name
                    self.personNotes = p.notes
                }
            }
            .store(in: &cancellables)

        // Generate suggestions/answers (policy-driven)
        $transcript
            .removeDuplicates()
            .debounce(for: .seconds(0.8), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.maybeAnswerDiscreetCue()
                    await self?.maybeGenerateSuggestion()
                }
            }
            .store(in: &cancellables)
    }

    func startSession() {
        guard !isSessionActive else {
            configureSpeechLocale()
            speech.start()
            return
        }

        // upsert person profile on start (so we always have an id)
        let person = PersonProfile(
            id: selectedPersonId ?? UUID(),
            name: personName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "(Unknown)" : personName,
            notes: personNotes,
            lastUpdated: Date()
        )
        peopleStore.upsert(person)
        selectedPersonId = person.id

        isSessionActive = true
        summary = nil
        suggestions = []
        transcript = ""
        lastSuggestionAt = .distantPast
        lastAnswerAt = .distantPast
        lastAnsweredQuestionFingerprint = ""

        speech.requestPermissions { [weak self] ok in
            Task { @MainActor in
                guard let self else { return }
                if ok {
                    self.configureSpeechLocale()
                    self.speech.start()
                } else {
                    self.isListening = false
                }
            }
        }
    }

    func pauseListening() {
        speech.stop()
    }

    func stopSession() {
        isListening = false
        speech.stop()

        // Persist notes back into the person profile (MVP: append a tiny marker)
        if let id = selectedPersonId, var p = peopleStore.people.first(where: { $0.id == id }) {
            p.lastUpdated = Date()
            peopleStore.upsert(p)
        }

        if generateSummaryAtEnd {
            Task { await generateSummary() }
        }
    }

    func speak(latest: CoachSuggestion) {
        let text = ([latest.title] + latest.bullets.map { "- \($0)" }).joined(separator: "\n")
        tts.speak(text, language: latest.language)
    }

    func forceFullAdviceNow() async {
        let prev = outputMode
        outputMode = .full
        defer { outputMode = prev }
        await maybeGenerateSuggestion()
    }

    func generateSummary() {
        Task {
            let s = try await coach.summarize(objective: objective, mode: mode, fullTranscript: transcript)
            self.summary = s

            // Append summary to person notes (very simple MVP)
            if let id = selectedPersonId, var p = peopleStore.people.first(where: { $0.id == id }) {
                let stamp = Self.localTimestamp()
                let addition = "\n\n[Session \(stamp)]\nObjective: \(objective)\nNotes: \(s.notes)\nActionItems: \(s.actionItems.joined(separator: "; "))"
                p.notes = (p.notes + addition).trimmingCharacters(in: .whitespacesAndNewlines)
                p.lastUpdated = Date()
                peopleStore.upsert(p)
                personNotes = p.notes
            }
        }
    }

    // MARK: - Policies

    private func maybeGenerateSuggestion() async {
        guard isListening else { return }
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 60 else { return }

        let now = Date()
        let minInterval: TimeInterval
        switch outputMode {
        case .nudges: minInterval = 25
        case .full: minInterval = 12
        case .cluely: minInterval = 4
        }
        guard now.timeIntervalSince(lastSuggestionAt) >= minInterval else { return }

        let detectedLang = resolvedConversationLanguage(from: text)

        do {
            let suggestion = try await coach.suggest(
                objective: objective,
                mode: mode,
                recentTranscript: lastChunk(text, maxChars: 900),
                outputMode: outputMode,
                language: detectedLang
            )
            if suggestion.bullets.isEmpty { return }

            // Insert newest first, but avoid spamming duplicates.
            if let first = suggestions.first, first.bullets == suggestion.bullets { return }
            suggestions.insert(suggestion, at: 0)
            lastSuggestionAt = now

            if speakSuggestions {
                // For nudges/cluely: keep it extremely short.
                let speakText: String
                if outputMode == .full {
                    speakText = "\(suggestion.title). \(suggestion.bullets.prefix(2).joined(separator: ". "))"
                } else {
                    speakText = suggestion.bullets.first ?? ""
                }
                tts.speak(speakText, language: suggestion.language)
            }
        } catch {
            // ignore for MVP
        }
    }

    /// Discreet cue behavior:
    /// If user repeats/rephrases a question (e.g. "quieres saber..." or ends with '?'), we answer it.
    private func maybeAnswerDiscreetCue() async {
        guard isListening else { return }
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 25 else { return }

        let now = Date()
        guard now.timeIntervalSince(lastAnswerAt) >= 6 else { return }

        guard let q = DiscreetCueDetector.extractQuestion(from: text) else { return }
        let fingerprint = q.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard fingerprint != lastAnsweredQuestionFingerprint else { return }

        let detectedLang = resolvedConversationLanguage(from: text)

        do {
            let answer = try await coach.answer(
                question: q,
                objective: objective,
                mode: mode,
                language: detectedLang
            )
            if answer.bullets.isEmpty { return }
            suggestions.insert(answer, at: 0)
            lastAnswerAt = now
            lastAnsweredQuestionFingerprint = fingerprint

            if speakSuggestions {
                tts.speak(answer.bullets.first ?? "", language: answer.language)
            }
        } catch {
            // ignore
        }
    }

    private func resolvedConversationLanguage(from text: String) -> DetectedLanguage? {
        switch languageMode {
        case .english: return .en
        case .spanish: return .es
        case .auto:
            return LanguageDetector.detect(from: text)
        }
    }

    private func configureSpeechLocale() {
        // For MVP we keep SpeechRecognizer default locale.
        // If you want: create recognizer with explicit locale based on languageMode.
        // Speech framework doesn’t easily swap recognizer mid-stream without restarting.
    }

    private static func localTimestamp(_ date: Date = Date()) -> String {
        let df = DateFormatter()
        df.locale = .current
        df.timeZone = .current
        df.dateFormat = "yyyy-MM-dd HH:mm" // local time
        return df.string(from: date)
    }

    private func lastChunk(_ s: String, maxChars: Int) -> String {
        if s.count <= maxChars { return s }
        return String(s.suffix(maxChars))
    }
}
