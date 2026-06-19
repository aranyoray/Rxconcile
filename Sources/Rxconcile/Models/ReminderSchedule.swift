import Foundation

/// A recurring intake schedule for a medication.
struct ReminderSchedule: Codable, Hashable {
    /// Times of day, stored as minutes-from-midnight so they survive timezone moves.
    var timesOfDay: [Int]
    /// Days of week the reminder fires (1 = Sunday ... 7 = Saturday). Empty = every day.
    var weekdays: Set<Int>
    var style: ReminderStyle
    var isEnabled: Bool = true

    static func daily(at minutes: [Int], style: ReminderStyle = .timeSensitive) -> ReminderSchedule {
        ReminderSchedule(timesOfDay: minutes, weekdays: [], style: style)
    }

    func timeComponents() -> [DateComponents] {
        timesOfDay.map { minutes in
            var c = DateComponents()
            c.hour = minutes / 60
            c.minute = minutes % 60
            return c
        }
    }
}

/// Escalating reminder strategies. We layer free, on-device mechanisms rather than
/// relying on a paid telephony service to "call" the user.
enum ReminderStyle: String, Codable, CaseIterable, Identifiable {
    /// Standard banner + sound.
    case standard = "Standard notification"
    /// Time-Sensitive interruption level — breaks through Focus / scheduled summary.
    case timeSensitive = "Time-Sensitive (breaks Focus)"
    /// Critical Alert — overrides silent switch & Do Not Disturb (requires Apple entitlement).
    case critical = "Critical alert (overrides silent)"
    /// A simulated "incoming call" full-screen reminder using CallKit (free, on-device).
    case callStyle = "Call-style alert"
    /// Speaks the reminder aloud in the user's language via on-device TTS.
    case spoken = "Spoken aloud"

    var id: String { rawValue }
}
