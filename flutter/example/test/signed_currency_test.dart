/// Regression tests for formatSignedCurrency in theme.dart.
/// Guards against re-introducing "−$0" on the Fee tab when par-spread
/// = coupon makes upfrontDollars a tiny negative double from numerical
/// noise. Pure Dart — no FFI, no device.

import 'package:flutter_test/flutter_test.dart';

import 'package:icds_spike_example/theme.dart';

void main() {
  group('formatSignedCurrency — −\$0 suppression', () {
    test('tiny negative renders as unsigned \$0', () {
      expect(formatSignedCurrency(-0.001, 'USD'), '\$0');
      expect(formatSignedCurrency(-0.49, 'USD'), '\$0');
    });

    test('tiny positive renders as unsigned \$0', () {
      expect(formatSignedCurrency(0.001, 'USD'), '\$0');
      expect(formatSignedCurrency(0.49, 'USD'), '\$0');
    });

    test('exact zero is unsigned', () {
      expect(formatSignedCurrency(0.0, 'USD'), '\$0');
    });
  });

  group('formatSignedCurrency — meaningful magnitudes keep sign', () {
    test('\$100 negative keeps U+2212 minus', () {
      expect(formatSignedCurrency(-100.0, 'USD'), '−\$100');
    });

    test('\$100 positive is unsigned', () {
      expect(formatSignedCurrency(100.0, 'USD'), '\$100');
    });

    test('thousands separator preserved with minus', () {
      expect(formatSignedCurrency(-15833.0, 'USD'), '−\$15,833');
    });

    test('thousands separator preserved when positive', () {
      expect(formatSignedCurrency(15833.0, 'USD'), '\$15,833');
    });
  });
}
