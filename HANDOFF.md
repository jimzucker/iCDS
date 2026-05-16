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

No pricing-engine change — `calculate(tenorYears:)` already rolls any integer year to the next IMM date.

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

- **Full v12 layout NOT built** — no CS01/IR-DV01/Rec01 metrics, no "BUYER PAYS"/period-line restructure. Those need risk calcs that don't exist on `CDSResult`; out of agreed scope. Decide if you want this next.
- **Legacy `FeeViewController.swift`** intentionally left on the old 4-tenor list — it's dead code (`@main → ContentView → FeeView`) and its storyboard control only has 4 segments.
- No PR opened (per instructions). Open one when the local builds pass.

## Suggested next steps

1. Build/test both apps locally (commands above); fix any compile nits.
2. Eyeball the chart on a simulator/emulator (tap a bar → maturity + outputs update).
3. Decide on the full-v12-layout question.
4. Open the PR.
