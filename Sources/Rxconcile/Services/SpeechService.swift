import Foundation
import AVFoundation

/// On-device text-to-speech for spoken reminders and accessibility. Uses the system
/// neural voices, which are free and fully offline. Supports many languages by BCP-47 tag.
final class SpeechService {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()

    /// Speak a string in the given language (e.g. "en-US", "es-ES", "hi-IN", "zh-CN").
    func speak(_ text: String, language: String = Locale.current.identifier) {
        configureSession()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language) ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.duckOthers])
        try? session.setActive(true)
    }
}
