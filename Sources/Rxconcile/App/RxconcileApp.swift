import SwiftUI

@main
struct RxconcileApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = MedicationStore()
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    private let reminders = ReminderService()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(store)
            .onAppear { appDelegate.store = store }
            .task {
                appDelegate.store = store
                await reminders.requestAuthorization()
            }
        }
    }
}
