# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

iCDS is a CDS (Credit Default Swap) upfront fee calculator implementing the SNAC (Standard North American CDS) model. It uses the **ISDA CDS Standard Model** C library (www.cdsmodel.com) compiled directly into the app. The app has four tabs: **Calc** (main calculator — Fee tab in earlier versions), **Curves** (live overnight reference rates), **Info** (about screen), and **Diag** (in-app diagnostics: JpmcdsDate sanity, CDSCalculator par/wide/tight, IMM helpers, holiday calendars, RFR fetcher status).

This repository contains **two parallel implementations** of the same product:

- **`icds/` + `icds.xcodeproj/`** — the iOS Swift / SwiftUI app. 3.0.1 is in the App Store; 3.1.0 (build 6, v12 layout) is prepared but not yet submitted. Use Xcode to build and run.
- **`flutter/`** — a Flutter / Dart-FFI port that runs on iOS arm64 + Android arm64 with bit-identical numerical results. Self-contained subdirectory; see `flutter/README.md` for build instructions. 130+ Dart tests at parity with the Swift suite; reference grids match ISDA's published values within 2.5e-5 across 6 currencies. Android versionCode 7 is in Play Store Internal testing.

When the user asks about "the iOS app" or "the App Store build" they mean the Swift one at the root. When they ask about "the Flutter version" or "Android" they mean the port at `flutter/`. The two are independent — touching one doesn't affect the other.

## Building and testing

This is an Xcode project — there is no CLI build script. Open `icds.xcodeproj` in Xcode.

- **Build**: ⌘B
- **Run on simulator**: ⌘R (requires iOS 16+ simulator)
- **Run all tests**: ⌘U (runs both `icdsTests` and `icdsUITests`)
- **Run unit tests only**: In Test Navigator (⌘6), run the `icdsTests` target
- **Run a single test**: Click the diamond next to any test method in the editor gutter

Deployment target is **iOS 16.0**. The app is locked to dark mode via `SceneDelegate`.

**Claude Code on the web:** `.claude/hooks/session-start.sh` (async SessionStart
hook) installs Flutter stable so web sessions can run the **pure-Dart suite**
(`cd flutter && flutter test test/`) and `dart analyze`. iOS (Xcode) and Flutter
**integration** tests still require a Mac / device — not runnable on the web host.

## Architecture

### Swift layer
The app is **SwiftUI lifecycle**: `@main iCDSApp` → `ContentView` (TabView) →
`FeeView`/`LiborView`/`InfoView`. The legacy UIKit controllers
(`FeeViewController`, `LiborViewController`, `InfoViewController`) and the unused
`Base.lproj/Main.storyboard` were **deleted** (dead code; nothing referenced them,
`project.pbxproj` pruned accordingly). `LaunchScreen.storyboard` is kept.
- **`CDSCalculator.swift`** — core calculation struct; all CDS math (`calculate`,
  `cumulativeDefaultProb`, `riskMetrics`). `FeeViewModel.recalculate()` delegates here.
- **`FeeView.swift` / `FeeViewModel.swift`** — the live Calc tab (SwiftUI + Combine).
  `FeeView` is the screen; `FeeViewModel` holds inputs and derived `result`/`risk`.
- **`ISDAContract.swift` / `Recovery.swift`** — data models loaded from `contracts.plist` (7 regional contracts: NA, EU, EM, Asia, Japan, AUS, LCDS).

### C library bridge
The ISDA C library lives in `icds/isdamodel/src/` (48 `.c` files + `cfinanci.cpp`). All files are compiled directly as part of the `icds` target — they were added to the Xcode project via a bulk `project.pbxproj` edit. The bridging header is `icds/icds-Bridging-Header.h`.

**Key C functions used:**
- `JpmcdsCdsoneUpfrontCharge` — computes dirty upfront charge from a flat par spread
- `JpmcdsCdsoneSpread` — back-calculates par spread from an upfront charge
- `JpmcdsMakeTCurve` — builds a simple flat discount curve (app uses 4.5% continuous)
- `JpmcdsBuildIRZeroCurve` — builds a full IR zero curve from deposits + swaps (used in reference tests)
- `JpmcdsDate(year, month, day)` — converts calendar date to `TDate` (days since 1601)

