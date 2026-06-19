import Foundation

/// State-by-state donation rules. Drug donation/repository programs vary widely by
/// state (some accept cancer drugs only, some require sealed unit-dose, some have no
/// program at all). This is a simplified rules tree keyed by US state code.
struct StateRulesEngine {

    struct StateRule {
        let stateCode: String
        let hasRepositoryProgram: Bool
        /// Minimum days of remaining shelf life a repository will accept.
        let minimumDaysToExpiry: Int
        /// Whether the program accepts general medications vs. a narrow category only.
        let acceptsGeneralMedications: Bool
        let notes: String
    }

    /// Seed of representative rules. Expand with a maintained dataset per state DOH/board of pharmacy.
    private static let rules: [String: StateRule] = [
        "TX": StateRule(stateCode: "TX", hasRepositoryProgram: true, minimumDaysToExpiry: 90,
                        acceptsGeneralMedications: true,
                        notes: "Texas accepts a broad range of sealed donations via charitable pharmacies."),
        "OH": StateRule(stateCode: "OH", hasRepositoryProgram: true, minimumDaysToExpiry: 90,
                        acceptsGeneralMedications: true,
                        notes: "Ohio's program accepts most non-controlled, sealed medications."),
        "CA": StateRule(stateCode: "CA", hasRepositoryProgram: true, minimumDaysToExpiry: 180,
                        acceptsGeneralMedications: true,
                        notes: "California requires county program participation; longer shelf life preferred."),
        "IA": StateRule(stateCode: "IA", hasRepositoryProgram: true, minimumDaysToExpiry: 90,
                        acceptsGeneralMedications: true,
                        notes: "Iowa SafeNetRx is a mature statewide repository."),
    ]

    func rule(forState code: String) -> StateRule {
        rules[code.uppercased()] ?? StateRule(
            stateCode: code.uppercased(),
            hasRepositoryProgram: false,
            minimumDaysToExpiry: 180,
            acceptsGeneralMedications: false,
            notes: "No verified statewide repository on file. Default to authorized disposal or ask a pharmacist."
        )
    }

    static let supportedStateCodes = Array(rules.keys).sorted()
}
