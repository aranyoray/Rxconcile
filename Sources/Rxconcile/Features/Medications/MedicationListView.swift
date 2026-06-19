import SwiftUI

struct MedicationListView: View {
    @EnvironmentObject var store: MedicationStore
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if store.medications.isEmpty {
                    ContentUnavailableView(
                        "No medications yet",
                        systemImage: "pills",
                        description: Text("Add a medication to track doses, get reminders, and triage leftovers.")
                    )
                } else {
                    List {
                        ForEach(store.medications) { med in
                            NavigationLink(value: med) {
                                MedicationRow(med: med)
                            }
                        }
                        .onDelete(perform: deleteRows)
                    }
                }
            }
            .navigationTitle("My Medications")
            .navigationDestination(for: Medication.self) { med in
                MedicationDetailView(med: med)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add medication")
                }
            }
            .sheet(isPresented: $showingAdd) {
                MedicationEditView(med: nil)
            }
        }
    }

    private func deleteRows(_ offsets: IndexSet) {
        offsets.map { store.medications[$0] }.forEach(store.delete)
    }
}

struct MedicationRow: View {
    let med: Medication

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(med.name).font(.headline)
                if med.isExpired {
                    Text("EXPIRED").font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.red.opacity(0.15)).foregroundStyle(.red)
                        .clipShape(Capsule())
                }
            }
            Text("\(med.dosage) • \(med.quantityRemaining) left")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
