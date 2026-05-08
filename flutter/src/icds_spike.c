#include "icds_spike.h"
#include <string.h>

// ISDA CDS Standard Model headers. CMakeLists.txt adds
// isdamodel/include/isda to the include path so these resolve.
#include "dateconv.h"
#include "cdsone.h"
#include "tcurve.h"
#include "convert.h"
#include "ldate.h"
#include "busday.h"
#include "yearfrac.h"

int64_t icds_spike_jpmcds_date(int64_t year, int64_t month, int64_t day) {
    TDate result = JpmcdsDate((long)year, (long)month, (long)day);
    return (int64_t)result;
}

int64_t icds_spike_upfront(
    int64_t  todayYear, int64_t  todayMonth, int64_t  todayDay,
    int64_t  startYear, int64_t  startMonth, int64_t  startDay,
    int64_t  endYear,   int64_t  endMonth,   int64_t  endDay,
    int64_t  settleYear,int64_t  settleMonth,int64_t  settleDay,
    double   couponBp,
    double   parSpreadBp,
    double   recoveryRate,
    double   discountRate,
    double  *upfrontFractionOut)
{
    if (!upfrontFractionOut) return -1;
    *upfrontFractionOut = 0.0;

    TDate today      = JpmcdsDate((long)todayYear,  (long)todayMonth,  (long)todayDay);
    TDate valueDate  = JpmcdsDate((long)settleYear, (long)settleMonth, (long)settleDay);
    TDate startDate  = JpmcdsDate((long)startYear,  (long)startMonth,  (long)startDay);
    TDate endDate    = JpmcdsDate((long)endYear,    (long)endMonth,    (long)endDay);
    TDate stepinDate = today + 1;
    TDate benchStart = startDate;

    if (today == FAILURE || valueDate == FAILURE ||
        startDate == FAILURE || endDate == FAILURE) {
        return -1;
    }

    // Flat 30y continuous discount curve, mirroring CDSCalculator.swift.
    TDate  curveEnd = today + 10957;
    double flatRate = discountRate;
    TCurve *discCurve = JpmcdsMakeTCurve(today, &curveEnd, &flatRate, 1,
                                         (double)JPMCDS_CONTINUOUS_BASIS,
                                         JPMCDS_ACT_365F);
    if (!discCurve) return -1;

    TDateInterval ivl;
    memset(&ivl, 0, sizeof(ivl));
    ivl.prd     = 3;
    ivl.prd_typ = (char)'M';
    ivl.flag    = 0;

    TStubMethod stub;
    memset(&stub, 0, sizeof(stub));
    stub.stubAtEnd = 0;
    stub.longStub  = 0;

    char *cal_str = strdup("None");
    if (!cal_str) {
        JpmcdsFreeTCurve(discCurve);
        return -1;
    }

    double upfrontFraction = 0.0;
    int status = JpmcdsCdsoneUpfrontCharge(
        today, valueDate, benchStart, stepinDate,
        startDate, endDate,
        couponBp / 10000.0,
        1,                                  // payAccruedOnDefault
        &ivl, &stub,
        JPMCDS_ACT_360,
        (long)'F',                          // FOLLOW bad-day
        cal_str,
        discCurve,
        parSpreadBp / 10000.0,
        recoveryRate,
        1,                                  // payAccruedAtStart (clean)
        &upfrontFraction);

    free(cal_str);
    JpmcdsFreeTCurve(discCurve);

    if (status != SUCCESS) return -1;

    *upfrontFractionOut = upfrontFraction;
    return 0;
}

