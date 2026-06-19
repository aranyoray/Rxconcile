import Foundation
import CoreImage.CIFilterBuiltins
import UIKit

/// Generates a QR code that encodes the user's *current medication list* for fast,
/// offline reconciliation at a clinic or ER. PHI is minimized: the payload contains
/// only what a clinician needs to reconcile, and the user can redact fields first.
struct ReconciliationService {

    /// Compact, versioned payload that travels inside the QR code.
    struct Payload: Codable {
        var version: Int = 1
        var generated: Date = Date()
        var medications: [Item]

        struct Item: Codable {
            let name: String
            let dosage: String
            let schedule: String   // human-readable, e.g. "2x daily"
        }
    }

    func makePayload(from meds: [Medication]) -> Payload {
        let items = meds.map { med -> Payload.Item in
            let count = med.schedule?.timesOfDay.count ?? 0
            let scheduleText = count > 0 ? "\(count)x daily" : "as needed"
            return .init(name: med.name, dosage: med.dosage, schedule: scheduleText)
        }
        return Payload(medications: items)
    }

    /// Render a QR image from the medication list. Returns nil if encoding fails.
    func qrImage(for meds: [Medication]) -> UIImage? {
        let payload = makePayload(from: meds)
        guard let data = try? JSONEncoder.rxconcile.encode(payload) else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }

        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    /// Decode a scanned reconciliation payload (e.g. from another device).
    func decode(_ string: String) -> Payload? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder.rxconcile.decode(Payload.self, from: data)
    }
}
