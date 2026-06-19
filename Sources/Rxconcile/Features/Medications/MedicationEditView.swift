import SwiftUI

struct MedicationEditView: View {
    @EnvironmentObject var store: MedicationStore
    @Environment(\.dismiss) private var dismiss

    let med: Medication?

    @State private var name = ""
    @State private var dosage = ""
    @State private var ndc = ""
    @State private var form: PackagingForm = .sealedBottle
    @State private var quantity = 30
    @State private var hasExpiry = true
    @State private var expiration = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var remindersOn = false
    @State private var reminderTime = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Name", text: $name)
                    TextField("Dosage (e.g. 10 mg)", text: $dosage)
                    TextField("NDC (optional)", text: $ndc)
                        .keyboardType(.numbersAndPunctuation)
                    Picker("Packaging", selection: $form) {
                        ForEach(PackagingForm.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 0...1000)
                }
                Section("Expiration") {
                    Toggle("Has expiration date", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("Expires", selection: $expiration, displayedComponents: .date)
                    }
                }
                Section("Reminder") {
                    Toggle("Daily reminder", isOn: $remindersOn)
                    if remindersOn {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle(med == nil ? "Add Medication" : "Edit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(name.isEmpty)
                }
            }
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        guard let med else { return }
        name = med.name
        dosage = med.dosage
        ndc = med.ndc ?? ""
        form = med.form
        quantity = med.quantityRemaining
        hasExpiry = med.expirationDate != nil
        if let exp = med.expirationDate { expiration = exp }
        if let s = med.schedule, let first = s.timesOfDay.first {
            remindersOn = true
            reminderTime = Calendar.current.date(bySettingHour: first / 60, minute: first % 60, second: 0, of: Date()) ?? Date()
        }
    }

    private func save() {
        var schedule: ReminderSchedule?
        if remindersOn {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let minutes = (comps.hour ?? 8) * 60 + (comps.minute ?? 0)
            schedule = .daily(at: [minutes])
        }

        var updated = med ?? Medication(name: name, dosage: dosage, form: form, quantityRemaining: quantity)
        updated.name = name
        updated.dosage = dosage
        updated.ndc = ndc.isEmpty ? nil : ndc
        updated.form = form
        updated.quantityRemaining = quantity
        updated.expirationDate = hasExpiry ? expiration : nil
        updated.schedule = schedule

        if med == nil { store.add(updated) } else { store.update(updated) }
        dismiss()
    }
}
