#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

// Spike entry #1: thin date-conversion wrapper around JpmcdsDate. Returns
// the TDate (= long, days since 1601-01-01) for a calendar date, or -1
// (= JPMCDS_FAILURE) for an invalid date.
FFI_PLUGIN_EXPORT int64_t icds_spike_jpmcds_date(int64_t year,
                                                 int64_t month,
                                                 int64_t day);

// Spike entry #2: end-to-end CDS upfront-fee calculation. Wraps
// JpmcdsCdsoneUpfrontCharge with all the SNAC plumbing (flat 30-year
// continuous discount curve, quarterly schedule, ACT/360, FOLLOW bad-day,
// "None" holiday calendar) so Dart only passes primitive doubles/ints
// through FFI. Mirrors the logic in icds/CDSCalculator.swift.
//
// Returns 0 on success, -1 on failure. On success, *upfrontFractionOut
// receives the upfront charge as a fraction of notional (positive ⇒ buyer
// pays seller).
FFI_PLUGIN_EXPORT int64_t icds_spike_upfront(
    int64_t  todayYear, int64_t  todayMonth, int64_t  todayDay,
    int64_t  startYear, int64_t  startMonth, int64_t  startDay, // benchStart = startDate
    int64_t  endYear,   int64_t  endMonth,   int64_t  endDay,
    int64_t  settleYear,int64_t  settleMonth,int64_t  settleDay,
    double   couponBp,
    double   parSpreadBp,
    double   recoveryRate,
    double   discountRate,
    double  *upfrontFractionOut);

// Spike entry #3: full pricing — same plumbing as #2, but also runs the
// inverse `JpmcdsCdsoneSpread` so we can show the rounded-trip par
// spread alongside the upfront. On success, *upfrontFractionOut and
// *parSpreadBpOut both receive results.
FFI_PLUGIN_EXPORT int64_t icds_spike_price(
    int64_t  todayYear, int64_t  todayMonth, int64_t  todayDay,
    int64_t  startYear, int64_t  startMonth, int64_t  startDay,
    int64_t  endYear,   int64_t  endMonth,   int64_t  endDay,
    int64_t  settleYear,int64_t  settleMonth,int64_t  settleDay,
    double   couponBp,
    double   parSpreadBp,
    double   recoveryRate,
    double   discountRate,
    double  *upfrontFractionOut,
    double  *parSpreadBpOut);

// Spike entry #4: build a shaped IR zero curve from deposits + swaps,
// then price a CDS against it. Used by the QuantLib / ISDA RFR
// reference tests where the discount curve is *not* flat. All inputs
// are passed as flat C arrays to keep FFI primitive-only.
//
//   nInstr            — total number of instruments (deposits + swaps)
//   instrTypes        — string of length nInstr, one char per instr:
//                       'M' = money market deposit, 'S' = swap
//   instrTenors       — concatenated tenor strings, separated by '\0'
//                       (e.g. "1M\02M\03M\0...\01Y\0..."). Total length
//                       summed across the nInstr null-separated strings.
//   instrRates        — array of nInstr doubles, decimal rates
//   curveValueDate*   — the curve's reference date (T+1 biz typically)
//   tradeDate*, valueDate* (settle), startDate*, endDate*
//   mmDcc             — JPMCDS_ACT_360 (3) | JPMCDS_ACT_365F (2)
//   fixedSwapFreq     — usually 1 for OIS, 2 for semi-annual fixed leg
//   floatSwapFreq     — usually 1 for OIS, 4 for quarterly floating leg
//   fixedSwapDcc, floatSwapDcc — same DCC codes as mmDcc
//
// Returns 0 on success, -1 on failure. Writes the upfront fraction
// AND the back-calculated par spread (basis points) on success.
FFI_PLUGIN_EXPORT int64_t icds_spike_price_with_curve(
    int64_t       nInstr,
    const char   *instrTypes,
    const char   *instrTenors,    // null-separated, nInstr strings concatenated
    const double *instrRates,
    int64_t       curveYear, int64_t curveMonth, int64_t curveDay,
    int64_t       tradeYear, int64_t tradeMonth, int64_t tradeDay,
    int64_t       settleYear,int64_t settleMonth,int64_t settleDay,
    int64_t       stepinYear,int64_t stepinMonth,int64_t stepinDay,
    int64_t       startYear, int64_t startMonth, int64_t startDay,
    int64_t       endYear,   int64_t endMonth,   int64_t endDay,
    int64_t       mmDcc,
    int64_t       fixedSwapFreq,
    int64_t       floatSwapFreq,
    int64_t       fixedSwapDcc,
    int64_t       floatSwapDcc,
    double        couponBp,
    double        parSpreadBp,
    double        recoveryRate,
    int64_t       isPriceClean,        // 1 = clean (ISDA grid), 0 = dirty (QuantLib)
    double       *upfrontFractionOut,
    double       *parSpreadBpOut);
