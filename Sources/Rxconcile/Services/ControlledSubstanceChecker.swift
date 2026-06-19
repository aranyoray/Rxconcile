import Foundation

/// Determines whether a medication is a federally controlled substance (DEA Schedule II–V).
///
/// Backed by a bundled dataset (`controlled_substances.json`) generated from the openFDA
/// NDC Directory's `dea_schedule` field (see scripts/build_controlled_substances.py),
/// merged with a curated ingredient seed. The engine has a zero-failure bias: anything we
/// cannot positively clear is treated as not donatable.
struct ControlledSubstanceChecker {

    enum Schedule: String {
        case i = "I", ii = "II", iii = "III", iv = "IV", v = "V"
        case none
    }

    struct Verdict {
        let isControlled: Bool
        let schedule: Schedule
        let confidentlyCleared: Bool
    }

    private let dataset: Dataset

    init(dataset: Dataset = .shared) {
        self.dataset = dataset
    }

    func evaluate(name: String, ndc: String?) -> Verdict {
        // 1. Exact NDC match against the live DEA-scheduled dataset (most authoritative).
        if let ndc, let normalized = Dataset.normalize(ndc),
           let raw = dataset.ndc[normalized], let schedule = Schedule(rawValue: raw) {
            return Verdict(isControlled: true, schedule: schedule, confidentlyCleared: false)
        }

        // 2. Ingredient / name keyword match.
        let lowered = name.lowercased()
        for (keyword, raw) in dataset.ingredients where lowered.contains(keyword) {
            return Verdict(isControlled: true, schedule: Schedule(rawValue: raw) ?? .none,
                           confidentlyCleared: false)
        }

        // 3. Not flagged as controlled. We only treat it as confidently cleared when we have
        //    a scanned NDC to anchor the identification; a name-only entry stays unconfirmed.
        let cleared = Dataset.normalize(ndc ?? "") != nil
        return Verdict(isControlled: false, schedule: .none, confidentlyCleared: cleared)
    }
}

extension ControlledSubstanceChecker {
    /// Loads and caches the bundled controlled-substance dataset.
    struct Dataset {
        let ingredients: [String: String]
        let ndc: [String: String]

        static let shared: Dataset = load()

        private struct File: Decodable {
            let ingredients: [String: String]
            let ndc: [String: String]
        }

        static func normalize(_ ndc: String) -> String? {
            let trimmed = ndc.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? nil : trimmed
        }

        static func load() -> Dataset {
            guard let url = Bundle.main.url(forResource: "controlled_substances", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let file = try? JSONDecoder().decode(File.self, from: data) else {
                return Dataset(ingredients: Self.fallbackIngredients, ndc: [:])
            }
            return Dataset(ingredients: file.ingredients, ndc: file.ndc)
        }

        /// Minimal safety net if the bundled JSON is missing for any reason.
        static let fallbackIngredients: [String: String] = [
            "oxycodone": "II", "hydrocodone": "II", "fentanyl": "II", "adderall": "II",
            "alprazolam": "IV", "xanax": "IV", "diazepam": "IV", "tramadol": "IV"
        ]
    }
}
