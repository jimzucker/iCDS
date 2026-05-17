# Play Store submission — iCDS (Android, Flutter port)

Copy-paste source for the Google Play Console listing. Excluded from
the Pages site via `_config.yml`.

Build to upload: `flutter/example/build/app/outputs/bundle/release/app-release.aab`
- applicationId: `com.jimzucker.iCDS`
- versionName: 3.1.0
- versionCode: 7 (currently in Internal testing; bump on each subsequent Play upload)
- Upload key SHA-1: `3C:52:AB:CA:13:49:62:9B:87:7B:97:00:01:84:1C:C0:83:BB:32:B5`

---

## App name (max 30 chars)
iCDS

## Short description (max 80 chars)
ISDA SNAC pricing calculator for finance students and professionals.

## Full description (max 4000 chars)

iCDS is an educational and reference calculator for the ISDA SNAC
(Standard North American CDS) pricing model.

The pricing engine is the ISDA CDS Standard Model — the same open
C library published at www.cdsmodel.com — compiled directly into
the app and called via Dart FFI. Computed values match the
reference grids published by ISDA within 2.5 × 10⁻⁵ across six
currencies (USD, EUR, GBP, JPY, AUD, CHF).

What the app does:

• Computes an upfront fee from a flat par spread, or back-solves a
  par spread from an upfront, for any of the major regional contract
  conventions (NA, EU, EM, Asia, Japan, AUS, LCDS).
• Shows the impact of valuation date, tenor, recovery, and notional
  in real time as you change inputs — useful for teaching how the
  model responds to each parameter.
• Displays the live overnight reference rate (SOFR / €STR / SONIA /
  TONA / RBA cash rate) used for discounting, fetched as public data
  from each region's central bank or rate publisher.
• Provides Apache 2.0 / disclaimer / methodology references on the
  Info tab.

What the app is NOT: iCDS is a calculation tool only. It is not a
brokerage, exchange, or trading platform. It does not have an
account system, does not move money, does not execute orders, does
not provide individualized recommendations, and does not store any
user data. All numbers shown are indicative and intended for
educational and reference purposes; see the in-app disclaimer for
the full text.

iCDS has been on iOS since 2019 under the same name. This Android
edition was built with Flutter to maintain exact numerical parity
with the iOS build.

Source code: https://github.com/jimzucker/iCDS
Privacy: https://jimzucker.github.io/iCDS/PRIVACY

---

## Category
Tools

(Was Finance — but Google Play's August-2024 organization-account
rule heavily weights the Finance category as a trigger for the
"financial services require an organization account" check, even
for calculators. Tools is accurate for a reference / computation
app and is what comparable Apple-side apps such as PCalc and
Soulver use. Productivity is a fine alternative.)

## Tags (optional, max 5)
Calculator, Reference, Tools

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

This is the field most likely to have triggered the
organization-account requirement. The TOP-LEVEL answer must be:

  **"No, my app does not contain any of these financial features."**

Do not tick anything underneath. In particular do not tick
"Investments" — Google's classifier maps any sub-tick under
Investments (Stock trading, Cryptocurrency, Investment funds,
Tokenized digital assets) onto the org-only policy bucket, even
though iCDS does none of those things.

Justification (paste in the explanation box if Play asks): "iCDS
is an educational reference calculator for ISDA SNAC pricing
mathematics. It does not facilitate, recommend, broker, or custody
any financial product. There is no order entry, account system,
or interaction with any market venue. The app reads public
reference rates from central banks for display purposes only."

## Health
No.

## Privacy policy URL
https://jimzucker.github.io/iCDS/PRIVACY

---

## Release notes for the first internal-testing release (max 500 chars per language)
Initial Android release of iCDS — Credit Default Swap upfront fee
calculator on the ISDA Standard CDS Model. Bit-identical numerical
parity with the iOS app across USD/EUR/GBP/JPY/CHF/AUD. Four tabs:
Calc (par/upfront, default-risk chart, CS01/IRDV01/Rec01), Curves
(live overnight RFR strip), Info (disclaimers + Apache 2.0), Diag
(deterministic self-tests). Six SNAC regions with modern post-Big-Bang
T+1 settlement and ISDA-aligned recoveries. Educational reference
only.

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
