import Foundation
import Speech
import AVFoundation

/// Minimal live speech-to-text using Apple's Speech framework.
/// Works best for the device language; requires user permission.
final class SpeechRecognizer: NSObject, ObservableObject {
    @Published var partialTranscript: String = ""

    private let audioEngine = AVAudioEngine()
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

        let session = AVAudioSession.sharedInstance()
        do {
            // .playAndRecord so TTS can output to BT headphones while recording.
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker, .duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }

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
