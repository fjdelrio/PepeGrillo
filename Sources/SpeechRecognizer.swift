import Foundation
import Speech
import AVFoundation

/// Minimal live speech-to-text using Apple's Speech framework.
/// Works best for the device language; requires user permission.
final class SpeechRecognizer: NSObject, ObservableObject {
    @Published var partialTranscript: String = ""

    func resetTranscript() {
        DispatchQueue.main.async {
            self.partialTranscript = ""
        }
    }

    // Recreate engine on start() to survive route/sample-rate changes (e.g. Bluetooth HFP 16kHz).
    private var audioEngine = AVAudioEngine()
    private let recognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestPermissions(_ completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { auth in
            DispatchQueue.main.async {
                let speechOK = (auth == .authorized)
                AVAudioSession.sharedInstance().requestRecordPermission { micOK in
                    DispatchQueue.main.async {
                        completion(speechOK && micOK)
                    }
                }
            }
        }
    }

    func start() {
        stop()

        guard let recognizer, recognizer.isAvailable else { return }

        // Important: Bluetooth headset mic typically uses HFP (often 16kHz).
        // If the engine is configured for 48kHz and route flips to HFP, AVAudioEngine tap can fail.
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)

            // .playAndRecord so TTS can output to BT headphones while recording.
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth, .defaultToSpeaker, .duckOthers]
            )

            // Prefer Bluetooth HFP input if available.
            if let bt = session.availableInputs?.first(where: { $0.portType == .bluetoothHFP }) {
                try session.setPreferredInput(bt)
                // HFP commonly runs at 16kHz.
                try session.setPreferredSampleRate(16_000)
            } else {
                // Default device mic typically runs at 48kHz.
                try session.setPreferredSampleRate(48_000)
            }

            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }

        // Recreate engine AFTER audio session is active, so formats match the current route.
        audioEngine = AVAudioEngine()

        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            return
        }

        task = recognizer.recognitionTask(with: request!) { [weak self] result, error in
            guard let self else { return }
            if let result {
                DispatchQueue.main.async {
                    self.partialTranscript = result.bestTranscription.formattedString
                }
            }
            if error != nil {
                self.stop()
            }
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil

        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