C `char *` parameters (not `const char *`) cannot accept Swift string literals — use `strdup("...")` / `free()`. This applies to the `calendar` parameter in `JpmcdsCdsoneUpfrontCharge`.

### Pricing assumptions (app simplification)
- Discount curve: **flat 4.5% continuous** via `JpmcdsMakeTCurve` (second-order effect vs credit spread)
- Date conventions: T+1 settle, today as startDate (not the proper SNAC previous-IMM startDate)
- Payment interval: quarterly (`prd=3, prd_typ='M'`), front short stub
- Day count: `JPMCDS_ACT_360`, bad day convention: `JPMCDS_BAD_DAY_FOLLOW` (`'F'`)

### IMM dates
Standard CDS maturity dates are the **20th of March, June, September, December**. `CDSCalculator.nextIMMDate(after:)` and `prevIMMDate(before:)` implement this. `endDate` for a trade is the next IMM date after `tradeDate + tenorYears`.

## Tests

**`icdsTests/icdsTests.swift`** — 26 unit tests covering:
- `ISDAContract` plist loading (7 regions, recovery rates, sorting)
- IMM date boundary cases
- CDS financial properties: monotonicity, buy/sell symmetry, tenor/recovery/notional scaling, par spread round-trip

**`icdsTests/CDSReferenceTests.swift`** — 8 reference tests validated against QuantLib's `testIsdaEngine` (May 21, 2009 USD curve, 1Y/2Y/5Y/10Y maturities, spreads 10bp and 1000bp). These build a real IR curve via `JpmcdsBuildIRZeroCurve` and compare upfront fractions against QuantLib's published `markitValues[]` within 5% tolerance.

## Key project.pbxproj facts

The `.gitignore` now correctly tracks `project.pbxproj`. The C source files were added to the build via a Python script that bulk-inserted `PBXFileReference`, `PBXBuildFile`, and Sources build phase entries. `OTHER_CFLAGS = "-w"` suppresses C library warnings. `HEADER_SEARCH_PATHS` points to `isdamodel/include/isda`, `isdamodel/include`, and `isdamodel/src`.

## UI design — FeeView mock iteration

Active design work on the **Fee tab UI** (SwiftUI `icds/FeeView.swift`). Mock series
lives at `/tmp/icds_final_mock_v1..v12.html` — static HTML phone frames (393pt iPhone
width). No HTML renderer is available in this environment, so mocks are delivered as
`.html` and opened directly in a browser. **v12 is the chosen/locked design** — same
layout as v11 with helper micro-copy stripped (bare labels; affordances are icon-only
✎/📅; per-metric unit captions kept). **Implemented** — see "Status" below.

Decisions locked in v9:
- **SNAC tenor grid = 1Y · 2Y · 3Y · 4Y · 5Y · 7Y · 10Y.** All engine-supported:
  `CDSCalculator.calculate(tenorYears: Int)` accepts any integer year and rolls to the
  next IMM date. **6M is intentionally excluded** — would need a sub-year/fractional
  tenor signature change.
- **Notional is not a SNAC constraint** (any positive amount is valid) → it becomes a
  single **editable field**, not fixed 1M/5M/10M/20M buttons.
- **Coupon stays region-driven** (NA = 100/500 bp only; other running coupons such as
  25/300/750/1000 are not NA-SNAC — do not expand arbitrarily).
- Lower chart is **Default Risk by Maturity**: cumulative default prob per tenor under a
  flat-hazard approx, h = spread / (1 − recovery). At 150 bp, R = 40% ⇒ 1Y 2.5%,
  2Y 4.9%, 3Y 7.2%, 4Y 9.5%, 5Y 11.8%, 7Y 16.0%, 10Y 22.1%. Re-scales with spread.

**Decision (v11, locked — NOT yet wired into `FeeView.swift`):** Variant B chosen.
- **Maturity:** full-width segmented bar, extended to all 7 SNAC tenors
  (1/2/3/4/5/7/10Y, ~52pt per segment, `font-size:11px` to keep labels readable).
