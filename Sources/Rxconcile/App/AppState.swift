import Foundation
import SwiftUI

/// Lightweight global preferences persisted in UserDefaults.
final class AppState: ObservableObject {
    @AppStorage("stateCode") var stateCode: String = "TX"
    @AppStorage("voiceLanguage") var voiceLanguage: String = Locale.current.identifier
    @AppStorage("defaultReminderStyle") var defaultReminderStyleRaw: String = ReminderStyle.timeSensitive.rawValue

    var defaultReminderStyle: ReminderStyle {
        ReminderStyle(rawValue: defaultReminderStyleRaw) ?? .timeSensitive
    }
}
