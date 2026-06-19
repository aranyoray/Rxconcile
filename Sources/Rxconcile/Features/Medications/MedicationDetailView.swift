import SwiftUI

struct MedicationDetailView: View {
    @EnvironmentObject var store: MedicationStore
    @State private var showingEdit = false
    let med: Medication

    private var current: Medication {
        store.medications.first(where: { $0.id == med.id }) ?? med
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Dosage", value: current.dosage)
                LabeledContent("Packaging", value: current.form.rawValue)
                LabeledContent("Remaining", value: "\(current.quantityRemaining)")
                if let ndc = current.ndc { LabeledContent("NDC", value: ndc) }
                if let exp = current.expirationDate {
                    LabeledContent("Expires", value: exp.formatted(date: .abbreviated, time: .omitted))
                }
            }

            Section {
                Button {
                    store.recordDoseTaken(current)
                    SpeechService.shared.speak("Dose recorded for \(current.name)")
                } label: {
                    Label("Mark dose taken", systemImage: "checkmark.circle.fill")
                }

                NavigationLink {
                    TriageResultView(med: current)
                } label: {
                    Label("Triage this medication", systemImage: "arrow.triangle.branch")
                }
            }
        }
        .navigationTitle(current.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            MedicationEditView(med: current)
        }
    }
}
