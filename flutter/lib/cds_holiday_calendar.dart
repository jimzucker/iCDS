/// Regional holiday calendars for CDS settlement-date arithmetic, ported
/// from `iCDS/icds/CDSCalculator.swift` (`CDSHolidayCalendar`). Used for
/// trade-date defaulting and T+N business-day settle calculation; the
/// ISDA C library still uses its own "None" (weekend-only) calendar for
/// cash-flow bad-day adjustment.
///
/// Region keys mirror the Swift enum's string names:
///   nyFed   — US Federal Reserve (NA, EM, Asia, LCDS — fallback)
///   target  — ECB TARGET2 (EU)
///   tokyo   — TSE / JPX (Japan)
///   sydney  — ASX / NSW (AUS)
library;

enum CdsRegion {
  nyFed,
  target,
  tokyo,
  sydney;

  static CdsRegion fromName(String name) {
    switch (name) {
      case 'target': return CdsRegion.target;
      case 'tokyo':  return CdsRegion.tokyo;
      case 'sydney': return CdsRegion.sydney;
      default:       return CdsRegion.nyFed;
    }
  }
}

class CDSHolidayCalendar {
  /// Touch all four sets so they're built before the user changes region.
  static void prewarmAll() {
    _nyFedSet; _targetSet; _tokyoSet; _sydneySet;
  }

