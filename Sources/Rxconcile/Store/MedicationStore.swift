import Foundation
import Combine

/// Source of truth for the user's medications. Persists to an on-device JSON file in
/// Application Support. No data leaves the device — supports the offline medication list
/// and HIPAA-minimization goals.
@MainActor
final class MedicationStore: ObservableObject {
    @Published private(set) var medications: [Medication] = []

    private let fileURL: URL
    private let reminders: ReminderService

    init(reminders: ReminderService = ReminderService()) {
        self.reminders = reminders
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("medications.json")
        load()
    }

    func add(_ med: Medication) {
        medications.append(med)
        save()
        rescheduleReminders(for: med)
    }

    func update(_ med: Medication) {
        guard let idx = medications.firstIndex(where: { $0.id == med.id }) else { return }
        medications[idx] = med
        save()
        rescheduleReminders(for: med)
    }

    func delete(_ med: Medication) {
        medications.removeAll { $0.id == med.id }
        save()
        reminders.cancel(for: med.id)
    }

    func recordDoseTaken(_ med: Medication) {
        guard let idx = medications.firstIndex(where: { $0.id == med.id }) else { return }
        if medications[idx].quantityRemaining > 0 {
            medications[idx].quantityRemaining -= 1
            save()
        }
    }

    private func rescheduleReminders(for med: Medication) {
        Task { await reminders.schedule(for: med) }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder.rxconcile.decode([Medication].self, from: data) else { return }
        medications = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder.rxconcile.encode(medications) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}

extension JSONEncoder {
    static var rxconcile: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }
}

extension JSONDecoder {
    static var rxconcile: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
