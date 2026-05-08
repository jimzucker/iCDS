/// Integration-test parity port of the SOFR network section of
/// `icdsTests.swift`. All assertions skip-if-offline (mirroring the
/// Swift `guard date != "unavailable" else { return }` pattern) so the
/// suite stays green in environments without internet.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:icds_spike/sofr_fetcher.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SOFR / RFR fetcher', () {
    test('USD SOFR fetch returns a plausible rate (skip-if-offline)', () async {
      final r = await RFRFetcher.fetch(RFRCurrency.usd);
      if (r.effectiveDate == 'unavailable') return;
      expect(r.rate, greaterThan(0.001));
      expect(r.rate, lessThan(0.20));
    });

    test('USD SOFR effective date is ISO yyyy-MM-dd (skip-if-offline)', () async {
      final r = await RFRFetcher.fetch(RFRCurrency.usd);
      if (r.effectiveDate == 'unavailable') return;
      final parts = r.effectiveDate.split('-');
      expect(parts.length, 3);
      expect(parts[0].length, 4);
      expect(parts[1].length, 2);
      expect(parts[2].length, 2);
    });

    test('every currency returns a rate or graceful fallback', () async {
      for (final c in RFRCurrency.values) {
        final r = await RFRFetcher.fetch(c);
        // Either live-shaped result or fallback marker — never throws.
        expect(r.rate, greaterThan(0.0).or(equals(c.fallbackRate)),
            reason: '${c.code} rate should be > 0 or fallback');
      }
    });
  });
}

extension _OrMatcher on Matcher {
  Matcher or(Matcher other) => anyOf(this, other);
}
