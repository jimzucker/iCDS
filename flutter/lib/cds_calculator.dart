/// Dart-side helpers that mirror `iCDS/icds/CDSCalculator.swift`'s pre-call
/// date logic and result struct: prev/next IMM dates, region-aware
/// business-day adder, and a CdsResult that carries the same set of
/// outputs as the Swift app's CDSResult.

import 'cds_holiday_calendar.dart';
import 'icds_spike.dart' as icds_spike;

export 'cds_holiday_calendar.dart' show CdsRegion;

class CdsResult {
  final double upfrontFraction;     // signed fraction of notional
  final double upfrontDollars;
  final double upfrontBp;
  final double price;               // 100 - upfront%
  final double accruedDollars;
  final double parSpreadBp;         // round-trip back-calc
  final DateTime startDate;         // SNAC accrual start (prev IMM)
  final DateTime valueDate;         // settle
  final DateTime endDate;           // next IMM after maturity

  const CdsResult({
    required this.upfrontFraction,
    required this.upfrontDollars,
    required this.upfrontBp,
    required this.price,
    required this.accruedDollars,
    required this.parSpreadBp,
    required this.startDate,
    required this.valueDate,
    required this.endDate,
  });
}

class CdsCalculator {
  /// IMM dates: 20 Mar / Jun / Sep / Dec.
  static const _immMonths = <int>[3, 6, 9, 12];

  /// Next IMM date strictly after [date].
  static DateTime nextIMMDate(DateTime date) {
    for (final m in _immMonths) {
      if (date.month < m || (date.month == m && date.day < 20)) {
        return DateTime(date.year, m, 20);
      }
    }
    return DateTime(date.year + 1, 3, 20);
  }

  /// Previous IMM date on or before [date].
  static DateTime prevIMMDate(DateTime date) {
    for (final m in _immMonths.reversed) {
      if (date.month > m || (date.month == m && date.day >= 20)) {
        return DateTime(date.year, m, 20);
      }
    }
    return DateTime(date.year - 1, 12, 20);
  }

  /// Add [n] business days, skipping weekends + the regional holiday set.
  static DateTime addBusinessDays(int n, DateTime date,
      {CdsRegion region = CdsRegion.nyFed}) {
    return CDSHolidayCalendar.addBusinessDays(n, date, region);
  }

  /// Most recent business day on or before [date].
  static DateTime lastValidTradeDate(DateTime date,
      {CdsRegion region = CdsRegion.nyFed}) {
    return CDSHolidayCalendar.prevBusinessDay(date, region);
  }

  /// Compute the upfront fee for a SNAC CDS trade. Mirrors the inputs of
  /// `CDSCalculator.calculate` in the Swift app.
  ///
  /// [minSettle], when supplied, clamps the computed settle date so it
  /// cannot fall in the past — matching the Swift app's behavior of
  /// passing `minSettle: Date()` when the user picks a back-dated trade.
  static CdsResult? calculate({
    required DateTime tradeDate,
    required int tenorYears,
    required double parSpreadBp,
    required double couponBp,
    required double recoveryRate,
    required double notional,
    required bool isBuy,
    int settleDays = 1,
    double discountRate = 0.045,
    CdsRegion region = CdsRegion.nyFed,
    DateTime? minSettle,
  }) {
    final today = tradeDate;
    final computedSettle = addBusinessDays(settleDays, tradeDate, region: region);
    final settle = (minSettle != null && computedSettle.isBefore(minSettle))
        ? minSettle
        : computedSettle;
    final start = prevIMMDate(tradeDate);
    final maturity = DateTime(
      tradeDate.year + tenorYears,
      tradeDate.month,
      tradeDate.day,
    );
    final end = nextIMMDate(maturity);

    final out = icds_spike.price(
      todayYear: today.year, todayMonth: today.month, todayDay: today.day,
      startYear: start.year, startMonth: start.month, startDay: start.day,
      endYear:   end.year,   endMonth:   end.month,   endDay:   end.day,
      settleYear:settle.year,settleMonth:settle.month,settleDay:settle.day,
      couponBp: couponBp,
      parSpreadBp: parSpreadBp,
      recoveryRate: recoveryRate,
      discountRate: discountRate,
    );
    if (out == null) return null;

    final signed = isBuy ? out.upfrontFraction : -out.upfrontFraction;
    // Accrued: days from prevIMM (start) to stepin (T+1 calendar) × coupon.
    final stepin = today.add(const Duration(days: 1));
    final accrualDays = stepin.difference(start).inDays.toDouble();
    final accrued = (couponBp / 10000.0) * (accrualDays / 360.0) * notional;

    return CdsResult(
      upfrontFraction: signed,
      upfrontDollars: signed * notional,
      upfrontBp: signed * 10000.0,
      price: (1.0 - signed) * 100.0,
      accruedDollars: accrued,
      parSpreadBp: out.parSpreadBp,
      startDate: start,
      valueDate: settle,
      endDate: end,
    );
  }
}
