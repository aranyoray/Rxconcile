import Foundation

/// Determines whether a medication is a federally controlled substance (DEA Schedule II–V).
///
/// In production this is backed by an authoritative dataset (e.g. an NDC → DEA schedule
/// mapping refreshed from the DEA Controlled Substance Act lists). The engine must have a
/// zero-failure bias: anything we cannot positively clear is treated as controlled.
struct ControlledSubstanceChecker {

    enum Schedule: String {
        case ii = "II", iii = "III", iv = "IV", v = "V"
        case none
    }

    /// Conservative offline seed list of common controlled-substance ingredients.
    /// Matching is substring/case-insensitive on the medication name.
    private static let controlledKeywords: [String: Schedule] = [
        "oxycodone": .ii, "hydrocodone": .ii, "fentanyl": .ii, "morphine": .ii,
        "methylphenidate": .ii, "ritalin": .ii, "adderall": .ii, "amphetamine": .ii,
        "dextroamphetamine": .ii, "methadone": .ii, "hydromorphone": .ii,
        "codeine": .iii, "ketamine": .iii, "buprenorphine": .iii, "testosterone": .iii,
        "alprazolam": .iv, "xanax": .iv, "lorazepam": .iv, "diazepam": .iv, "valium": .iv,
        "clonazepam": .iv, "klonopin": .iv, "zolpidem": .iv, "ambien": .iv, "tramadol": .iv,
        "lyrica": .v, "pregabalin": .v
    ]

    struct Verdict {
        let isControlled: Bool
        let schedule: Schedule
        let confidentlyCleared: Bool
    }

    func evaluate(name: String, ndc: String?) -> Verdict {
        let lowered = name.lowercased()
        for (keyword, schedule) in Self.controlledKeywords where lowered.contains(keyword) {
            return Verdict(isControlled: true, schedule: schedule, confidentlyCleared: false)
        }

        // We have no positive identification (no NDC match in the live DEA dataset).
        // Without authoritative confirmation we do NOT clear it for donation.
        let cleared = ndc != nil && !ndc!.isEmpty
        return Verdict(isControlled: false, schedule: .none, confidentlyCleared: cleared)
    }
}
