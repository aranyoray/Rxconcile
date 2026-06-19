import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("stateCode") private var stateCode = "TX"
    private let reminders = ReminderService()

    private let states = ["TX", "OH", "CA", "IA", "NY", "FL", "WA"]

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                page(icon: "pills.fill",
                     title: "Track your medications",
                     body: "Keep an offline list of what you take. Your data stays on this device — nothing is uploaded.")
                page(icon: "bell.badge.fill",
                     title: "Never miss a dose",
                     body: "Set reminders that can break through Focus and even read your dose aloud in your language.")
                page(icon: "arrow.triangle.branch",
                     title: "Triage leftovers safely",
                     body: "Rxconcile routes leftover medication to licensed donation review or authorized disposal. It never enables person-to-person transfers.")
                finalPage
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    private func page(icon: String, title: String, body: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(Color.accentColor)
            Text(title).font(.title).bold().multilineTextAlignment(.center)
            Text(body).font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .padding()
    }

    private var finalPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72)).foregroundStyle(Color.accentColor)
            Text("Let's set you up").font(.title).bold()
            Picker("My state", selection: $stateCode) {
                ForEach(states, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            Text("Donation rules vary by state — we use this to triage correctly.")
                .font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
            Button {
                Task {
                    await reminders.requestAuthorization()
                    hasOnboarded = true
                }
            } label: {
                Text("Get started").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            Spacer()
        }
        .padding()
    }
}
