// Hand-written FFI binding for the spike. Real plugin would use ffigen
// against the full ISDA header set; for spike validation a manual binding
// is faster to read.
// ignore_for_file: type=lint, unused_import
import 'dart:ffi' as ffi;

class IcdsSpikeBindings {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
  _lookup;

  IcdsSpikeBindings(ffi.DynamicLibrary dynamicLibrary)
    : _lookup = dynamicLibrary.lookup;

  IcdsSpikeBindings.fromLookup(
    ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup,
  ) : _lookup = lookup;

  /// JpmcdsDate(year, month, day) → TDate. Returns -1 on failure.
  int jpmcdsDate(int year, int month, int day) =>
      _jpmcdsDate(year, month, day);

  late final _jpmcdsDatePtr = _lookup<
    ffi.NativeFunction<ffi.Int64 Function(ffi.Int64, ffi.Int64, ffi.Int64)>
  >('icds_spike_jpmcds_date');
  late final _jpmcdsDate =
      _jpmcdsDatePtr.asFunction<int Function(int, int, int)>();

  /// Full SNAC upfront-charge calculation. Returns 0 on success and writes
  /// the upfront fraction to [out]. Returns -1 on any failure.
  int upfront({
    required int todayYear,
    required int todayMonth,
    required int todayDay,
    required int startYear,
    required int startMonth,
    required int startDay,
    required int endYear,
    required int endMonth,
    required int endDay,
    required int settleYear,
    required int settleMonth,
    required int settleDay,
    required double couponBp,
    required double parSpreadBp,
    required double recoveryRate,
    required double discountRate,
    required ffi.Pointer<ffi.Double> out,
  }) =>
      _upfront(
        todayYear, todayMonth, todayDay,
        startYear, startMonth, startDay,
        endYear, endMonth, endDay,
        settleYear, settleMonth, settleDay,
        couponBp, parSpreadBp, recoveryRate, discountRate,
        out,
      );

  late final _upfrontPtr = _lookup<
    ffi.NativeFunction<
      ffi.Int64 Function(
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Double, ffi.Double, ffi.Double, ffi.Double,
        ffi.Pointer<ffi.Double>,
      )
    >
  >('icds_spike_upfront');
  late final _upfront = _upfrontPtr.asFunction<
    int Function(
      int, int, int,
      int, int, int,
      int, int, int,
      int, int, int,
      double, double, double, double,
      ffi.Pointer<ffi.Double>,
    )
  >();

  /// Full pricing — returns both upfront fraction and back-calculated par
  /// spread (basis points) in a single C call. Returns 0 on success.
  int price({
    required int todayYear,
    required int todayMonth,
    required int todayDay,
    required int startYear,
    required int startMonth,
    required int startDay,
    required int endYear,
    required int endMonth,
    required int endDay,
    required int settleYear,
    required int settleMonth,
    required int settleDay,
    required double couponBp,
    required double parSpreadBp,
    required double recoveryRate,
    required double discountRate,
    required ffi.Pointer<ffi.Double> upfrontOut,
    required ffi.Pointer<ffi.Double> parSpreadOut,
  }) =>
      _price(
        todayYear, todayMonth, todayDay,
        startYear, startMonth, startDay,
        endYear, endMonth, endDay,
        settleYear, settleMonth, settleDay,
        couponBp, parSpreadBp, recoveryRate, discountRate,
        upfrontOut, parSpreadOut,
      );

  late final _pricePtr = _lookup<
    ffi.NativeFunction<
      ffi.Int64 Function(
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Double, ffi.Double, ffi.Double, ffi.Double,
        ffi.Pointer<ffi.Double>,
        ffi.Pointer<ffi.Double>,
      )
    >
  >('icds_spike_price');
  late final _price = _pricePtr.asFunction<
    int Function(
      int, int, int,
      int, int, int,
      int, int, int,
      int, int, int,
      double, double, double, double,
      ffi.Pointer<ffi.Double>,
      ffi.Pointer<ffi.Double>,
    )
  >();

  /// Shaped-curve pricing — builds an IR zero curve from deposits + swaps,
  /// then prices a CDS against it. Used by the QuantLib / ISDA RFR
  /// reference grids. Returns 0 on success.
  int priceWithCurve({
    required int nInstr,
    required ffi.Pointer<ffi.Char> instrTypes,
    required ffi.Pointer<ffi.Char> instrTenors,
    required ffi.Pointer<ffi.Double> instrRates,
    required int curveYear,
    required int curveMonth,
    required int curveDay,
    required int tradeYear,
    required int tradeMonth,
    required int tradeDay,
    required int settleYear,
    required int settleMonth,
    required int settleDay,
    required int stepinYear,
    required int stepinMonth,
    required int stepinDay,
    required int startYear,
    required int startMonth,
    required int startDay,
    required int endYear,
    required int endMonth,
    required int endDay,
    required int mmDcc,
    required int fixedSwapFreq,
    required int floatSwapFreq,
    required int fixedSwapDcc,
    required int floatSwapDcc,
    required double couponBp,
    required double parSpreadBp,
    required double recoveryRate,
    required int isPriceClean,
    required ffi.Pointer<ffi.Double> upfrontOut,
    required ffi.Pointer<ffi.Double> parSpreadOut,
  }) =>
      _priceWithCurve(
        nInstr,
        instrTypes,
        instrTenors,
        instrRates,
        curveYear, curveMonth, curveDay,
        tradeYear, tradeMonth, tradeDay,
        settleYear, settleMonth, settleDay,
        stepinYear, stepinMonth, stepinDay,
        startYear, startMonth, startDay,
        endYear, endMonth, endDay,
        mmDcc, fixedSwapFreq, floatSwapFreq, fixedSwapDcc, floatSwapDcc,
        couponBp, parSpreadBp, recoveryRate, isPriceClean,
        upfrontOut, parSpreadOut,
      );

  late final _priceWithCurvePtr = _lookup<
    ffi.NativeFunction<
      ffi.Int64 Function(
        ffi.Int64,
        ffi.Pointer<ffi.Char>,
        ffi.Pointer<ffi.Char>,
        ffi.Pointer<ffi.Double>,
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Int64, ffi.Int64, ffi.Int64,
        ffi.Int64,
        ffi.Int64, ffi.Int64,
        ffi.Int64, ffi.Int64,
        ffi.Double, ffi.Double, ffi.Double,
        ffi.Int64,
        ffi.Pointer<ffi.Double>,
        ffi.Pointer<ffi.Double>,
      )
    >
  >('icds_spike_price_with_curve');
  late final _priceWithCurve = _priceWithCurvePtr.asFunction<
    int Function(
      int,
      ffi.Pointer<ffi.Char>,
      ffi.Pointer<ffi.Char>,
      ffi.Pointer<ffi.Double>,
      int, int, int,
      int, int, int,
      int, int, int,
      int, int, int,
      int, int, int,
      int, int, int,
      int,
      int, int,
      int, int,
      double, double, double,
      int,
      ffi.Pointer<ffi.Double>,
      ffi.Pointer<ffi.Double>,
    )
  >();
}
