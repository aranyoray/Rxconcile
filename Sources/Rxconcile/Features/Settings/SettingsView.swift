import SwiftUI

struct SettingsView: View {
    @AppStorage("stateCode") private var stateCode: String = "TX"
    @AppStorage("voiceLanguage") private var voiceLanguage: String = "en-US"
    @AppStorage("defaultReminderStyle") private var reminderStyleRaw: String = ReminderStyle.timeSensitive.rawValue
    @AppStorage("donorName") private var donorName: String = ""

    @StateObject private var voice = VoiceCommandService()

    private let languages = ["en-US", "es-ES", "es-MX", "hi-IN", "zh-CN", "fr-FR", "ar-SA", "pt-BR"]
    private let states = ["TX", "OH", "CA", "IA", "NY", "FL", "WA"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    Picker("My state", selection: $stateCode) {
                        ForEach(states, id: \.self) { Text($0).tag($0) }
                    }
                    Text("Donation rules vary by state. We use this to triage correctly.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Donor") {
                    TextField("Your name (for transfer forms)", text: $donorName)
                        .textContentType(.name)
                }

                Section("Reminders") {
                    Picker("Default reminder style", selection: $reminderStyleRaw) {
                        ForEach(ReminderStyle.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                }

                Section("Accessibility & Voice") {
                    Picker("Voice language", selection: $voiceLanguage) {
                        ForEach(languages, id: \.self) { Text($0).tag($0) }
                    }
                    Button {
                        Task { await toggleVoice() }
                    } label: {
                        Label(voice.isListening ? "Stop listening" : "Try a voice command",
                              systemImage: voice.isListening ? "mic.fill" : "mic")
                    }
                    if !voice.transcript.isEmpty {
                        Text("Heard: \(voice.transcript)").font(.caption)
                    }
                    Button("Speak a test phrase") {
                        SpeechService.shared.speak("Rxconcile voice is working.", language: voiceLanguage)
                    }
                }

                Section("Privacy") {
                    Text("Your medication list never leaves this device. Scanned label images are processed for text and immediately discarded — no PHI is stored or uploaded.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func toggleVoice() async {
        if voice.isListening { voice.stop(); return }
        guard await voice.requestAuthorization() else { return }
        try? voice.start(localeIdentifier: voiceLanguage)
    }
}
