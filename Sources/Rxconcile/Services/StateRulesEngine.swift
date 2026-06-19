import Foundation

/// State-by-state donation rules, loaded from the bundled `state_rules.json`. Drug
/// donation/repository programs vary widely by state, so the dataset is curated and
/// versioned; update it against the authoritative statute before relying on an entry.
struct StateRulesEngine {

    struct StateRule: Decodable {
        let stateCode: String
        let hasRepositoryProgram: Bool
        let minimumDaysToExpiry: Int
        let acceptsGeneralMedications: Bool
        let notes: String
    }

    private let rules: [String: StateRule]

    init(rules: [String: StateRule] = StateRulesEngine.bundled) {
        self.rules = rules
    }

    func rule(forState code: String) -> StateRule {
        rules[code.uppercased()] ?? StateRule(
            stateCode: code.uppercased(),
            hasRepositoryProgram: false,
            minimumDaysToExpiry: 180,
            acceptsGeneralMedications: false,
            notes: "No verified statewide repository on file. Default to authorized disposal or ask a pharmacist."
        )
    }

    var supportedStateCodes: [String] { rules.keys.sorted() }

    // MARK: - Loading

    private struct File: Decodable { let states: [StateRule] }

    static let bundled: [String: StateRule] = load()

    private static func load() -> [String: StateRule] {
        guard let url = Bundle.main.url(forResource: "state_rules", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: file.states.map { ($0.stateCode.uppercased(), $0) })
    }
}
