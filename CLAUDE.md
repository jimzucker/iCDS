# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

iCDS is a CDS (Credit Default Swap) upfront fee calculator implementing the SNAC (Standard North American CDS) model. It uses the **ISDA CDS Standard Model** C library (www.cdsmodel.com) compiled directly into the app. The app has three tabs: **Fee** (main calculator), **Libor** (SOFR reference curve), and **Info** (about screen).

This repository contains **two parallel implementations** of the same product:

- **`icds/` + `icds.xcodeproj/`** — the shipped iOS Swift / SwiftUI app (3.0.1 in App Store). Use Xcode to build and run.
- **`flutter/`** — a Flutter / Dart-FFI port that runs on iOS arm64 + Android arm64 with bit-identical numerical results. Self-contained subdirectory; see `flutter/README.md` for build instructions. 103 Dart tests at parity with the Swift suite (32 pure-Dart + 71 integration); reference grids match ISDA's published values within 2.5e-5 across 6 currencies.

When the user asks about "the iOS app" or "the App Store build" they mean the Swift one at the root. When they ask about "the Flutter version" or "Android" they mean the port at `flutter/`. The two are independent — touching one doesn't affect the other.

## Building and testing

This is an Xcode project — there is no CLI build script. Open `icds.xcodeproj` in Xcode.

- **Build**: ⌘B
- **Run on simulator**: ⌘R (requires iOS 16+ simulator)
- **Run all tests**: ⌘U (runs both `icdsTests` and `icdsUITests`)
- **Run unit tests only**: In Test Navigator (⌘6), run the `icdsTests` target
- **Run a single test**: Click the diamond next to any test method in the editor gutter

Deployment target is **iOS 16.0**. The app is locked to dark mode via `SceneDelegate`.

## Architecture

### Swift layer
- **`CDSCalculator.swift`** — the core calculation struct. All CDS math lives here. `FeeViewController.reCalc()` delegates to `CDSCalculator.calculate()`. This is the right place to fix or extend pricing logic.
- **`FeeViewController.swift`** — main tab; reads UI controls, calls `CDSCalculator`, formats and displays results. Several IBOutlets are **not wired in the storyboard** (`TradeDateStepper`, `AccruedIntField`, `SettleDateField`) — access these with `?.` optional chaining.
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
lives at `/tmp/icds_final_mock_v1..v9.html` — static HTML phone frames (393pt iPhone
width). No HTML renderer is available in this environment, so mocks are delivered as
`.html` and opened directly in a browser. **v9 is current.**

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

Open decision (NOT yet wired into `FeeView.swift`):
- **Variant A (recommended):** Maturity as a compact dropdown paired on one row with
  Coupon; Notional editable field promoted to top. Scales to any tenor count, saves a row.
- **Variant B:** keep the full-width segmented bar, extended to 7 segments (~52pt each —
  above the 44pt tap minimum but labels tight, still a dedicated row).
- A half-width 7-segment bar (~25pt) fails the 44pt tap minimum — this is why a paired
  layout requires the dropdown, not a bar.

## App Store requirements satisfied
- `arm64` in `UIRequiredDeviceCapabilities`
- `PrivacyInfo.xcprivacy` present (no data collected)
- Deployment target iOS 16.0
- `@main` entry point, `SceneDelegate` for UIScene lifecycle
- App icon: all sizes in `Assets.xcassets/AppIcon.appiconset/`, generated from `images/newpng.png`
