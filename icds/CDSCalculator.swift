//
//  CDSCalculator.swift
//  icds
//
//  Copyright © 2024 Strategic Software Engineering LLC. All rights reserved.
//

import Foundation

struct CDSResult {
    let upfrontFraction: Double  // fraction of notional (signed: + = buyer pays)
    let upfrontDollars: Double
    let upfrontBp: Double
    let price: Double            // clean price (100 - upfront%)
    let accrued: Double          // accrued interest in dollars
    let parSpreadBp: Double      // flat spread that gives zero upfront
    let startDate: TDate
    let valueDate: TDate
    let endDate: TDate
}

struct CDSCalculator {

    // Next IMM date (20th of Mar/Jun/Sep/Dec) at or after the given date
    static func nextIMMDate(after date: Date) -> TDate {
        let cal = Calendar.current
        let year  = cal.component(.year,  from: date)
        let month = cal.component(.month, from: date)
        let day   = cal.component(.day,   from: date)
        for m in [3, 6, 9, 12] {
            if month < m || (month == m && day < 20) {
                return JpmcdsDate(year, m, 20)
            }
        }
        return JpmcdsDate(year + 1, 3, 20)
    }

    // Previous IMM date (20th of Mar/Jun/Sep/Dec) before the given date
    static func prevIMMDate(before date: Date) -> Date {
        let cal = Calendar.current
        var year  = cal.component(.year,  from: date)
        let month = cal.component(.month, from: date)
        let day   = cal.component(.day,   from: date)
        for m in [12, 9, 6, 3].reversed() {
            if month > m || (month == m && day >= 20) {
                var dc = DateComponents(); dc.year = year; dc.month = m; dc.day = 20
                return cal.date(from: dc) ?? date
            }
        }
        year -= 1
        var dc = DateComponents(); dc.year = year; dc.month = 12; dc.day = 20
        return cal.date(from: dc) ?? date
    }

    static func tdate(from date: Date) -> TDate {
        let cal = Calendar.current
        return JpmcdsDate(
            cal.component(.year,  from: date),
            cal.component(.month, from: date),
            cal.component(.day,   from: date))
    }

    // Main calculation entry point
    static func calculate(tradeDate: Date,
                          tenorYears: Int,
                          parSpreadBp: Double,
                          couponBp: Double,
                          recoveryRate: Double,
                          notional: Double,
                          isBuy: Bool) -> CDSResult? {

        let cal = Calendar.current
        let today      = tdate(from: tradeDate)
        let valueDate  = today + 1
        let stepinDate = today + 1
        let benchStart = today
        let startDate  = today

        guard let matDate = cal.date(byAdding: .year, value: tenorYears, to: tradeDate) else { return nil }
        let endDate = nextIMMDate(after: matDate)

        // Flat 4.5% continuous discount curve (~30 years)
        var curveEnd  = today + 10957
        var flatRate  = 0.045
        guard let discCurve = JpmcdsMakeTCurve(today, &curveEnd, &flatRate, 1,
                                               Double(JPMCDS_CONTINUOUS_BASIS),
                                               JPMCDS_ACT_365F) else { return nil }
        defer { JpmcdsFreeTCurve(discCurve) }

        var ivl = TDateInterval()
        ivl.prd      = 3
        ivl.prd_typ  = Int8(bitPattern: UInt8(ascii: "M"))
        ivl.flag     = 0

        var stub = TStubMethod()
        stub.stubAtEnd  = 0
        stub.longStub   = 0

        let cal_str = strdup("None")
        defer { free(cal_str) }

        var upfrontFraction = 0.0
        let status = JpmcdsCdsoneUpfrontCharge(
            today, valueDate, benchStart, stepinDate,
            startDate, endDate,
            couponBp / 10000.0, 1,
            &ivl, &stub,
            JPMCDS_ACT_360, Int(UInt8(ascii: "F")),
            cal_str, discCurve,
            parSpreadBp / 10000.0,
            recoveryRate, 0,
            &upfrontFraction
        )
        guard status == SUCCESS else { return nil }

        let signed       = isBuy ? upfrontFraction : -upfrontFraction
        let dollars      = signed * notional
        let bp           = signed * 10_000.0
        let price        = (1.0 - signed) * 100.0

        let prevIMM      = prevIMMDate(before: tradeDate)
        let accrualDays  = Double(today - tdate(from: prevIMM))
        let accrued      = (couponBp / 10_000.0) * (accrualDays / 360.0) * notional

        var parOut = 0.0
        JpmcdsCdsoneSpread(
            today, valueDate, benchStart, stepinDate,
            startDate, endDate,
            couponBp / 10000.0, 1, &ivl, &stub,
            JPMCDS_ACT_360, Int(UInt8(ascii: "F")),
            cal_str, discCurve,
            0.0, recoveryRate, 0,
            &parOut
        )

        return CDSResult(
            upfrontFraction: signed,
            upfrontDollars:  dollars,
            upfrontBp:       bp,
            price:           price,
            accrued:         accrued,
            parSpreadBp:     parOut * 10_000.0,
            startDate:       startDate,
            valueDate:       valueDate,
            endDate:         endDate
        )
    }
}
