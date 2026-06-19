import Foundation

/// Combines the controlled-substance check, packaging, expiry, and state rules into a
/// single, conservative routing decision.
struct TriageEngine {
    let controlledChecker = ControlledSubstanceChecker()
    let stateRules = StateRulesEngine()

    func triage(_ med: Medication, stateCode: String) -> TriageResult {
        var reasons: [String] = []

        // 1. Controlled substances can never be routed to donation. Hard stop.
        let verdict = controlledChecker.evaluate(name: med.name, ndc: med.ndc)
        if verdict.isControlled {
            reasons.append("Appears to be a DEA Schedule \(verdict.schedule.rawValue) controlled substance. Controlled medications cannot be donated and must be surrendered to an authorized take-back location.")
            return TriageResult(decision: .authorizedDisposal, reasons: reasons, medicationName: med.name)
        }

        // 2. Expiry / shelf-life.
        let rule = stateRules.rule(forState: stateCode)
        if med.isExpired {
            reasons.append("This medication is past its expiration date. Expired medication is not eligible for donation.")
            return TriageResult(decision: .authorizedDisposal, reasons: reasons, medicationName: med.name)
        }
        if let exp = med.expirationDate {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: exp).day ?? 0
            if days < rule.minimumDaysToExpiry {
                reasons.append("Only \(days) days of shelf life remain; \(rule.stateCode) repositories generally require at least \(rule.minimumDaysToExpiry).")
                return TriageResult(decision: .authorizedDisposal, reasons: reasons, medicationName: med.name)
            }
        }

        // 3. Packaging integrity.
        if !med.form.isTamperEvidentSealed {
            reasons.append("Packaging is \"\(med.form.rawValue)\". Most repositories only accept factory-sealed, tamper-evident packaging.")
            return TriageResult(decision: .authorizedDisposal, reasons: reasons, medicationName: med.name)
        }

        // 4. State program availability.
        if !rule.hasRepositoryProgram {
            reasons.append(rule.notes)
            return TriageResult(decision: .authorizedDisposal, reasons: reasons, medicationName: med.name)
        }
        if !rule.acceptsGeneralMedications {
            reasons.append("\(rule.stateCode)'s program is restricted in scope. Confirm category eligibility with a pharmacist before donating.")
            return TriageResult(decision: .askPharmacist, reasons: reasons, medicationName: med.name)
        }

        // 5. If we could not positively identify the drug we stay cautious.
        if !verdict.confidentlyCleared {
            reasons.append("We could not positively identify this medication from a scanned NDC. A pharmacist should confirm eligibility before donation review.")
            return TriageResult(decision: .askPharmacist, reasons: reasons, medicationName: med.name)
        }

        reasons.append("Non-controlled, sealed, and within shelf life. \(rule.notes)")
        reasons.append("Next step: a licensed repository/charitable pharmacy reviews the donation — Rxconcile never transfers medication between individuals.")
        return TriageResult(decision: .donationReview, reasons: reasons, medicationName: med.name)
    }
}
