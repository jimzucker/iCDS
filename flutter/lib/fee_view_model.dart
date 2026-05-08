/// Reactive state for the Fee tab. Mirrors `FeeViewModel.swift`'s public
/// surface (region/buy-sell/notional/maturity/coupon/recovery/spread/
/// trade-date inputs, and result/discountRate/discountRateStatus
/// outputs) using `ChangeNotifier` instead of Combine `@Published`.

import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';

import 'cds_calculator.dart';   // re-exports CdsRegion from cds_holiday_calendar
import 'contract.dart';
import 'sofr_fetcher.dart';

class FeeViewModel extends ChangeNotifier {
  // Static option lists — match Swift FeeViewModel
  static const notionalLabels = <String>['1M', '5M', '10M', '20M'];
  static const notionalValues = <double>[
    1_000_000, 5_000_000, 10_000_000, 20_000_000,
  ];
  static const tenorLabels = <String>['1Y', '5Y', '7Y', '10Y'];
  static const tenorYearsList = <int>[1, 5, 7, 10];

  // Inputs
  int _regionIndex = 0;
  int _buySellIndex = 0;       // 0=Buy 1=Sell
  int _notionalIndex = 2;      // 10M default
  int _maturityIndex = 1;      // 5Y default
  int _couponIndex = 0;
  int _recoveryIndex = 0;
  double _spreadBp = 100;
  int _tradeDateOffset = 0;    // days from today

  int get regionIndex => _regionIndex;
  int get buySellIndex => _buySellIndex;
  int get notionalIndex => _notionalIndex;
  int get maturityIndex => _maturityIndex;
  int get couponIndex => _couponIndex;
  int get recoveryIndex => _recoveryIndex;
  double get spreadBp => _spreadBp;
  int get tradeDateOffset => _tradeDateOffset;

  set regionIndex(int v) {
    if (_regionIndex == v) return;
    _regionIndex = v;
    _onRegionChanged();
    _recalculate();
  }

  set buySellIndex(int v) {
    if (_buySellIndex == v) return;
    _buySellIndex = v;
    _recalculate();
  }

  set notionalIndex(int v) {
    if (_notionalIndex == v) return;
    _notionalIndex = v;
    _recalculate();
  }

  set maturityIndex(int v) {
    if (_maturityIndex == v) return;
    _maturityIndex = v;
    _recalculate();
  }

  set couponIndex(int v) {
    if (_couponIndex == v) return;
    _couponIndex = v;
    _spreadBp = couponBp;            // resetSpreadToCoupon
    _recalculate();
  }

  set recoveryIndex(int v) {
    if (_recoveryIndex == v) return;
    _recoveryIndex = v;
    _recalculate();
  }

  set spreadBp(double v) {
    if (_spreadBp == v) return;
    _spreadBp = v;
    _recalculate();
  }

  set tradeDateOffset(int v) {
    final clamped = v.clamp(-365, 0);
    if (_tradeDateOffset == clamped) return;
    _tradeDateOffset = clamped;
    // Kick the per-currency rate refresh; intentionally not awaited
    // (UI shouldn't block on the network), but `unawaited` makes the
    // fire-and-forget intent explicit and keeps the Future from being
    // GC'd before it completes.
    unawaited(_store.updateForTradeDate(tradeDate));
    _recalculate();
  }

  // Derived
  List<ISDAContract> _contracts = const [];
  List<ISDAContract> get contracts => _contracts;
  ISDAContract? get contract =>
      _contracts.isNotEmpty && _regionIndex < _contracts.length
          ? _contracts[_regionIndex]
          : null;

  double get couponBp {
    final c = contract;
    if (c == null || c.coupons.isEmpty) return 100;
    return c.coupons[_couponIndex.clamp(0, c.coupons.length - 1)].toDouble();
  }

  int get recoveryPct {
    final c = contract;
    if (c == null || c.recoveryList.isEmpty) return 40;
    return c.recoveryList[_recoveryIndex.clamp(0, c.recoveryList.length - 1)].recovery;
  }

