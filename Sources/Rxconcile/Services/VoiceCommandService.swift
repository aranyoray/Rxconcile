import Foundation
import Speech
import AVFoundation

/// On-device, multi-language voice command recognition for accessibility and hands-free use.
/// Uses `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true` so no audio leaves
/// the device. Recognized phrases are mapped to intents (mark taken, add med, triage).
@MainActor
final class VoiceCommandService: ObservableObject {
    @Published var transcript: String = ""
    @Published var isListening: Bool = false
    @Published var lastIntent: Intent?

    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    enum Intent: Equatable {
        case markTaken(medName: String)
        case addMedication
        case startTriage
        case unknown(String)
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    func start(localeIdentifier: String = Locale.current.identifier) throws {
        stop()
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
        guard let recognizer, recognizer.isAvailable else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        let input = audioEngine.inputNode
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        isListening = true

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            // The result handler may be invoked off the main thread; hop back to the
            // main actor before touching published state.
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let text {
                    self.transcript = text
                    if isFinal { self.lastIntent = Self.parse(text) }
                }
                if failed { self.stop() }
            }
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isListening = false
    }

    /// Lightweight keyword intent parser. A production build localizes these triggers.
    static func parse(_ text: String) -> Intent {
        let t = text.lowercased()
        if t.contains("took") || t.contains("taken") || t.contains("mark") {
            return .markTaken(medName: t)
        }
        if t.contains("add") { return .addMedication }
        if t.contains("donate") || t.contains("dispose") || t.contains("triage") { return .startTriage }
        return .unknown(text)
    }
}
