import SwiftUI

@main
struct RxconcileApp: App {
    @StateObject private var store = MedicationStore()
    private let reminders = ReminderService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .task {
                    await reminders.requestAuthorization()
                }
        }
    }
}
