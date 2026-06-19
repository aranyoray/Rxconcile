# App Store submission checklist

## Listing copy (draft)

**Name:** Rxconcile — Meds, Reminders & Safe Disposal

**Subtitle:** Track meds, never miss a dose, donate or dispose safely.

**Promotional text:**
Your private medication companion. Track what you take, get reminders that
actually reach you, and find out whether leftover medication can go to a
licensed donation program or should be safely disposed.

**Description:**
Rxconcile helps you manage your medications and handle leftovers responsibly.

• Offline medication list — your data stays on your device.
• Smart reminders — break through Focus, hear doses read aloud in your language.
• Label scanning — point your camera at a label to fill in the details.
• Leftover triage — get a clear answer: donation review, ask a pharmacist, or
  authorized disposal. Rxconcile checks for controlled substances, expiration,
  packaging, and your state's rules.
• Clinic reconciliation — show a QR code of your med list at a clinic or ER.

Rxconcile never enables person-to-person drug transfers. It points you toward
licensed repositories (like SIRUM) and authorized DEA take-back locations.
Final donation eligibility is always confirmed by a licensed pharmacist.

**Keywords:** medication,reminder,pill,adherence,donate,dispose,pharmacy,health,NDC,refill

**Support URL / Privacy Policy URL:** _add before submission_

## Required before submitting

- [ ] Set `DEVELOPMENT_TEAM` in `project.yml` (or signing in Xcode).
- [ ] Provide a hosted **Privacy Policy URL** (App Store requires one for health apps).
- [ ] App Privacy questionnaire in App Store Connect: **No data collected** (matches
      `PrivacyInfo.xcprivacy`).
- [ ] Screenshots: 6.7" and 6.1" iPhone (required sizes).
- [ ] Health-app review note: explain that Rxconcile gives informational guidance,
      does not transfer medication between users, and defers to licensed pharmacists.
- [ ] Confirm `ITSAppUsesNonExemptEncryption` = false is accurate (no custom crypto).
- [ ] Only enable the Critical Alerts entitlement **after** Apple approves the request
      (see `Rxconcile.entitlements`). Otherwise leave disabled.
- [ ] Replace seed datasets in `ControlledSubstanceChecker` and `StateRulesEngine`
      with maintained, authoritative data before relying on triage output.

## Build & archive

```bash
brew install xcodegen
xcodegen generate
# Open in Xcode, select "Any iOS Device", Product > Archive, then distribute.
```

## Test

```bash
xcodegen generate
xcodebuild test -scheme Rxconcile -destination 'platform=iOS Simulator,name=iPhone 15'
```
