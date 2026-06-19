# Rxconcile

An iOS app that helps people manage leftover and active medications: an **offline
medication list**, **adherence reminders** (escalating, on-device), **QR
reconciliation** for clinics/ERs, and a **triage engine** that safely routes
leftover medication toward *licensed donation review* or *authorized disposal*.

> **Positioning / legal framing.** Rxconcile never enables peer-to-peer drug
> transfer. It is a consumer-facing "front door": it helps a person decide whether
> to dispose, ask a pharmacist, or contact a licensed repository (e.g. SIRUM).
> Final donation eligibility is always confirmed by a licensed pharmacist or
> repository. Donation law varies by US state, so the triage engine is
> state-aware and conservative by default.

## Architecture

```
Sources/Rxconcile/
  App/         App entry, root tab view, global app state
  Models/      Medication, ReminderSchedule, TriageResult
  Store/       MedicationStore — on-device JSON persistence (no cloud, no PHI upload)
  Services/    TriageEngine, ControlledSubstanceChecker, StateRulesEngine,
               ReminderService, SpeechService, VoiceCommandService, ReconciliationService
  Features/    Medications, Reminders, Triage, Reconcile, Settings (SwiftUI views)
  Resources/   Info.plist
```

### Core pillars

| Pillar | Where |
|--------|-------|
| Offline medication list | `Store/MedicationStore.swift` |
| Adherence reminders (escalation ladder) | `Services/ReminderService.swift` |
| Leftover triage → donate review / dispose | `Services/TriageEngine.swift` |
| DEA controlled-substance gating | `Services/ControlledSubstanceChecker.swift` |
| State-by-state donation rules | `Services/StateRulesEngine.swift` |
| QR reconciliation for clinic/ER | `Services/ReconciliationService.swift` + `Features/Reconcile` |
| Voice commands + spoken reminders (multi-language, on-device) | `Services/VoiceCommandService.swift`, `Services/SpeechService.swift` |

## Reminder escalation ladder (all free / on-device)

`ReminderStyle` layers increasingly insistent, **no-telephony-cost** mechanisms:

1. **Standard** — banner + sound.
2. **Time-Sensitive** — breaks through Focus / scheduled summary.
3. **Critical alert** — overrides the silent switch and Do Not Disturb. Requires
   the *Critical Alerts* entitlement from Apple (free, but request-gated).
4. **Call-style** — a ringtone-style, full-attention reminder. Can be paired with
   CallKit to present an incoming-call-like screen on-device (free) — note Apple
   restricts CallKit to genuine VoIP, so a respectful full-screen reminder is the
   compliant version of "call your own phone".
5. **Spoken aloud** — `AVSpeechSynthesizer` reads the dose in the user's language.

> Actually placing a real phone *call* requires a telephony provider (Twilio etc.)
> and is not free. The ladder above achieves the same "hard to ignore" goal using
> only on-device APIs.

## Building

This repo keeps **sources only**; the Xcode project is generated so the
`.pbxproj` doesn't churn in git.

```bash
brew install xcodegen        # one-time
xcodegen generate            # produces Rxconcile.xcodeproj
open Rxconcile.xcodeproj      # build & run on iOS 17+ simulator/device
```

Set your signing team in Xcode (or `project.yml` `DEVELOPMENT_TEAM`) before
running on a device. Voice, critical alerts, and CallKit features require a real
device and the relevant entitlements.

## Privacy

- Medication data is stored only in on-device Application Support JSON with file
  protection; nothing is uploaded.
- Voice recognition uses `requiresOnDeviceRecognition` where supported.
- Label OCR (planned) extracts text and discards the image — no PHI retained.

## Status

MVP scaffold: medication CRUD, reminders, triage engine, QR reconciliation,
voice/TTS, settings. Not yet implemented: live NDC/DEA dataset integration,
VisionKit label OCR capture, CallKit incoming-call presentation, the donor
transfer PDF generator, and full per-state rule data. These are wired as clear
extension points.
