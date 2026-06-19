import UIKit
import UserNotifications

/// Handles notification presentation and the "Taken" / "Snooze" actions a user can tap
/// directly from a dose reminder. Decrements remaining quantity and reschedules snoozes.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    /// Set by the SwiftUI app so the delegate can mutate the store from notification actions.
    weak var store: MedicationStore?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories([Self.doseCategory])
        return true
    }

    static var doseCategory: UNNotificationCategory {
        let taken = UNNotificationAction(
            identifier: NotificationCategory.takenAction,
            title: "Mark as taken",
            options: [.authenticationRequired]
        )
        let snooze = UNNotificationAction(
            identifier: NotificationCategory.snoozeAction,
            title: "Snooze 15 min",
            options: []
        )
        return UNNotificationCategory(
            identifier: NotificationCategory.doseReminder,
            actions: [taken, snooze],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
    }

    // Show reminders even while the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    // Respond to action buttons / taps.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        guard let idString = info["medID"] as? String, let id = UUID(uuidString: idString) else { return }
        let actionID = response.actionIdentifier

        await MainActor.run { [store] in
            guard let med = store?.medications.first(where: { $0.id == id }) else { return }

            switch actionID {
            case NotificationCategory.takenAction:
                store?.recordDoseTaken(med)
            case NotificationCategory.snoozeAction:
                AppDelegate.scheduleSnooze(for: med)
            default:
                break
            }
        }
    }

    private static func scheduleSnooze(for med: Medication) {
        let content = UNMutableNotificationContent()
        content.title = "Snoozed: \(med.name)"
        content.body = "Take \(med.dosage)."
        content.categoryIdentifier = NotificationCategory.doseReminder
        content.interruptionLevel = .timeSensitive
        content.sound = .default
        content.userInfo = ["medID": med.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: "\(med.id.uuidString)-snooze", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
