/// Pure-Dart parity port of `icdsTests.swift`'s holiday-calendar sections
/// (nyFed / TARGET / Tokyo / Sydney) and lastValidTradeDate cases.
/// Run with: `flutter test test/holiday_calendar_test.dart`

import 'package:flutter_test/flutter_test.dart';
import 'package:icds_spike/cds_calculator.dart';
import 'package:icds_spike/cds_holiday_calendar.dart';

void main() {
  DateTime d(int y, int m, int dd) => DateTime(y, m, dd);
  String iso(DateTime x) =>
      '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';

  group('Holiday calendar — nyFed', () {
    test('MLK Day 2025-01-20 is a holiday', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 1, 20), CdsRegion.nyFed), isFalse);
    });
    test('Memorial Day 2025-05-26 is a holiday', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 5, 26), CdsRegion.nyFed), isFalse);
    });
    test('Independence Day 2025-07-04 is a holiday', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 7, 4), CdsRegion.nyFed), isFalse);
    });
    test('Thanksgiving 2025-11-27 is a holiday', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 11, 27), CdsRegion.nyFed), isFalse);
    });
    test('Good Friday 2025-04-18 is NOT a Federal Reserve holiday', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 4, 18), CdsRegion.nyFed), isTrue);
    });
    test('Regular Wednesday 2025-03-12 is a business day', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 3, 12), CdsRegion.nyFed), isTrue);
    });
  });

  group('Holiday calendar — TARGET (ECB)', () {
    test('Good Friday 2025-04-18 is a TARGET holiday', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 4, 18), CdsRegion.target), isFalse);
    });
    test('Easter Monday 2025-04-21 is a TARGET holiday', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 4, 21), CdsRegion.target), isFalse);
    });
    test('May Day 2025-05-01 is a TARGET holiday', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 5, 1), CdsRegion.target), isFalse);
    });
    test('Boxing Day 2025-12-26 is a TARGET holiday', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 12, 26), CdsRegion.target), isFalse);
    });
    test('Good Friday differs across calendars (TARGET closed, nyFed open)', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 4, 18), CdsRegion.target), isFalse);
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 4, 18), CdsRegion.nyFed),  isTrue);
    });
  });

  group('Holiday calendar — Tokyo (TSE)', () {
    test('Coming of Age 2nd Mon Jan = 2025-01-13 is a holiday', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 1, 13), CdsRegion.tokyo), isFalse);
    });
    test('Golden Week May 3 + May 5 are holidays', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 5, 3), CdsRegion.tokyo), isFalse);
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 5, 5), CdsRegion.tokyo), isFalse);
    });
    test('Year-end 2025-12-31 is a holiday', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 12, 31), CdsRegion.tokyo), isFalse);
    });
    test('Regular day 2025-03-12 is a business day', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 3, 12), CdsRegion.tokyo), isTrue);
    });
  });

  group('Holiday calendar — Sydney (ASX/NSW)', () {
    test('Australia Day 2025: Jan 26 is Sun → observed Mon Jan 27', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 1, 27), CdsRegion.sydney), isFalse);
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 1, 28), CdsRegion.sydney), isTrue);
    });
    test('Good Friday 2025-04-18 is a Sydney holiday', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 4, 18), CdsRegion.sydney), isFalse);
    });
    test('ANZAC Day 2025-04-25 is a Sydney holiday', () {
      expect(CDSHolidayCalendar.isBusinessDay(d(2025, 4, 25), CdsRegion.sydney), isFalse);
    });
  });

  group('Last valid trade date', () {
    test('Saturday 2025-04-05 snaps back to Friday 2025-04-04', () {
      final last = CdsCalculator.lastValidTradeDate(d(2025, 4, 5), region: CdsRegion.nyFed);
      expect(iso(last), '2025-04-04');
    });
    test('Sunday 2025-04-06 snaps back to Friday 2025-04-04', () {
      final last = CdsCalculator.lastValidTradeDate(d(2025, 4, 6), region: CdsRegion.nyFed);
      expect(iso(last), '2025-04-04');
    });
    test('MLK Day 2025-01-20 (Mon) snaps back to Friday 2025-01-17', () {
      final last = CdsCalculator.lastValidTradeDate(d(2025, 1, 20), region: CdsRegion.nyFed);
      expect(iso(last), '2025-01-17');
    });
    test('TARGET Good Friday 2025-04-18 snaps back to Thu 2025-04-17', () {
      final last = CdsCalculator.lastValidTradeDate(d(2025, 4, 18), region: CdsRegion.target);
      expect(iso(last), '2025-04-17');
    });
    test('Regular weekday 2025-03-12 unchanged', () {
      final last = CdsCalculator.lastValidTradeDate(d(2025, 3, 12), region: CdsRegion.nyFed);
      expect(iso(last), '2025-03-12');
    });
    test('nyFed open on Good Friday 2025-04-18', () {
      final last = CdsCalculator.lastValidTradeDate(d(2025, 4, 18), region: CdsRegion.nyFed);
      expect(iso(last), '2025-04-18');
    });
  });

  group('Settle date arithmetic — full holiday calendar', () {
    test('T+1 nyFed from Fri 2025-05-23 skips Memorial Day to Tue 2025-05-27', () {
      final s = CdsCalculator.addBusinessDays(1, d(2025, 5, 23), region: CdsRegion.nyFed);
      expect(iso(s), '2025-05-27');
    });
    test('T+1 target from Thu 2025-04-17 skips Good Fri + Easter Mon to Tue 2025-04-22', () {
      final s = CdsCalculator.addBusinessDays(1, d(2025, 4, 17), region: CdsRegion.target);
      expect(iso(s), '2025-04-22');
    });
    test('T+3 nyFed from Mon 2025-04-14 → Thu 2025-04-17', () {
      final s = CdsCalculator.addBusinessDays(3, d(2025, 4, 14), region: CdsRegion.nyFed);
      expect(iso(s), '2025-04-17');
    });
  });
}
