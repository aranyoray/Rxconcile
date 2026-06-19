import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            MedicationListView()
                .tabItem { Label("Meds", systemImage: "pills.fill") }

            TriageHomeView()
                .tabItem { Label("Triage", systemImage: "arrow.triangle.branch") }

            ReconcileView()
                .tabItem { Label("Reconcile", systemImage: "qrcode") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