int64_t icds_spike_price(
    int64_t  todayYear, int64_t  todayMonth, int64_t  todayDay,
    int64_t  startYear, int64_t  startMonth, int64_t  startDay,
    int64_t  endYear,   int64_t  endMonth,   int64_t  endDay,
    int64_t  settleYear,int64_t  settleMonth,int64_t  settleDay,
    double   couponBp,
    double   parSpreadBp,
    double   recoveryRate,
    double   discountRate,
    double  *upfrontFractionOut,
    double  *parSpreadBpOut)
{
    if (!upfrontFractionOut || !parSpreadBpOut) return -1;
    *upfrontFractionOut = 0.0;
    *parSpreadBpOut = 0.0;

    TDate today      = JpmcdsDate((long)todayYear,  (long)todayMonth,  (long)todayDay);
    TDate valueDate  = JpmcdsDate((long)settleYear, (long)settleMonth, (long)settleDay);
    TDate startDate  = JpmcdsDate((long)startYear,  (long)startMonth,  (long)startDay);
    TDate endDate    = JpmcdsDate((long)endYear,    (long)endMonth,    (long)endDay);
    TDate stepinDate = today + 1;
    TDate benchStart = startDate;

    if (today == FAILURE || valueDate == FAILURE ||
        startDate == FAILURE || endDate == FAILURE) {
        return -1;
    }

    TDate  curveEnd = today + 10957;
    double flatRate = discountRate;
    TCurve *discCurve = JpmcdsMakeTCurve(today, &curveEnd, &flatRate, 1,
                                         (double)JPMCDS_CONTINUOUS_BASIS,
                                         JPMCDS_ACT_365F);
    if (!discCurve) return -1;

    TDateInterval ivl;
    memset(&ivl, 0, sizeof(ivl));
    ivl.prd     = 3;
    ivl.prd_typ = (char)'M';
    ivl.flag    = 0;

    TStubMethod stub;
    memset(&stub, 0, sizeof(stub));
    stub.stubAtEnd = 0;
    stub.longStub  = 0;

    char *cal_str = strdup("None");
    if (!cal_str) {
        JpmcdsFreeTCurve(discCurve);
        return -1;
    }

    double upfrontFraction = 0.0;
    int status = JpmcdsCdsoneUpfrontCharge(
        today, valueDate, benchStart, stepinDate,
        startDate, endDate,
        couponBp / 10000.0, 1, &ivl, &stub,
        JPMCDS_ACT_360, (long)'F',
        cal_str, discCurve,
        parSpreadBp / 10000.0,
        recoveryRate, 1,
        &upfrontFraction);

    if (status != SUCCESS) {
        free(cal_str);
        JpmcdsFreeTCurve(discCurve);
        return -1;
    }

    double parOut = 0.0;
    JpmcdsCdsoneSpread(
        today, valueDate, benchStart, stepinDate,
        startDate, endDate,
        couponBp / 10000.0, 1, &ivl, &stub,
        JPMCDS_ACT_360, (long)'F',
        cal_str, discCurve,
        upfrontFraction, recoveryRate, 1,
        &parOut);

    free(cal_str);
    JpmcdsFreeTCurve(discCurve);

    *upfrontFractionOut = upfrontFraction;
    *parSpreadBpOut     = parOut * 10000.0;
    return 0;
}

// === Shaped-curve pricing (IR zero curve from deposits + swaps) ===

#include "zerocurve.h"  // JpmcdsBuildIRZeroCurve

