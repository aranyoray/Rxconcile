import Foundation
import Vision
import UIKit

/// Extracts medication details from a photo of a label using on-device Vision OCR.
/// The image is processed for text and then discarded by the caller — no PHI image
/// is persisted, in line with the privacy model.
struct LabelScanner {

    struct Extraction {
        var name: String?
        var ndc: String?
        var expiration: Date?
        var rawLines: [String]
    }

    /// NDC appears as 4-4-2, 5-4-1, 5-3-2, or 5-4-2 digit groups.
    private static let ndcRegex = try! NSRegularExpression(
        pattern: #"\b\d{4,5}-\d{3,4}-\d{1,2}\b"#
    )

    func scan(_ image: UIImage) async -> Extraction {
        guard let cg = image.cgImage else { return Extraction(rawLines: []) }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cg, orientation: cgOrientation(image), options: [:])
        try? handler.perform([request])

        let lines = (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }

        return Extraction(
            name: guessName(from: lines),
            ndc: firstNDC(in: lines),
            expiration: firstExpiry(in: lines),
            rawLines: lines
        )
    }

    private func firstNDC(in lines: [String]) -> String? {
        for line in lines {
            let range = NSRange(line.startIndex..., in: line)
            if let m = Self.ndcRegex.firstMatch(in: line, range: range),
               let r = Range(m.range, in: line) {
                return String(line[r])
            }
        }
        return nil
    }

    private func firstExpiry(in lines: [String]) -> Date? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        for line in lines where line.lowercased().contains("exp") {
            let range = NSRange(line.startIndex..., in: line)
            if let match = detector?.firstMatch(in: line, range: range), let date = match.date {
                return date
            }
        }
        return nil
    }

    /// Heuristic: the drug name is usually the longest alphabetic line near the top.
    private func guessName(from lines: [String]) -> String? {
        lines
            .prefix(6)
            .filter { $0.rangeOfCharacter(from: .letters) != nil && $0.count >= 4 }
            .max(by: { $0.count < $1.count })
    }

    private func cgOrientation(_ image: UIImage) -> CGImagePropertyOrientation {
        CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)) ?? .up
    }
}
