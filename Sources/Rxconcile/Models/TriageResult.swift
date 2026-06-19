import Foundation

/// The definitive routing ruling for a piece of leftover medication.
///
/// Framing note: Rxconcile never enables peer-to-peer drug transfer. It routes a
/// medication toward *licensed donation review* or *authorized disposal* only.
struct TriageResult: Identifiable {
    let id = UUID()
    let decision: Decision
    let reasons: [String]
    let medicationName: String

    enum Decision: Equatable {
        /// Eligible to be reviewed by a licensed repository / charitable pharmacy.
        case donationReview
        /// Must go to authorized take-back / DEA disposal.
        case authorizedDisposal
        /// Ambiguous — ask a pharmacist before acting.
        case askPharmacist

        var headline: String {
            switch self {
            case .donationReview:     return "May qualify for donation review"
            case .authorizedDisposal: return "Route to authorized disposal"
            case .askPharmacist:      return "Check with a pharmacist first"
            }
        }

        var systemImage: String {
            switch self {
            case .donationReview:     return "heart.text.square.fill"
            case .authorizedDisposal: return "trash.fill"
            case .askPharmacist:      return "questionmark.circle.fill"
            }
        }
    }
}
