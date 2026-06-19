import Foundation

/// A medication the user is tracking. Stored entirely on-device.
struct Medication: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    /// National Drug Code, when known (from a scanned label).
    var ndc: String?
    var dosage: String          // e.g. "10 mg"
    var form: PackagingForm
    var quantityRemaining: Int
    var expirationDate: Date?
    var notes: String?
    var schedule: ReminderSchedule?
    var dateAdded: Date = Date()

    var isExpired: Bool {
        guard let expirationDate else { return false }
        return expirationDate < Date()
    }
}

/// Physical packaging — central to donation eligibility. Loose pills in an
/// opened amber vial are almost never donatable; sealed unit-dose is.
enum PackagingForm: String, Codable, CaseIterable, Identifiable {
    case sealedBlister      = "Sealed blister / unit-dose"
    case sealedBottle       = "Sealed, unopened bottle"
    case openedVial         = "Opened amber vial (loose pills)"
    case liquid             = "Liquid / suspension"
    case injectable         = "Injectable"
    case other              = "Other"

    var id: String { rawValue }

    /// Tamper-evident, factory-sealed packaging is a baseline donation requirement
    /// in most state repository programs.
    var isTamperEvidentSealed: Bool {
        self == .sealedBlister || self == .sealedBottle
    }
}
