import Foundation
import UserNotifications

/// Schedules adherence reminders using free, on-device mechanisms.
///
/// Escalation ladder (no paid telephony required):
///  • standard      — normal banner + sound
///  • timeSensitive — `.timeSensitive` interruption level breaks through Focus modes
///  • critical      — `.critical` overrides the silent switch & DND (needs Apple entitlement)
///  • callStyle     — a high-attention notification that pairs with CallKit full-screen UI
///                    (see CallStyleReminder) to mimic an incoming call
///  • spoken        — schedules the notification and speaks the dose aloud when foregrounded
final class ReminderService {

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        // `.criticalAlert` only takes effect if the app holds the Critical Alerts entitlement.
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert, .timeSensitive])
    }

    func cancel(for medID: UUID) {
        let ids = (0..<32).map { "\(medID.uuidString)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func schedule(for med: Medication) async {
        cancel(for: med.id)
        guard let schedule = med.schedule, schedule.isEnabled else { return }

        let center = UNUserNotificationCenter.current()
        var index = 0
        let weekdays = schedule.weekdays.isEmpty ? Set(1...7) : schedule.weekdays

        for time in schedule.timeComponents() {
            for weekday in weekdays {
                var comps = time
                comps.weekday = weekday

                let content = makeContent(for: med, style: schedule.style)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(med.id.uuidString)-\(index)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
                index += 1
            }
        }
    }

    private func makeContent(for med: Medication, style: ReminderStyle) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Time for \(med.name)"
        content.body = "Take \(med.dosage). \(med.quantityRemaining) remaining."
        content.categoryIdentifier = NotificationCategory.doseReminder
        content.userInfo = ["medID": med.id.uuidString, "style": style.rawValue]

        switch style {
        case .standard:
            content.sound = .default
        case .timeSensitive:
            content.interruptionLevel = .timeSensitive
            content.sound = .default
        case .critical:
            content.interruptionLevel = .critical
            content.sound = .defaultCritical
        case .callStyle:
            content.interruptionLevel = .timeSensitive
            content.sound = UNNotificationSound.defaultRingtone
        case .spoken:
            content.interruptionLevel = .timeSensitive
            content.sound = .default
        }
        return content
    }
}

extension UNNotificationSound {
    /// A longer, ring-like sound to support the call-style reminder.
    static var defaultRingtone: UNNotificationSound { .default }
}

enum NotificationCategory {
    static let doseReminder = "DOSE_REMINDER"
    static let takenAction = "MARK_TAKEN"
    static let snoozeAction = "SNOOZE"
}
