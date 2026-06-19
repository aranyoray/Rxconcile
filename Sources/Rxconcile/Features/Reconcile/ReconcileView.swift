import SwiftUI

struct ReconcileView: View {
    @EnvironmentObject var store: MedicationStore
    private let service = ReconciliationService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Show this code to a clinic or ER to share your current medication list — works fully offline.")
                        .font(.footnote).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if let image = service.qrImage(for: store.medications) {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 280)
                            .padding()
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .accessibilityLabel("Medication reconciliation QR code with \(store.medications.count) medications")
                    } else {
                        ContentUnavailableView("Nothing to reconcile",
                                               systemImage: "qrcode",
                                               description: Text("Add medications to generate a reconciliation code."))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(store.medications) { med in
                            Text("• \(med.name) — \(med.dosage)")
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Reconcile")
        }
    }
}
