/// Integration-test parity port of `icdsTests.swift`'s pricing-property
/// section. Runs on iOS simulator / Android emulator — the FFI native
/// library is loaded by the plugin at startup.
///
/// Run on iOS:    `flutter test integration_test -d "iPhone 17 Pro"`
/// Run on Android: `flutter test integration_test -d emulator-5554`

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:icds_spike/cds_calculator.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Fixed reference date matching iOS suite: 2024-04-15 (Mon).
  final refDate = DateTime(2024, 4, 15);

  CdsResult? calc({
    required double parSpread,
    required double coupon,
    double recovery = 0.40,
    double notional = 10_000_000,
    int tenor = 5,
    bool isBuy = true,
    double? discount,
  }) {
    return CdsCalculator.calculate(
      tradeDate: refDate,
      tenorYears: tenor,
      parSpreadBp: parSpread,
      couponBp: coupon,
      recoveryRate: recovery,
      notional: notional,
      isBuy: isBuy,
      discountRate: discount ?? 0.045,
    );
  }

  group('Pricing — core financial properties', () {
    test('returns a result', () {
      expect(calc(parSpread: 100, coupon: 100), isNotNull);
    });

    test('at-par spread → upfront fraction is exactly zero', () {
      final r = calc(parSpread: 100, coupon: 100)!;
      expect(r.upfrontFraction.abs(), lessThan(1e-5));
      expect(r.upfrontDollars.abs(), lessThan(1.0));
    });

    test('spread above coupon → buyer pays', () {
      final r = calc(parSpread: 300, coupon: 100)!;
      expect(r.upfrontFraction, greaterThan(0));
      expect(r.upfrontDollars, greaterThan(0));
    });

    test('spread below coupon → buyer receives', () {
      final r = calc(parSpread: 50, coupon: 100)!;
      expect(r.upfrontFraction, lessThan(0));
      expect(r.upfrontDollars, lessThan(0));
    });

    test('sell is the opposite of buy', () {
      final buy  = calc(parSpread: 200, coupon: 100, isBuy: true)!;
      final sell = calc(parSpread: 200, coupon: 100, isBuy: false)!;
      expect((buy.upfrontDollars + sell.upfrontDollars).abs(), lessThan(1.0));
    });

    test('upfront increases monotonically with spread', () {
      double prev = -double.infinity;
      for (final s in [50.0, 100.0, 200.0, 300.0, 500.0]) {
        final r = calc(parSpread: s, coupon: 100)!;
        expect(r.upfrontDollars, greaterThan(prev));
        prev = r.upfrontDollars;
      }
    });

    test('longer tenor → larger absolute upfront for above-coupon spread', () {
      final r1 = calc(parSpread: 300, coupon: 100, tenor: 1)!;
      final r5 = calc(parSpread: 300, coupon: 100, tenor: 5)!;
      expect(r5.upfrontDollars, greaterThan(r1.upfrontDollars));
    });

    test('higher recovery → lower upfront for above-coupon spread', () {
      final lo = calc(parSpread: 300, coupon: 100, recovery: 0.20)!;
      final hi = calc(parSpread: 300, coupon: 100, recovery: 0.60)!;
      expect(lo.upfrontDollars, greaterThan(hi.upfrontDollars));
    });

    test('price = (1 - upfront fraction) × 100', () {
      final r = calc(parSpread: 200, coupon: 100)!;
      expect((r.price - (1.0 - r.upfrontFraction) * 100.0).abs(), lessThan(1e-4));
    });

    test('upfront scales linearly with notional', () {
      final r1 = calc(parSpread: 200, coupon: 100, notional: 5_000_000)!;
      final r2 = calc(parSpread: 200, coupon: 100, notional: 10_000_000)!;
      expect((r2.upfrontDollars - r1.upfrontDollars * 2.0).abs(), lessThan(1.0));
    });

    test('par spread round-trip recovers the input spread', () {
      final r = calc(parSpread: 150, coupon: 100)!;
      expect((r.parSpreadBp - 150.0).abs(), lessThan(1.0));
    });

    test('all SNAC tenors (1Y/5Y/7Y/10Y) succeed', () {
      for (final t in [1, 5, 7, 10]) {
        expect(calc(parSpread: 200, coupon: 100, tenor: t), isNotNull,
            reason: '${t}Y tenor');
      }
    });
  });

  group('Pricing — 500bp coupon (NA distressed)', () {
    test('at-par 500bp → upfront fraction zero', () {
      final r = calc(parSpread: 500, coupon: 500)!;
      expect(r.upfrontFraction.abs(), lessThan(1e-5));
      expect(r.upfrontDollars.abs(), lessThan(1.0));
    });

    test('spread above 500bp coupon → buyer pays', () {
      final r = calc(parSpread: 1000, coupon: 500)!;
      expect(r.upfrontFraction, greaterThan(0));
    });

    test('spread below 500bp coupon → buyer receives', () {
      final r = calc(parSpread: 100, coupon: 500)!;
      expect(r.upfrontFraction, lessThan(0));
    });

    test('buy/sell symmetry at 500bp coupon', () {
      final buy  = calc(parSpread: 800, coupon: 500, isBuy: true)!;
      final sell = calc(parSpread: 800, coupon: 500, isBuy: false)!;
      expect((buy.upfrontDollars + sell.upfrontDollars).abs(), lessThan(1.0));
    });

    test('coupon level affects upfront for fixed par spread', () {
      // 100bp coupon → buyer pays at 300bp spread; 500bp coupon → buyer receives.
      final r100 = calc(parSpread: 300, coupon: 100)!;
      final r500 = calc(parSpread: 300, coupon: 500)!;
      expect(r100.upfrontFraction, greaterThan(r500.upfrontFraction));
    });

    test('par spread round-trip for 500bp coupon', () {
      final r = calc(parSpread: 600, coupon: 500)!;
      expect((r.parSpreadBp - 600.0).abs(), lessThan(1.0));
    });
  });

  group('Pricing — 10000bp ceiling', () {
    test('produces a positive upfront', () {
      final r = calc(parSpread: 10000, coupon: 100)!;
      expect(r.upfrontDollars, greaterThan(0));
    });

    test('upfront fraction bounded by loss-given-default', () {
      const recovery = 0.40;
      final r = calc(parSpread: 10000, coupon: 100, recovery: recovery)!;
      expect(r.upfrontFraction, lessThan((1 - recovery) + 0.05));
      expect(r.upfrontFraction, greaterThan(0.30));
    });

    test('par spread round-trip at 10000bp', () {
      final r = calc(parSpread: 10000, coupon: 100)!;
      expect((r.parSpreadBp - 10000.0).abs(), lessThan(1.0));
    });

    test('buy/sell symmetric at 10000bp', () {
      final buy  = calc(parSpread: 10000, coupon: 100, isBuy: true)!;
      final sell = calc(parSpread: 10000, coupon: 100, isBuy: false)!;
      expect((buy.upfrontDollars + sell.upfrontDollars).abs(), lessThan(1.0));
    });
  });

  group('Pricing — chip grid (default 100bp coupon)', () {
    test('every visible chip prices, signs match coupon-relative direction, par round-trips', () {
      const coupon = 100.0;
      // Mirror Swift FeeView's chips. -200/-100 hidden when coupon=100
      // (would clamp negative); -50 is the only visible negative.
      const chips = <(double, int, String)>[
        (50,    -1, 'Coupon -50'),
        (100,    0, 'At Par'),
        (150,    1, 'Coupon +50'),
        (200,    1, 'Coupon +100'),
        (300,    1, 'Coupon +200'),
        (600,    1, 'Coupon +500'),
        (1100,   1, 'Coupon +1000'),
        (2100,   1, 'Coupon +2000'),
        (5100,   1, 'Coupon +5000'),
        (10000,  1, 'Max 10000'),
      ];
      double prev = -double.infinity;
      for (final c in chips) {
        final bp = c.$1;
        final sign = c.$2;
        final label = c.$3;
        final r = calc(parSpread: bp, coupon: coupon)!;
        switch (sign) {
          case -1:
            expect(r.upfrontDollars, lessThan(-1.0), reason: label);
            break;
          case 0:
            expect(r.upfrontDollars.abs(), lessThan(1.0), reason: label);
            break;
          case 1:
            expect(r.upfrontDollars, greaterThan(1.0), reason: label);
            break;
        }
        expect((r.parSpreadBp - bp).abs(), lessThan(1.0), reason: '$label round-trip');
        expect(r.upfrontDollars, greaterThan(prev), reason: '$label monotonic');
        prev = r.upfrontDollars;
      }
    });

    test('500bp coupon: below-par chips are buyer-receives and monotonic', () {
      const coupon = 500.0;
      const chips = <(double, String)>[
        (300, 'Coupon -200'),
        (400, 'Coupon -100'),
        (450, 'Coupon -50'),
      ];
      double prev = -double.infinity;
      for (final c in chips) {
        final bp = c.$1;
        final label = c.$2;
        final r = calc(parSpread: bp, coupon: coupon)!;
        expect(r.upfrontDollars, lessThan(-1.0), reason: label);
        expect(r.upfrontDollars, greaterThan(prev), reason: '$label monotonic');
        prev = r.upfrontDollars;
        expect((r.parSpreadBp - bp).abs(), lessThan(1.0), reason: '$label round-trip');
      }
    });
  });

  group('Pricing — edges and accrued', () {
    test('very high spread (2000bp) produces a result', () {
      expect(calc(parSpread: 2000, coupon: 500), isNotNull);
    });

    test('near-zero spread (1bp) produces a result', () {
      expect(calc(parSpread: 1, coupon: 100), isNotNull);
    });

    test('accrued is non-negative', () {
      final r = calc(parSpread: 200, coupon: 100)!;
      expect(r.accruedDollars, greaterThanOrEqualTo(0));
    });

    test('accrued uses stepinDate (T+1 calendar) — pin at refDate=2024-04-15', () {
      // stepin = 2024-04-16, prevIMM = 2024-03-20, ACT = 27 days
      // accrued = $10M × 1% × 27/360 = $7,500
      final r = calc(parSpread: 100, coupon: 100)!;
      const expected = 10_000_000.0 * 0.01 * 27.0 / 360.0;
      expect((r.accruedDollars - expected).abs(), lessThan(0.01),
          reason: '27/360 days expected. Off-by-one if it equals \$7222.22 (=26 days)');
    });

    test('price stays in [50, 120] across spread sweep', () {
      for (final s in [50.0, 100.0, 200.0, 500.0, 1000.0]) {
        final r = calc(parSpread: s, coupon: 100)!;
        expect(r.price, greaterThan(50.0), reason: 'price low @ $s bp');
        expect(r.price, lessThan(120.0), reason: 'price high @ $s bp');
      }
    });
  });

  group('Pricing — discount rate effect', () {
    test('higher discount rate reduces upfront for above-coupon spread', () {
      final lo = calc(parSpread: 300, coupon: 100, discount: 0.02)!;
      final hi = calc(parSpread: 300, coupon: 100, discount: 0.08)!;
      expect(lo.upfrontDollars, greaterThan(hi.upfrontDollars));
    });

    test('at-par upfront stays zero regardless of discount rate', () {
      final lo = calc(parSpread: 100, coupon: 100, discount: 0.02)!;
      final hi = calc(parSpread: 100, coupon: 100, discount: 0.08)!;
      expect(lo.upfrontFraction.abs(), lessThan(1e-5));
      expect(hi.upfrontFraction.abs(), lessThan(1e-5));
    });

    test('discount rate impact significant at 10Y tenor', () {
      final lo = calc(parSpread: 200, coupon: 100, tenor: 10, discount: 0.01)!;
      final hi = calc(parSpread: 200, coupon: 100, tenor: 10, discount: 0.10)!;
      expect((lo.upfrontFraction - hi.upfrontFraction).abs(), greaterThan(0.01));
    });
  });

  group('Pricing — settle date with regional calendar', () {
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    test('CdsResult.valueDate skips Memorial Day on T+1 nyFed', () {
      // Trade Fri 2025-05-23, T+1 nyFed must skip Mon Memorial Day → Tue 5-27.
      final r = CdsCalculator.calculate(
        tradeDate: DateTime(2025, 5, 23),
        tenorYears: 5,
        parSpreadBp: 100, couponBp: 100,
        recoveryRate: 0.40, notional: 10_000_000, isBuy: true,
      )!;
      expect(iso(r.valueDate), '2025-05-27');
    });

    test('CdsResult.valueDate skips TARGET Easter cluster', () {
      final r = CdsCalculator.calculate(
        tradeDate: DateTime(2025, 4, 17),
        tenorYears: 5,
        parSpreadBp: 100, couponBp: 100,
        recoveryRate: 0.40, notional: 10_000_000, isBuy: true,
        region: CdsRegion.target,
      )!;
      expect(iso(r.valueDate), '2025-04-22');
    });
  });
}
