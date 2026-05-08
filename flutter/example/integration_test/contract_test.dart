/// Integration-test parity port of `icdsTests.swift`'s ISDAContract /
/// plist-loading section. Uses rootBundle so it must run on a device
/// (sim/emulator).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:icds_spike/cds_calculator.dart';
import 'package:icds_spike/contract.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late List<ISDAContract> contracts;

  setUpAll(() async {
    contracts = await ISDAContract.loadFromAsset();
  });

  group('Contract loading', () {
    test('exactly 6 regional contracts', () {
      expect(contracts.length, 6);
    });

    test('all expected regions present', () {
      final regions = contracts.map((c) => c.region).toSet();
      for (final r in const ['NA', 'EU', 'EM', 'Asia', 'Japan', 'AUS']) {
        expect(regions.contains(r), isTrue, reason: 'missing region: $r');
      }
    });

    test('NA recovery list has SEN=40 and SUB=20', () {
      final na = contracts.firstWhere((c) => c.region == 'NA');
      expect(na.recoveryList.length, 2);
      final rates = na.recoveryList.map((r) => r.recovery).toSet();
      expect(rates.contains(40), isTrue);
      expect(rates.contains(20), isTrue);
    });

    test('NA coupons include 100 and 500', () {
      final na = contracts.firstWhere((c) => c.region == 'NA');
      expect(na.coupons.contains(100), isTrue);
      expect(na.coupons.contains(500), isTrue);
    });

    test('subordination keys sorted alphabetically (SEN, SUB)', () {
      final na = contracts.firstWhere((c) => c.region == 'NA');
      expect(na.recoveryList[0].subordination, 'SEN');
      expect(na.recoveryList[1].subordination, 'SUB');
    });

    test('Recovery model constructor', () {
      const r = Recovery('SEN', 40);
      expect(r.subordination, 'SEN');
      expect(r.recovery, 40);
    });

    test('EU contract has coupons', () {
      final eu = contracts.firstWhere((c) => c.region == 'EU');
      expect(eu.coupons, isNotEmpty);
    });

    test('EM contract has recovery list', () {
      final em = contracts.firstWhere((c) => c.region == 'EM');
      expect(em.recoveryList, isNotEmpty);
    });
  });

  group('Region × pricing', () {
    final refDate = DateTime(2024, 4, 15);

    test('every region × recovery produces a result', () {
      for (final c in contracts) {
        for (final rec in c.recoveryList) {
          final r = CdsCalculator.calculate(
            tradeDate: refDate, tenorYears: 5,
            parSpreadBp: 200,
            couponBp: c.coupons.first.toDouble(),
            recoveryRate: rec.recovery / 100.0,
            notional: 10_000_000, isBuy: true,
            region: c.calendar,
            settleDays: c.settleDays,
          );
          expect(r, isNotNull,
              reason: '${c.region}/${rec.subordination} should produce a result');
        }
      }
    });

    test('every region × coupon at-par → upfront fraction is exactly zero', () {
      for (final c in contracts) {
        final recovery = (c.recoveryList.firstOrNull?.recovery ?? 40) / 100.0;
        for (final coupon in c.coupons) {
          final r = CdsCalculator.calculate(
            tradeDate: refDate, tenorYears: 5,
            parSpreadBp: coupon.toDouble(),
            couponBp: coupon.toDouble(),
            recoveryRate: recovery,
            notional: 10_000_000, isBuy: true,
            region: c.calendar,
            settleDays: c.settleDays,
          );
          expect(r, isNotNull, reason: '${c.region} coupon=${coupon}bp at-par failed');
          expect(r!.upfrontFraction.abs(), lessThan(1e-5),
              reason: '${c.region} coupon=${coupon}bp at-par must be ~0');
        }
      }
    });
  });
}
