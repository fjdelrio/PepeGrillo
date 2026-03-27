import Foundation
import AVFoundation

final class TTSManager {
    private let synth = AVSpeechSynthesizer()

    /// Default: infer from text; fallback to es-MX.
    func speak(_ text: String, language: DetectedLanguage? = nil) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            // Keep compatible with Bluetooth output.
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP, .duckOthers])
            try session.setActive(true)
        } catch {
            // ignore
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.volume = 0.9

        // Infer language from text if not provided, so voice matches output language.
        let resolved = language ?? LanguageDetector.detect(from: text)

        let bcp47: String
        switch resolved {
        case .en?: bcp47 = "en-US"
        case .es?, nil: bcp47 = "es-MX"
        }
        utterance.voice = AVSpeechSynthesisVoice(language: bcp47)

        synth.speak(utterance)
    }
}
