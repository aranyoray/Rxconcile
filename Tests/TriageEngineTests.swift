import XCTest
@testable import Rxconcile

final class TriageEngineTests: XCTestCase {
    let engine = TriageEngine()

    private func med(_ name: String,
                     form: PackagingForm = .sealedBlister,
                     ndc: String? = "12345-678-90",
                     expiresInDays: Int? = 365) -> Medication {
        let exp = expiresInDays.map { Calendar.current.date(byAdding: .day, value: $0, to: Date())! }
        return Medication(name: name, ndc: ndc, dosage: "10 mg", form: form,
                          quantityRemaining: 30, expirationDate: exp)
    }

    func testControlledSubstanceAlwaysRoutesToDisposal() {
        let result = engine.triage(med("Oxycodone 5mg"), stateCode: "TX")
        XCTAssertEqual(result.decision, .authorizedDisposal)
    }

    func testBrandNameControlledSubstanceCaught() {
        let result = engine.triage(med("Xanax"), stateCode: "TX")
        XCTAssertEqual(result.decision, .authorizedDisposal)
    }

    func testExpiredRoutesToDisposal() {
        let result = engine.triage(med("Amoxicillin", expiresInDays: -5), stateCode: "TX")
        XCTAssertEqual(result.decision, .authorizedDisposal)
    }

    func testOpenedVialNotDonatable() {
        let result = engine.triage(med("Lisinopril", form: .openedVial), stateCode: "TX")
        XCTAssertEqual(result.decision, .authorizedDisposal)
    }

    func testNoStateProgramRoutesToDisposal() {
        let result = engine.triage(med("Lisinopril"), stateCode: "ZZ")
        XCTAssertEqual(result.decision, .authorizedDisposal)
    }

    func testShortShelfLifeRoutesToDisposal() {
        let result = engine.triage(med("Lisinopril", expiresInDays: 10), stateCode: "TX")
        XCTAssertEqual(result.decision, .authorizedDisposal)
    }

    func testUnidentifiedDrugAsksPharmacist() {
        let result = engine.triage(med("Lisinopril", ndc: nil), stateCode: "TX")
        XCTAssertEqual(result.decision, .askPharmacist)
    }

    func testEligibleDonation() {
        let result = engine.triage(med("Lisinopril"), stateCode: "TX")
        XCTAssertEqual(result.decision, .donationReview)
    }
}

final class ControlledSubstanceCheckerTests: XCTestCase {
    let checker = ControlledSubstanceChecker()

    func testKnownControlled() {
        XCTAssertTrue(checker.evaluate(name: "Adderall XR", ndc: nil).isControlled)
    }

    func testNonControlledNotFlagged() {
        XCTAssertFalse(checker.evaluate(name: "Metformin", ndc: "111-222-33").isControlled)
    }

    func testNoNDCNotConfidentlyCleared() {
        XCTAssertFalse(checker.evaluate(name: "Metformin", ndc: nil).confidentlyCleared)
    }
}

final class ReconciliationServiceTests: XCTestCase {
    func testRoundTrip() {
        let service = ReconciliationService()
        let meds = [Medication(name: "Lisinopril", dosage: "10 mg",
                               form: .sealedBottle, quantityRemaining: 30,
                               schedule: .daily(at: [480]))]
        let payload = service.makePayload(from: meds)
        let data = try! JSONEncoder.rxconcile.encode(payload)
        let decoded = service.decode(String(data: data, encoding: .utf8)!)
        XCTAssertEqual(decoded?.medications.first?.name, "Lisinopril")
        XCTAssertEqual(decoded?.medications.first?.schedule, "1x daily")
    }
}
