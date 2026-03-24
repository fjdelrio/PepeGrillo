import Foundation
import AVFoundation

final class TTSManager {
    private let synth = AVSpeechSynthesizer()

    /// Default: es-MX. If language is provided, we select a matching voice.
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

        // Default to Spanish (Mexico). Switch to English (US) if detected.
        let bcp47: String
        switch language {
        case .en: bcp47 = "en-US"
        case .es, .none: bcp47 = "es-MX"
        }
        utterance.voice = AVSpeechSynthesisVoice(language: bcp47)

        synth.speak(utterance)
    }
}
