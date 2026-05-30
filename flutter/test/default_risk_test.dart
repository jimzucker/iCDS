//
//  default_risk_test.dart
//  icds
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//

/// Pure-Dart parity port of `icdsTests.swift`'s Default-risk section
/// (flat-hazard cumulative default probability). Pure math, no FFI —
/// run with: `flutter test test/default_risk_test.dart`
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:icds_spike/cds_calculator.dart';

void main() {
  group('Cumulative default probability (flat-hazard)', () {
    double pd(num t) => CdsCalculator.cumulativeDefaultProb(
          spreadBp: 150,
          recoveryRate: 0.40,
          years: t,
        );

    test('closed-form values: λ = (150/1e4)/(1−0.40) = 0.025', () {
      // P(T) = 1 − e^(−0.025·T)
      expect(pd(1), closeTo(0.0246901, 1e-6));
      expect(pd(2), closeTo(0.0487706, 1e-6));
      expect(pd(5), closeTo(0.1175031, 1e-6));
      expect(pd(10), closeTo(0.2211992, 1e-6));
    });

    test('monotonic increasing in maturity, bounded below 1', () {
      var prev = 0.0;
      for (final t in [1, 2, 3, 4, 5, 7, 10]) {
        final p = pd(t);
        expect(p, greaterThan(prev), reason: '${t}Y');
        expect(p, lessThan(1.0));
        prev = p;
      }
    });

    test('monotonic increasing in spread', () {
      final low = CdsCalculator.cumulativeDefaultProb(
          spreadBp: 100, recoveryRate: 0.40, years: 5);
      final high = CdsCalculator.cumulativeDefaultProb(
          spreadBp: 400, recoveryRate: 0.40, years: 5);
      expect(high, greaterThan(low));
    });

    test('higher recovery → higher implied default prob (fixed spread)', () {
      // Credit triangle: λ = S / (1 − R); larger R ⇒ smaller (1−R) ⇒ larger λ.
      final r20 = CdsCalculator.cumulativeDefaultProb(
          spreadBp: 150, recoveryRate: 0.20, years: 5);
      final r60 = CdsCalculator.cumulativeDefaultProb(
          spreadBp: 150, recoveryRate: 0.60, years: 5);
      expect(r60, greaterThan(r20));
    });

    test('degenerate inputs return 0', () {
      expect(
          CdsCalculator.cumulativeDefaultProb(
              spreadBp: 150, recoveryRate: 0.40, years: 0),
          0);
      expect(
          CdsCalculator.cumulativeDefaultProb(
              spreadBp: 0, recoveryRate: 0.40, years: 5),
          0);
      expect(
          CdsCalculator.cumulativeDefaultProb(
              spreadBp: 150, recoveryRate: 1.0, years: 5),
          0);
    });
  });
}
