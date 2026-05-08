# CDSReferenceTests parity — DONE

The reference grid suite from `iCDS/icdsTests/CDSReferenceTests.swift`
has been ported to Dart.

Live test file: `example/integration_test/cds_reference_test.dart`.

Cases ported:
- **QuantLib testIsdaEngine** (May 21 2009 USD curve) — 9 cases:
  1Y/2Y/5Y/10Y × spread 10bp/1000bp × recovery 40%/20%
- **ISDA Official RFR Test Grids** (2021-04-26) — 144 cases:
  USD (SOFR), EUR (€STR), GBP (SONIA), JPY (TONA), CHF (SARON), AUD (AONIA)
  × 6 maturities × 4 spreads × coupon=100bp × R=40%

C-side wrapper added:
- `icds_spike_price_with_curve` — builds an IR zero curve via
  `JpmcdsBuildIRZeroCurve`, prices the CDS, runs the inverse
  `JpmcdsCdsoneSpread` for round-trip par. Takes deposits + swaps as
  flat C arrays plus per-leg DCC / frequency parameters and an
  `isPriceClean` flag (1 = clean / ISDA grid; 0 = dirty / QuantLib).

Tolerance achieved (max abs error vs ISDA reference):
- JPY 4.16e-7    — best fit
- GBP 2.75e-6
- AUD 6.88e-6
- EUR 6.73e-6
- CHF 8.82e-6
- USD 9.77e-6

All within the 2.5e-5 (= 0.25 bp = $250 on $10M) tolerance the Swift
suite uses.
