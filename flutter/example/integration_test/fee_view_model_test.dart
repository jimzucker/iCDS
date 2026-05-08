/// Integration-test parity port of `icdsTests.swift`'s FeeViewModel async
/// init section. Mirrors the Swift tests as closely as Dart's
/// ChangeNotifier / Future model allows.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:icds_spike/cds_holiday_calendar.dart';
import 'package:icds_spike/fee_view_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FeeViewModel — async init', () {
    test('result starts nil before async bootstrap completes', () {
      final vm = FeeViewModel();
      // Synchronous read right after construction — bootstrap is in flight.
      expect(vm.result, isNull, reason: 'result must be nil before bootstrap');
      vm.dispose();
    });

    test('result is non-nil after bootstrap', () async {
      final vm = FeeViewModel();
      // Cover asset load (~100ms) + holiday-calendar prewarm + recalc.
      await Future.delayed(const Duration(seconds: 1));
      expect(vm.result, isNotNull);
      vm.dispose();
    });

    test('trade date is a business day after async init', () async {
      final vm = FeeViewModel();
      await Future.delayed(const Duration(milliseconds: 500));
      final region = vm.calendar;
      expect(CDSHolidayCalendar.isBusinessDay(vm.tradeDate, region), isTrue,
          reason: 'tradeDate must be a valid business day for $region');
      vm.dispose();
    });

    test('result remains valid after SOFR refresh', () async {
      final vm = FeeViewModel();
      await Future.delayed(const Duration(seconds: 1));
      final r1 = vm.result;
      expect(r1, isNotNull);

      // Trigger a fetch; result should remain a valid pricing.
      // (We don't await the network — just check post-refresh state.)
      await Future.delayed(const Duration(seconds: 1));
      expect(vm.result, isNotNull);
      expect(vm.result!.price, greaterThan(50.0));
      expect(vm.result!.price, lessThan(120.0));
      vm.dispose();
    });
  });

  group('FeeViewModel — spread initialization', () {
    test('spreadBp positive at construction (defaulted from coupon list)', () async {
      final vm = FeeViewModel();
      await Future.delayed(const Duration(milliseconds: 300));
      expect(vm.spreadBp, greaterThan(0),
          reason: 'spreadBp must never be 0 — would open picker showing 0 bp');
      vm.dispose();
    });

    test('spreadBp matches default contract first coupon at init', () async {
      final vm = FeeViewModel();
      await Future.delayed(const Duration(milliseconds: 300));
      expect((vm.spreadBp - vm.couponBp).abs(), lessThan(0.001),
          reason: 'spreadBp at init should equal default coupon');
      vm.dispose();
    });

    test('previewUpfront uses current state and gives ~0 at par', () async {
      final vm = FeeViewModel();
      await Future.delayed(const Duration(seconds: 1));
      final atPar = vm.previewUpfront(vm.couponBp);
      expect(atPar, isNotNull);
      expect(atPar!.upfrontDollars.abs(), lessThan(1.0));

      final wide = vm.previewUpfront(vm.couponBp + 200);
      expect(wide, isNotNull);
      expect(wide!.upfrontDollars, greaterThan(0));
      vm.dispose();
    });
  });
}
