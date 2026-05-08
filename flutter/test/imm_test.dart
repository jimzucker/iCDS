/// Pure-Dart parity port of `icdsTests.swift`'s IMM Date Helpers section.
/// Run with: `flutter test test/imm_test.dart`

import 'package:flutter_test/flutter_test.dart';
import 'package:icds_spike/cds_calculator.dart';

void main() {
  group('IMM date helpers', () {
    test('next IMM strictly after Mar 10 → Mar 20 same year', () {
      final imm = CdsCalculator.nextIMMDate(DateTime(2024, 3, 10));
      expect(imm, DateTime(2024, 3, 20));
    });

    test('next IMM after Dec 21 rolls to next year Mar 20', () {
      final imm = CdsCalculator.nextIMMDate(DateTime(2024, 12, 21));
      expect(imm, DateTime(2025, 3, 20));
    });

    test('next IMM exactly on Jun 20 advances to Sep 20', () {
      final imm = CdsCalculator.nextIMMDate(DateTime(2024, 6, 20));
      expect(imm, DateTime(2024, 9, 20));
    });

    test('prev IMM before Jun 15 → Mar 20 same year', () {
      final prev = CdsCalculator.prevIMMDate(DateTime(2024, 6, 15));
      expect(prev, DateTime(2024, 3, 20));
    });

    test('prev IMM on Dec 20 returns same day', () {
      final prev = CdsCalculator.prevIMMDate(DateTime(2024, 12, 20));
      expect(prev, DateTime(2024, 12, 20));
    });
  });
}
