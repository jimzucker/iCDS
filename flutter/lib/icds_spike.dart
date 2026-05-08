import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'icds_spike_bindings_generated.dart';

export 'package:ffi/ffi.dart' show malloc, calloc;

/// JpmcdsDate(year, month, day) — TDate (days since 1601-01-01) or -1 on failure.
int jpmcdsDate(int year, int month, int day) =>
    _bindings.jpmcdsDate(year, month, day);

/// Full SNAC CDS upfront-charge calculation. All dates are passed as plain
/// (year, month, day) integers and the wrapper builds the discount curve and
/// schedule structs internally. Returns the upfront fraction of notional
/// (positive ⇒ buyer pays seller) or null on failure.
double? upfrontFraction({
  required int todayYear, required int todayMonth, required int todayDay,
  required int startYear, required int startMonth, required int startDay,
  required int endYear,   required int endMonth,   required int endDay,
  required int settleYear,required int settleMonth,required int settleDay,
  required double couponBp,
  required double parSpreadBp,
  required double recoveryRate,
  required double discountRate,
}) {
  final out = calloc<Double>();
  try {
    final status = _bindings.upfront(
      todayYear: todayYear, todayMonth: todayMonth, todayDay: todayDay,
      startYear: startYear, startMonth: startMonth, startDay: startDay,
      endYear: endYear, endMonth: endMonth, endDay: endDay,
      settleYear: settleYear, settleMonth: settleMonth, settleDay: settleDay,
      couponBp: couponBp,
      parSpreadBp: parSpreadBp,
      recoveryRate: recoveryRate,
      discountRate: discountRate,
      out: out,
    );
    if (status != 0) return null;
    return out.value;
  } finally {
    calloc.free(out);
  }
}

class PricingOutputs {
  final double upfrontFraction;
  final double parSpreadBp;
  const PricingOutputs(this.upfrontFraction, this.parSpreadBp);
}

/// One instrument on a built IR zero curve — either a money-market deposit
/// (`type='M'`) or a swap (`type='S'`).
class CurveInstrument {
  final String type;   // 'M' or 'S'
  final String tenor;  // e.g. "1M", "5Y"
  final double rate;   // decimal
  const CurveInstrument(this.type, this.tenor, this.rate);
}

/// DCC codes mirroring `ldate.h` in the ISDA C library.
class IsdaDcc {
  static const act365F = 2;
  static const act360 = 3;
  static const b30360 = 4;
  static const b30E360 = 5;
}

/// Full pricing against a *shaped* IR zero curve built from deposits + swaps.
/// Used by the QuantLib / ISDA RFR reference test grids. Returns null on
/// failure.
PricingOutputs? priceWithCurve({
  required List<CurveInstrument> instruments,
  required DateTime curveValueDate,
  required DateTime tradeDate,
  required DateTime settleDate,
  required DateTime stepinDate,
  required DateTime startDate,
  required DateTime endDate,
  required int mmDcc,
  required int fixedSwapFreq,   // OIS=1, semi=2
  required int floatSwapFreq,   // OIS=1, quarterly=4
  required int fixedSwapDcc,
  required int floatSwapDcc,
  required double couponBp,
  required double parSpreadBp,
  required double recoveryRate,
  bool isPriceClean = true,
}) {
  if (instruments.isEmpty) return null;

  // Build the C-side strings + arrays.
  final n = instruments.length;
  final typesStr = instruments.map((i) => i.type).join();
  // Tenor blob: each tenor as null-terminated UTF-8, concatenated.
  final tenorBytes = <int>[];
  for (final i in instruments) {
    tenorBytes.addAll(i.tenor.codeUnits);
    tenorBytes.add(0);
  }

  final typesPtr = typesStr.toNativeUtf8();
  final tenorsPtr = calloc<Uint8>(tenorBytes.length);
  for (var i = 0; i < tenorBytes.length; i++) {
    tenorsPtr[i] = tenorBytes[i];
  }
  final ratesPtr = calloc<Double>(n);
  for (var i = 0; i < n; i++) {
    ratesPtr[i] = instruments[i].rate;
  }

  final upOut = calloc<Double>();
  final parOut = calloc<Double>();
  try {
    final status = _bindings.priceWithCurve(
      nInstr: n,
      instrTypes: typesPtr.cast(),
      instrTenors: tenorsPtr.cast(),
      instrRates: ratesPtr,
      curveYear: curveValueDate.year, curveMonth: curveValueDate.month, curveDay: curveValueDate.day,
      tradeYear: tradeDate.year, tradeMonth: tradeDate.month, tradeDay: tradeDate.day,
      settleYear: settleDate.year, settleMonth: settleDate.month, settleDay: settleDate.day,
      stepinYear: stepinDate.year, stepinMonth: stepinDate.month, stepinDay: stepinDate.day,
      startYear: startDate.year, startMonth: startDate.month, startDay: startDate.day,
      endYear: endDate.year, endMonth: endDate.month, endDay: endDate.day,
      mmDcc: mmDcc,
      fixedSwapFreq: fixedSwapFreq,
      floatSwapFreq: floatSwapFreq,
      fixedSwapDcc: fixedSwapDcc,
      floatSwapDcc: floatSwapDcc,
      couponBp: couponBp,
      parSpreadBp: parSpreadBp,
      recoveryRate: recoveryRate,
      isPriceClean: isPriceClean ? 1 : 0,
      upfrontOut: upOut,
      parSpreadOut: parOut,
    );
    if (status != 0) return null;
    return PricingOutputs(upOut.value, parOut.value);
  } finally {
    // typesPtr came from toNativeUtf8() which uses the malloc allocator;
    // the rest came from calloc<T>(). Both ultimately call C `free()`,
    // but the convention is to release with the matching allocator.
    malloc.free(typesPtr);
    calloc.free(tenorsPtr);
    calloc.free(ratesPtr);
    calloc.free(upOut);
    calloc.free(parOut);
  }
}

/// Full pricing — runs both forward (upfront) and inverse (par spread) ISDA
/// calls in a single C round-trip. Returns null on failure.
PricingOutputs? price({
  required int todayYear, required int todayMonth, required int todayDay,
  required int startYear, required int startMonth, required int startDay,
  required int endYear,   required int endMonth,   required int endDay,
  required int settleYear,required int settleMonth,required int settleDay,
  required double couponBp,
  required double parSpreadBp,
  required double recoveryRate,
  required double discountRate,
}) {
  final up = calloc<Double>();
  final par = calloc<Double>();
  try {
    final status = _bindings.price(
      todayYear: todayYear, todayMonth: todayMonth, todayDay: todayDay,
      startYear: startYear, startMonth: startMonth, startDay: startDay,
      endYear: endYear, endMonth: endMonth, endDay: endDay,
      settleYear: settleYear, settleMonth: settleMonth, settleDay: settleDay,
      couponBp: couponBp,
      parSpreadBp: parSpreadBp,
      recoveryRate: recoveryRate,
      discountRate: discountRate,
      upfrontOut: up,
      parSpreadOut: par,
    );
    if (status != 0) return null;
    return PricingOutputs(up.value, par.value);
  } finally {
    calloc.free(up);
    calloc.free(par);
  }
}

const String _libName = 'icds_spike';

final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

final IcdsSpikeBindings _bindings = IcdsSpikeBindings(_dylib);
