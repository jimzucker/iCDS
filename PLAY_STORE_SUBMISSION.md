# Play Store submission — iCDS (Android, Flutter port)

Copy-paste source for the Google Play Console listing. Excluded from
the Pages site via `_config.yml`.

Build to upload: `flutter/example/build/app/outputs/bundle/release/app-release.aab`
- applicationId: `com.jimzucker.icds`
- versionName: 3.0.1
- versionCode: 1 (defaulted from flutter; bump on each upload)
- Upload key SHA-1: `3C:52:AB:CA:13:49:62:9B:87:7B:97:00:01:84:1C:C0:83:BB:32:B5`

---

## App name (max 30 chars)
iCDS

## Short description (max 80 chars)
ISDA SNAC CDS upfront pricing calculator. Bit-identical to QuantLib.

## Full description (max 4000 chars)

iCDS is a Credit Default Swap (CDS) upfront fee calculator implementing
the SNAC (Standard North American CDS) model.

The pricing engine is the ISDA CDS Standard Model — the same C library
that lives at www.cdsmodel.com — compiled directly into the app and
called via Dart FFI. Reference test grids match ISDA's published values
within 2.5 × 10⁻⁵ across six currencies (USD, EUR, GBP, JPY, AUD, CHF).

What you can do with it:

• Price an upfront fee from a flat par spread, or back-solve par spread
  from an upfront, for any of the major regional contracts (NA, EU, EM,
  Asia, Japan, AUS, LCDS).
• See the impact of trade date, tenor, recovery, and notional in real
  time as you change inputs.
• View the live SOFR / €STR / SONIA / TONA / RBA cash rate curve used
  for discounting (fetched from each region's central bank or
  reference-rate publisher).
• Read the Apache 2.0 / disclaimer / methodology references on the Info
  tab.

iCDS is a calculation tool. It does not place trades, route orders,
recommend any security, give investment advice, or store any user
data. Numbers are indicative and for educational purposes only — see
the in-app disclaimer for the full text.

iCDS has been on iOS since 2019 and uses the same pricing engine as
the iOS app. This Android version was built with Flutter to maintain
exact numerical parity with the iOS build.

Source code: https://github.com/jimzucker/iCDS
Privacy: https://jimzucker.github.io/iCDS/PRIVACY

---

## Category
Finance

## Tags (optional, max 5)
Finance, Tools

## Contact details
- Email: jamesazucker@gmail.com
- Website: https://jimzucker.github.io/iCDS
- Phone: (omit)

## External marketing
Off — Play should not advertise outside Play.

---

## App access (questionnaire answer)
"All functionality in my app is available without any access
restrictions." (No login, no gating.)

## Ads
"No, my app does not contain ads."

## Content rating questionnaire
- Violence: None
- Sexual content: None
- Profanity: None
- Controlled substances: None
- Gambling: None — clarify in note: "App computes hypothetical CDS
  pricing for educational/professional reference. Does not facilitate
  trading or any real-money transaction."
- User-generated content: None
- Location sharing: None
- Personal info: None
Expected rating: Everyone / 3+ / PEGI 3.

## Target audience
18 and over (single age group). Avoids COPPA / Families policy.

## News app
No.

## COVID-19 contact tracing
No.

## Data safety form
- Does your app collect or share any of the required user data types?
  No.
- Is all of the user data collected by your app encrypted in transit?
  Yes — but no user data is collected.
- Do you provide a way for users to request that their data be deleted?
  N/A — no user data is collected.
- Functional network use: declare under "App functionality":
  "App fetches public reference rates (SOFR, €STR, SONIA, TONA, RBA
  cash rate) from each currency's central bank or reference-rate
  publisher to display the discount curve. No user data is sent;
  these are pure HTTPS GETs of publicly published rate values."

## Government apps
No.

## Financial features (most-asked-about question)
Tick: **None of these features are in my app.**

Justification (paste in the explanation box if Play asks): "iCDS is an
informational calculator for Credit Default Swap upfront fees using
the ISDA SNAC model. It does not facilitate, recommend, broker, or
custody any financial product. Users cannot place trades, transfer
money, or interact with any market venue. The app reads public
reference rates from central banks for display purposes only."

## Health
No.

## Privacy policy URL
https://jimzucker.github.io/iCDS/PRIVACY

---

## Release notes for the first internal-testing release (max 500 chars per language)
Initial Android release. Feature parity with the iOS build, including
bit-identical pricing across USD, EUR, GBP, JPY, AUD and CHF. Live
discount-rate fetch from each region's reference-rate publisher.
Includes Curves and Info tabs.

---

## Asset checklist (must be ready before publishing to Production track)
- [ ] App icon: 512×512 PNG  (regenerate from images/newpng.png)
- [ ] Feature graphic: 1024×500 PNG  (banner; create in Pixelmator/Figma)
- [ ] Phone screenshots: 2–8, min 1080px on long edge  (Pixel 9 emulator)
- [ ] Tablet screenshots: optional but recommended for finance apps
- [ ] Promo video (YouTube link): optional, skip for v1

## First-upload checklist
- [ ] Verify upload cert SHA-1 matches `3C:52:AB:CA:...:32:B5`
- [ ] App Bundle Explorer shows `arm64-v8a` and `armeabi-v7a` ABIs each
      containing `libicds_spike.so` and `libflutter.so`
- [ ] Pre-launch report runs clean (no critical issues)
- [ ] Internal testing track active with at least one real-device tester