  /// Most recent business day on or before [date] in [region].
  /// Calendar-day arithmetic (DST-safe) — see [_usObserved].
  static DateTime prevBusinessDay(DateTime date, CdsRegion region) {
    var d = date;
    while (!isBusinessDay(d, region)) {
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return d;
  }

  /// Advance [n] business days from [date] in [region].
  /// Calendar-day arithmetic (DST-safe).
  static DateTime addBusinessDays(int n, DateTime date, CdsRegion region) {
    var result = date;
    var count = 0;
    while (count < n) {
      result = DateTime(result.year, result.month, result.day + 1);
      if (isBusinessDay(result, region)) count += 1;
    }
    return result;
  }

  static bool isBusinessDay(DateTime date, CdsRegion region) {
    if (_isWeekend(date)) return false;
    return !_isHoliday(date, region);
  }

  static bool _isWeekend(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  static bool _isHoliday(DateTime date, CdsRegion region) {
    final key = _dayInt(date);
    switch (region) {
      case CdsRegion.target: return _targetSet.contains(key);
      case CdsRegion.tokyo:  return _tokyoSet.contains(key);
      case CdsRegion.sydney: return _sydneySet.contains(key);
      case CdsRegion.nyFed:  return _nyFedSet.contains(key);
    }
  }

  /// Encode a date as a YYYYMMDD int for O(1) lookup.
  static int _dayInt(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static DateTime _d(int y, int m, int d) => DateTime(y, m, d);

  /// US Saturday→Friday, Sunday→Monday observed-holiday rule.
  /// Uses calendar-day arithmetic (DateTime constructor) instead of
  /// `Duration` to be DST-immune — `add(Duration(days: 1))` crosses
  /// "fall back" boundaries and lands an hour earlier on the *previous*
  /// day, which then mis-keys the YYYYMMDD set lookup.
  static DateTime _usObserved(DateTime date) {
    if (date.weekday == DateTime.saturday) {
      return DateTime(date.year, date.month, date.day - 1);
    }
    if (date.weekday == DateTime.sunday) {
      return DateTime(date.year, date.month, date.day + 1);
    }
    return date;
  }

  /// Nth weekday of (month, year). [weekday] uses Dart's `DateTime.monday=1
  /// … sunday=7` convention (NOT Swift's 1=Sun..7=Sat).
  static DateTime _nthWeekday(int n, {required int weekday, required int month, required int year}) {
    final first = _d(year, month, 1);
    var offset = weekday - first.weekday;
    if (offset < 0) offset += 7;
    offset += (n - 1) * 7;
    return DateTime(year, month, 1 + offset);
  }

  /// Last occurrence of [weekday] in (month, year). Same Dart-weekday convention.
  static DateTime _lastWeekday(int weekday, {required int month, required int year}) {
    // Day 0 of next month == last day of current month.
    final last = DateTime(year, month + 1, 0);
    var offset = last.weekday - weekday;
    if (offset < 0) offset += 7;
    return DateTime(last.year, last.month, last.day - offset);
  }

  /// Easter Sunday — Anonymous Gregorian algorithm.
  static DateTime _easter(int year) {
    final a = year % 19, b = year ~/ 100, c = year % 100;
    final d = b ~/ 4, e = b % 4, f = (b + 8) ~/ 25, g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4, k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final mo = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * mo + 114) ~/ 31;
    final day = (h + l - 7 * mo + 114) % 31 + 1;
    return _d(year, month, day);
  }

  // DST-immune day arithmetic (see _usObserved comment).
  static DateTime _addDays(int n, DateTime d) =>
      DateTime(d.year, d.month, d.day + n);

  // === Lazily-built holiday sets (one per region) ===

  static final Set<int> _nyFedSet  = _buildNYFed();
  static final Set<int> _targetSet = _buildTarget();
  static final Set<int> _tokyoSet  = _buildTokyo();
  static final Set<int> _sydneySet = _buildSydney();

  static Set<int> _buildNYFed() {
    final s = <int>{};
    for (var y = 2024; y <= 2030; y++) {
      // Fixed (adjusted to nearest weekday per US convention)
      for (final dt in [_d(y, 1, 1), _d(y, 6, 19), _d(y, 7, 4), _d(y, 11, 11), _d(y, 12, 25)]) {
        s.add(_dayInt(_usObserved(dt)));
      }
      // Floating — Dart weekday: Mon=1, Thu=4
      s.add(_dayInt(_nthWeekday(3, weekday: DateTime.monday,   month:  1, year: y))); // MLK Day
      s.add(_dayInt(_nthWeekday(3, weekday: DateTime.monday,   month:  2, year: y))); // Presidents Day
      s.add(_dayInt(_lastWeekday(   DateTime.monday,            month:  5, year: y))); // Memorial Day
      s.add(_dayInt(_nthWeekday(1, weekday: DateTime.monday,   month:  9, year: y))); // Labor Day
      s.add(_dayInt(_nthWeekday(2, weekday: DateTime.monday,   month: 10, year: y))); // Columbus Day
      s.add(_dayInt(_nthWeekday(4, weekday: DateTime.thursday, month: 11, year: y))); // Thanksgiving
    }
    return s;
  }

  static Set<int> _buildTarget() {
    final s = <int>{};
    for (var y = 2024; y <= 2030; y++) {
      final e = _easter(y);
      s.add(_dayInt(_d(y, 1, 1)));        // New Year's Day
      s.add(_dayInt(_addDays(-2, e)));    // Good Friday
      s.add(_dayInt(_addDays( 1, e)));    // Easter Monday
      s.add(_dayInt(_d(y, 5, 1)));        // Labour Day
      s.add(_dayInt(_d(y, 12, 25)));      // Christmas Day
      s.add(_dayInt(_d(y, 12, 26)));      // Boxing Day
    }
    return s;
  }

  static Set<int> _buildTokyo() {
    final s = <int>{};
    for (var y = 2024; y <= 2030; y++) {
      // Fixed national holidays
      for (final dt in [
        _d(y, 1, 1), _d(y, 2, 11), _d(y, 2, 23),
        _d(y, 4, 29), _d(y, 5, 3), _d(y, 5, 4), _d(y, 5, 5),
        _d(y, 8, 11), _d(y, 11, 3), _d(y, 11, 23),
        _d(y, 12, 31),
      ]) {
        s.add(_dayInt(dt));
      }
      // Floating (TSE calendar — substitute-holiday rule simplified here)
      s.add(_dayInt(_nthWeekday(2, weekday: DateTime.monday, month:  1, year: y))); // Coming of Age
      s.add(_dayInt(_nthWeekday(3, weekday: DateTime.monday, month:  7, year: y))); // Marine Day
      s.add(_dayInt(_nthWeekday(3, weekday: DateTime.monday, month:  9, year: y))); // Respect for the Aged
      s.add(_dayInt(_nthWeekday(2, weekday: DateTime.monday, month: 10, year: y))); // Sports Day
      // Equinoxes (approximate — vary ±1 day astronomically)
      s.add(_dayInt(_d(y, 3, 20)));    // Vernal Equinox
      s.add(_dayInt(_d(y, 9, 23)));    // Autumnal Equinox
    }
    return s;
  }

  static Set<int> _buildSydney() {
    final s = <int>{};
    for (var y = 2024; y <= 2030; y++) {
      final e = _easter(y);
      // Australia Day: Jan 26 (Mon if on weekend)
      final jan26 = _d(y, 1, 26);
      final DateTime ausDay;
      if (jan26.weekday == DateTime.saturday) {
        ausDay = _addDays(2, jan26);
      } else if (jan26.weekday == DateTime.sunday) {
        ausDay = _addDays(1, jan26);
      } else {
        ausDay = jan26;
      }
      s.add(_dayInt(_usObserved(_d(y, 1, 1))));     // New Year's Day
      s.add(_dayInt(ausDay));                         // Australia Day
      s.add(_dayInt(_addDays(-2, e)));                // Good Friday
      s.add(_dayInt(_addDays(-1, e)));                // Easter Saturday
      s.add(_dayInt(_addDays( 1, e)));                // Easter Monday
      s.add(_dayInt(_usObserved(_d(y, 4, 25))));     // ANZAC Day
      s.add(_dayInt(_nthWeekday(2, weekday: DateTime.monday, month:  6, year: y))); // King's Birthday
      s.add(_dayInt(_nthWeekday(1, weekday: DateTime.monday, month:  8, year: y))); // Bank Holiday (NSW)
      s.add(_dayInt(_nthWeekday(1, weekday: DateTime.monday, month: 10, year: y))); // Labour Day (NSW)
      s.add(_dayInt(_usObserved(_d(y, 12, 25))));    // Christmas Day
      s.add(_dayInt(_usObserved(_d(y, 12, 26))));    // Boxing Day
    }
    return s;
  }
}
