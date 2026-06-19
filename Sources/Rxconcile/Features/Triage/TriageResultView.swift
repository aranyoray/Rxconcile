import SwiftUI

struct TriageResultView: View {
    @AppStorage("stateCode") private var stateCode: String = "TX"
    @AppStorage("donorName") private var donorName: String = ""
    @State private var formURL: URL?
    let med: Medication

    private var result: TriageResult {
        TriageEngine().triage(med, stateCode: stateCode)
    }

    var body: some View {
        let r = result
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: r.decision.systemImage)
                    .font(.system(size: 56))
                    .foregroundStyle(tint(for: r.decision))
                    .padding(.top)

                Text(r.decision.headline)
                    .font(.title2).bold()
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(r.reasons, id: \.self) { reason in
                        Label(reason, systemImage: "info.circle")
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                nextSteps(for: r.decision)
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Triage Result")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            SpeechService.shared.speak("\(med.name). \(r.decision.headline).")
        }
    }

    private func tint(for d: TriageResult.Decision) -> Color {
        switch d {
        case .donationReview:     return .green
        case .authorizedDisposal: return .red
        case .askPharmacist:      return .orange
        }
    }

    @ViewBuilder
    private func nextSteps(for decision: TriageResult.Decision) -> some View {
        VStack(spacing: 12) {
            switch decision {
            case .donationReview:
                Link(destination: URL(string: "https://www.sirum.org")!) {
                    Label("Find a licensed repository (SIRUM)", systemImage: "heart.text.square")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    let donor = DonationFormGenerator.DonorInfo(donorName: donorName, stateCode: stateCode)
                    formURL = DonationFormGenerator().makePDF(medication: med, donor: donor)
                } label: {
                    Label("Generate donor transfer form", systemImage: "doc.text")
                }
                .buttonStyle(.bordered)

                if let formURL {
                    ShareLink(item: formURL) {
                        Label("Share / sign form", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }

                Text("A pharmacist or repository confirms final eligibility before accepting the donation.")
                    .font(.caption).foregroundStyle(.secondary)
            case .authorizedDisposal:
                Link(destination: URL(string: "https://apps.deadiversion.usdoj.gov/pubdispsearch/spring/main?execution=e1s1")!) {
                    Label("Find a DEA take-back location", systemImage: "mappin.and.ellipse")
                }
                .buttonStyle(.borderedProminent)
            case .askPharmacist:
                Text("Bring the sealed package to your pharmacist to confirm donation eligibility.")
                    .font(.callout).multilineTextAlignment(.center)
            }
        }
    }
}