- **Coupon:** 2-segment selector (`100 | 500`, region-driven).
- **Notional:** reverted to a 4-segment selector (`1M / 5M / 10M / 20M`) per explicit
  user request — overrides the earlier "editable field" recommendation.
- Structurally identical to v8 plus 3 extra Maturity segments and 3 extra chart bars —
  no new rows, still fits one iPhone-16 screen with no scroll.
- Rejected alternative (for context): Variant A paired Maturity dropdown (`5Y ▾`) +
  Coupon selector + Notional editable field on top. A half-width 7-segment bar (~25pt)
  fails the 44pt tap minimum, which is why A used a dropdown; B keeps the bar full-width
  (~52pt) so it stays a segmented control.

### Status: IMPLEMENTED in both apps (branch `claude/upfront-interest-accrual-JWv90`)

Shipped, not just mocked — Swift (`icds/`) + Flutter (`flutter/`), kept at parity:
- **Tenor grid → `[1,2,3,4,5,7,10]`, 5Y default.** Swift `FeeViewModel.swift`
  (`maturityIndex` default index moved 1 → **4**); Flutter `fee_view_model.dart`
  (`_maturityIndex` 1 → 4). No engine change — `calculate(tenorYears:)` already rolls
  any integer year to the next IMM date.
- **Fee → Calc** tab label: Swift `ContentView.swift`; Flutter `main.dart` (icons were
  already calc-themed).
- **`CDSCalculator.cumulativeDefaultProb(spreadBp:recoveryRate:years:)`** — new pure
  closed-form `1 − e^(−λT)`, `λ = (spreadBp/1e4)/(1−R)`. Mirrored in Dart
  `CdsCalculator.cumulativeDefaultProb`. Drives the **Default-Risk-by-Maturity chart**
  (`FeeView.defaultRiskChart` / `FeeTab._defaultRiskChart`): 7 bars, selected tenor
  highlighted, tap-a-bar selects that maturity. Deliberately independent of the ISDA
  bootstrap (consistent with the app's flat-curve simplification).
- **Trimmed copy**: "QUOTED SPREAD · tap" → "QUOTED SPREAD"; "Trade Date · tap to
  pick" → "Trade Date" (both apps).
- **Full v12 layout (now built):** `CDSCalculator.riskMetrics` / `CdsCalculator.riskMetrics`
  — first-order CS01 / IR DV01 / Rec01 by bump-and-reprice (forward diffs: +1 bp spread,
  +1 bp discount, +1 pt recovery). Surfaced as `FeeView.riskRow` / `FeeTab._riskRow`
  plus a period line (`periodRow` / `_periodRow`, accrual start → maturity + length in
  years). VM exposes `var risk`/`get risk`.
- **Dead-code cleanup:** legacy UIKit `FeeViewController`/`LiborViewController`/
  `InfoViewController` + unused `Base.lproj/Main.storyboard` deleted; `project.pbxproj`
  hand-pruned (PBXBuildFile / PBXFileReference / PBXGroup / PBXSourcesBuildPhase /
  PBXVariantGroup). Main.storyboard was not in any build phase, so no build-input loss.
  ⚠️ pbxproj was edited without Xcode — **open the project in Xcode to confirm it loads
  and builds.**
- **Tests** (parity, both suites): fixed the hardcoded `[1,5,7,10]` loops; added
  new-tenor IMM-roll + upfront-monotonicity + 5Y-default-guard tests; closed-form
  `cumulativeDefaultProb` tests (Swift `icdsTests.swift`, pure-Dart
  `flutter/test/default_risk_test.dart`); risk-metrics property tests — signs,
  notional scaling, buy/sell symmetry (`icdsTests.swift` +
  `integration_test/cds_calculator_test.dart`).
  **Not run here** (no Xcode/Flutter toolchain on this host): verify with Xcode `⌘U`
  and `flutter test` / `flutter test integration_test`.

## App Store requirements satisfied
- `arm64` in `UIRequiredDeviceCapabilities`
- `PrivacyInfo.xcprivacy` present (no data collected)
- Deployment target iOS 16.0
- `@main` entry point, `SceneDelegate` for UIScene lifecycle
- App icon: all sizes in `Assets.xcassets/AppIcon.appiconset/`, generated from `images/newpng.png`
