# Handoff — v12 (7 SNAC tenors · Fee→Calc · default-risk chart)

**Branch:** `claude/upfront-interest-accrual-JWv90` (repo `jimzucker/iCDS`)
**Head:** `691451f` — pushed. `jimzucker/iinteract` was **not** touched.

Pick up:
```
git fetch origin
git checkout claude/upfront-interest-accrual-JWv90
git pull
```

## What's done (both apps, kept at parity)

| Change | Swift (`icds/`) | Flutter (`flutter/`) |
|---|---|---|
| Tenor grid → `1/2/3/4/5/7/10Y`, 5Y default (index 1→4) | `FeeViewModel.swift` | `lib/fee_view_model.dart` |
| `Fee` tab → **`Calc`** | `ContentView.swift` | `example/lib/main.dart` |
| `cumulativeDefaultProb` (flat-hazard `1−e^(−λT)`, `λ=(spreadBp/1e4)/(1−R)`) | `CDSCalculator.swift` | `lib/cds_calculator.dart` |
| Default-Risk-by-Maturity bar chart (7 bars, tap-to-select) | `FeeView.swift` (`defaultRiskChart`) | `example/lib/fee_tab.dart` (`_defaultRiskChart`) |
| Trimmed copy (`· tap`, `· tap to pick`) | `FeeView.swift` | `example/lib/fee_tab.dart` |
| **Risk metrics** CS01 / IR DV01 / Rec01 (bump-and-reprice) + period line | `CDSCalculator.riskMetrics`, `FeeView.riskRow`/`periodRow` | `CdsCalculator.riskMetrics`, `fee_tab._riskRow`/`_periodRow` |
| **Dead-code cleanup** — deleted legacy UIKit `FeeViewController`/`LiborViewController`/`InfoViewController` + unused `Main.storyboard`; `project.pbxproj` hand-pruned | yes | n/a (Flutter had no equivalent) |

No pricing-engine change — `calculate(tenorYears:)` already rolls any integer year to the next IMM date. App is SwiftUI-lifecycle (`@main iCDSApp → ContentView`); the deleted controllers/storyboard were unreferenced.

**⚠️ `project.pbxproj` was edited by hand (no Xcode here).** First thing on the laptop: open `icds.xcodeproj` and confirm it loads + builds before anything else. Main.storyboard was not in any build phase, so removal should be clean, but verify.

Locked design reference (open in a browser): `docs/mocks/fee_v12_locked_design.html`.

## NOT verified — must build on your laptop

This was done on a host with **no Xcode and no Flutter/Dart SDK**, so nothing was compiled or run.

- **iOS:** open `icds.xcodeproj`, ⌘B then ⌘U (runs `icdsTests` + `icdsUITests`).
- **Flutter pure-Dart** (no device):
  ```
  cd flutter
  flutter test test/default_risk_test.dart
  flutter test test/imm_test.dart
  ```
- **Flutter integration** (needs sim/emulator, loads FFI):
  ```
  cd flutter/example
  flutter test integration_test -d "iPhone 17 Pro"      # or: -d emulator-5554
  ```

During self-review I fixed two Dart return-type issues (`.clamp()` returns `num`, not `double`) in `cds_calculator.dart` and `fee_tab.dart` — worth a glance if Dart analyze flags anything.

## New / changed tests

- `icdsTests/icdsTests.swift` — unhardcoded `[1,5,7,10]`; added: new-tenor IMM-roll, upfront monotonicity across the ladder, 5Y-default guard (`@MainActor`), closed-form `cumulativeDefaultProb` + properties.
- `flutter/test/default_risk_test.dart` — **new** pure-Dart parity for `cumulativeDefaultProb` (same closed-form expected values as Swift).
- `flutter/example/integration_test/cds_calculator_test.dart` — full-grid succeed, new-tenor IMM-roll, monotonicity.
- `flutter/example/integration_test/fee_view_model_test.dart` — SNAC-grid + 5Y-default guard.

Closed-form check values (λ=0.025 at 150bp/40%): 1Y 0.024690 · 2Y 0.048771 · 5Y 0.117503 · 10Y 0.221199.

## Scope boundaries / open items

- **Full v12 layout — now built.** CS01 / IR DV01 / Rec01 are computed by
  bump-and-reprice (forward diffs) in `CDSCalculator.riskMetrics` /
  `CdsCalculator.riskMetrics`; period line added. The "BUYER PAYS" card already
  existed via `directionalLabel`. Risk numbers are bump-derived, not analytic Greeks
  (consistent with the app's flat-curve simplification) — sanity-check magnitudes on
  device.
- **Legacy dead code removed** (see warning above re: pbxproj).
- No PR opened (per instructions). Open one when the local builds pass.

## Suggested next steps

1. **Open `icds.xcodeproj` in Xcode — confirm it loads and builds** (pbxproj was
   hand-edited). Then ⌘U.
2. `cd flutter && flutter test test/default_risk_test.dart test/imm_test.dart`;
   then `cd example && flutter test integration_test -d <device>`.
3. Eyeball on a sim/emulator: tap a chart bar → maturity + outputs update; check the
   RISK row signs (CS01 > 0 for a buyer above coupon, Rec01 < 0) and the period line.
4. Open the PR.