  String get currency => contract?.currency ?? 'USD';
  CdsRegion get calendar => contract?.calendar ?? CdsRegion.nyFed;

  DateTime get tradeDate {
    // Calendar-day arithmetic via the DateTime constructor (DST-safe).
    // `DateTime.now().add(Duration(days: N))` is not — across a fall-back
    // transition it lands an hour earlier on the *previous* day, which
    // would mis-key the YYYYMMDD set lookup inside lastValidTradeDate.
    final today = DateTime.now();
    final raw = DateTime(today.year, today.month, today.day + _tradeDateOffset);
    return CdsCalculator.lastValidTradeDate(raw, region: calendar);
  }

  CdsResult? _result;
  CdsResult? get result => _result;

  // Discount rate from the per-currency RFR store
  RFRCurrency get _rfrForCurrency {
    switch (currency) {
      case 'EUR': return RFRCurrency.eur;
      case 'GBP': return RFRCurrency.gbp;
      case 'JPY': return RFRCurrency.jpy;
      case 'AUD': return RFRCurrency.aud;
      default:    return RFRCurrency.usd;
    }
  }

  double get discountRate => _store.rateFor(_rfrForCurrency);
  String get discountRateDate => _store.effectiveDateFor(_rfrForCurrency);
  SOFRDataStatus get discountRateStatus => _store.statusFor(_rfrForCurrency);

  final SOFRRateStore _store = SOFRRateStore.shared;
  bool _disposed = false;

  FeeViewModel() {
    _store.addListener(_onStoreChanged);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _contracts = await ISDAContract.loadFromAsset();
    if (_disposed) return;
    if (_contracts.isNotEmpty) {
      _spreadBp = couponBp;
    }
    // Snap to last valid business day of the region's calendar.
    // We compute the day delta via UTC dates so a DST transition between
    // `today` and `last` doesn't yank an hour out of the Duration and
    // throw off `.inDays`.
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final last = CdsCalculator.lastValidTradeDate(todayMidnight, region: calendar);
    final lastUtc  = DateTime.utc(last.year, last.month, last.day);
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    _tradeDateOffset = lastUtc.difference(todayUtc).inDays;
    _recalculate();
    unawaited(_store.updateForTradeDate(tradeDate));
  }

  @override
  void dispose() {
    _disposed = true;
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() => _recalculate();

  void _onRegionChanged() {
    _couponIndex = 0;
    _recoveryIndex = 0;
    _spreadBp = couponBp;
  }

  /// Hypothetical-spread preview (used by the spread-edit dialog).
  CdsResult? previewUpfront(double spread) {
    final c = contract;
    if (c == null) return null;
    final today = DateTime.now();
    return CdsCalculator.calculate(
      tradeDate: tradeDate,
      tenorYears: tenorYearsList[_maturityIndex],
      parSpreadBp: spread,
      couponBp: couponBp,
      recoveryRate: recoveryPct / 100.0,
      notional: notionalValues[_notionalIndex],
      isBuy: _buySellIndex == 0,
      settleDays: c.settleDays,
      discountRate: discountRate,
      region: calendar,
      minSettle: DateTime(today.year, today.month, today.day),
    );
  }

  void _recalculate() {
    if (_disposed) return;
    final c = contract;
    if (c == null) return;
    final today = DateTime.now();
    _result = CdsCalculator.calculate(
      tradeDate: tradeDate,
      tenorYears: tenorYearsList[_maturityIndex],
      parSpreadBp: _spreadBp,
      couponBp: couponBp,
      recoveryRate: recoveryPct / 100.0,
      notional: notionalValues[_notionalIndex],
      isBuy: _buySellIndex == 0,
      settleDays: c.settleDays,
      discountRate: discountRate,
      region: calendar,
      minSettle: DateTime(today.year, today.month, today.day),
    );
    if (_disposed) return;
    notifyListeners();
  }
}
