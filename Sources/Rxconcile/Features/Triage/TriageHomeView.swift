import SwiftUI

struct TriageHomeView: View {
    @EnvironmentObject var store: MedicationStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Rxconcile routes leftover medication toward **licensed donation review** or **authorized disposal**. It never enables person-to-person drug transfer.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Pick a medication to triage") {
                    if store.medications.isEmpty {
                        Text("Add a medication first.").foregroundStyle(.secondary)
                    }
                    ForEach(store.medications) { med in
                        NavigationLink {
                            TriageResultView(med: med)
                        } label: {
                            MedicationRow(med: med)
                        }
                    }
                }
            }
            .navigationTitle("Triage")
        }
    }
}