int64_t icds_spike_price_with_curve(
    int64_t       nInstr,
    const char   *instrTypes,
    const char   *instrTenors,
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
    int64_t       isPriceClean,
    double       *upfrontFractionOut,
    double       *parSpreadBpOut)
{
    if (!upfrontFractionOut || !parSpreadBpOut) return -1;
    *upfrontFractionOut = 0.0;
    *parSpreadBpOut = 0.0;
    if (nInstr <= 0 || !instrTypes || !instrTenors || !instrRates) return -1;

    TDate curveValueDate = JpmcdsDate((long)curveYear, (long)curveMonth, (long)curveDay);
    TDate tradeDate      = JpmcdsDate((long)tradeYear, (long)tradeMonth, (long)tradeDay);
    TDate valueDate      = JpmcdsDate((long)settleYear, (long)settleMonth, (long)settleDay);
    TDate stepinDate     = JpmcdsDate((long)stepinYear, (long)stepinMonth, (long)stepinDay);
    TDate startDate      = JpmcdsDate((long)startYear, (long)startMonth, (long)startDay);
    TDate endDate        = JpmcdsDate((long)endYear,   (long)endMonth,   (long)endDay);
    if (curveValueDate == FAILURE || tradeDate == FAILURE ||
        valueDate == FAILURE || stepinDate == FAILURE ||
        startDate == FAILURE || endDate == FAILURE) {
        return -1;
    }

    // Materialize tenor pointers from the null-separated string blob.
    const char **tenorPtrs = (const char **)malloc((size_t)nInstr * sizeof(char *));
    if (!tenorPtrs) return -1;
    {
        const char *p = instrTenors;
        for (int64_t i = 0; i < nInstr; i++) {
            tenorPtrs[i] = p;
            p += strlen(p) + 1;  // skip past the null terminator
        }
    }

    // Convert each tenor string to a TDate (forward + adjust under "None")
    char *cal = strdup("None");
    char *routine = strdup("spike");
    if (!cal || !routine) {
        free(cal); free(routine); free(tenorPtrs);
        return -1;
    }
    TDate *dates = (TDate *)malloc((size_t)nInstr * sizeof(TDate));
    if (!dates) {
        free(cal); free(routine); free(tenorPtrs);
        return -1;
    }
    for (int64_t i = 0; i < nInstr; i++) {
        TDateInterval ivl;
        memset(&ivl, 0, sizeof(ivl));
        if (JpmcdsStringToDateInterval((char *)tenorPtrs[i], routine, &ivl) != SUCCESS) {
            free(cal); free(routine); free(tenorPtrs); free(dates);
            return -1;
        }
        if (JpmcdsDateFwdThenAdjust(curveValueDate, &ivl,
                                     (long)'N',  // bad-day convention NONE for tenor build
                                     cal, &dates[i]) != SUCCESS) {
            free(cal); free(routine); free(tenorPtrs); free(dates);
            return -1;
        }
    }

    TCurve *curve = JpmcdsBuildIRZeroCurve(
        curveValueDate,
        (char *)instrTypes,
        dates,
        (double *)instrRates,
        (long)nInstr,
        (long)mmDcc,
        (long)fixedSwapFreq,
        (long)floatSwapFreq,
        (long)fixedSwapDcc,
        (long)floatSwapDcc,
        (long)'M',  // modified-following bad-day for swap dates
        cal);

    if (!curve) {
        free(cal); free(routine); free(tenorPtrs); free(dates);
        return -1;
    }

    TDateInterval payIvl; memset(&payIvl, 0, sizeof(payIvl));
    payIvl.prd = 3; payIvl.prd_typ = (char)'M'; payIvl.flag = 0;
    TStubMethod stub; memset(&stub, 0, sizeof(stub));
    stub.stubAtEnd = 0; stub.longStub = 0;

    double upfrontFraction = 0.0;
    int status = JpmcdsCdsoneUpfrontCharge(
        tradeDate, valueDate, startDate, stepinDate,
        startDate, endDate,
        couponBp / 10000.0, 1, &payIvl, &stub,
        JPMCDS_ACT_360, (long)'F',
        cal, curve,
        parSpreadBp / 10000.0,
        recoveryRate, (int)isPriceClean,
        &upfrontFraction);

    double parOut = 0.0;
    if (status == SUCCESS) {
        JpmcdsCdsoneSpread(
            tradeDate, valueDate, startDate, stepinDate,
            startDate, endDate,
            couponBp / 10000.0, 1, &payIvl, &stub,
            JPMCDS_ACT_360, (long)'F',
            cal, curve,
            upfrontFraction, recoveryRate, (int)isPriceClean,
            &parOut);
    }

    JpmcdsFreeTCurve(curve);
    free(cal); free(routine); free(tenorPtrs); free(dates);

    if (status != SUCCESS) return -1;
    *upfrontFractionOut = upfrontFraction;
    *parSpreadBpOut     = parOut * 10000.0;
    return 0;
}
