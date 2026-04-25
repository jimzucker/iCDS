//
//  CDSCalculator.swift
//  icds
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
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

    // Previous IMM date (20th of Mar/Jun/Sep/Dec) on or before the given date
    static func prevIMMDate(before date: Date) -> Date {
        let cal = Calendar.current
        var year  = cal.component(.year,  from: date)
        let month = cal.component(.month, from: date)
        let day   = cal.component(.day,   from: date)
        for m in [12, 9, 6, 3] {
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

    // Most recent business day on or before `date` for the given region calendar.
    // Uses CDSHolidayCalendar — call from an async Task at app launch to avoid
    // blocking the main thread on first-time Calendar stack initialisation.
    static func lastValidTradeDate(on date: Date = Date(), calendarName: String = "nyFed") -> Date {
        CDSHolidayCalendar.prevBusinessDay(date, calendarName: calendarName)
    }

    // Advance by n business days using the region's holiday calendar
    static func addBusinessDays(_ n: Int, to date: Date, calendarName: String = "nyFed") -> Date {
        CDSHolidayCalendar.addBusinessDays(n, to: date, calendarName: calendarName)
    }

    static func calculate(tradeDate: Date,
                          tenorYears: Int,
                          parSpreadBp: Double,
                          couponBp: Double,
                          recoveryRate: Double,
                          notional: Double,
                          isBuy: Bool,
                          settleDays: Int = 1,
                          calendarName: String = "nyFed",
                          discountRate: Double = SOFRFetcher.fallbackRate,
                          minSettle: Date? = nil) -> CDSResult? {

        let cal        = Calendar.current
        let today      = tdate(from: tradeDate)
        // Settle = T + settleDays business days, but clamped to >= minSettle when supplied
        // (e.g., 'today') because real-world settlement cannot fall in the past.
        let computedSettle = addBusinessDays(settleDays, to: tradeDate, calendarName: calendarName)
        let effectiveSettle = (minSettle.map { max(computedSettle, $0) }) ?? computedSettle
        let valueDate  = tdate(from: effectiveSettle)
        let stepinDate = today + 1                                         // T+1 calendar day
        let prevIMM    = prevIMMDate(before: tradeDate)
        let startDate  = tdate(from: prevIMM)                              // SNAC: coupon accrues from previous IMM
        let benchStart = startDate                                         // benchmark uses same start as contract (SNAC)

        guard let matDate = cal.date(byAdding: .year, value: tenorYears, to: tradeDate) else { return nil }
        let endDate = nextIMMDate(after: matDate)

        // Flat continuous discount curve (~30 years), rate supplied by caller (live SOFR or fallback)
        var curveEnd  = today + 10957
        var flatRate  = discountRate
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
            recoveryRate, 1,                                               // isPriceClean=1 (ex-accrued)
            &upfrontFraction
        )
        guard status == SUCCESS else { return nil }

        let signed       = isBuy ? upfrontFraction : -upfrontFraction
        let dollars      = signed * notional
        let bp           = signed * 10_000.0
        let price        = (1.0 - signed) * 100.0

        // Accrued shown separately: days from previous IMM to stepinDate
        // (T+1 calendar) × coupon. SNAC convention: accrued endpoint is
        // stepinDate, not the trade date. The C library uses stepinDate
        // internally too — see the call to JpmcdsCdsoneUpfrontCharge above.
        let accrualDays  = Double(stepinDate - startDate)
        let accrued      = (couponBp / 10_000.0) * (accrualDays / 360.0) * notional

        // Back-calculate par spread from the actual clean upfront → round-trip of input spread
        var parOut = 0.0
        JpmcdsCdsoneSpread(
            today, valueDate, benchStart, stepinDate,
            startDate, endDate,
            couponBp / 10000.0, 1, &ivl, &stub,
            JPMCDS_ACT_360, Int(UInt8(ascii: "F")),
            cal_str, discCurve,
            upfrontFraction, recoveryRate, 1,                              // isPriceClean=1
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

// MARK: - CDS Holiday Calendars
//
// Industry sources:
//   NA/EM/Asia/LCDS — US Federal Reserve: federalreserve.gov/aboutthefed/k8.htm
//   EU              — ECB TARGET/T2: ecb.europa.eu/paym/target/target2/profuse/calendar
//   Japan           — TSE/JPX calendar: jpx.co.jp/english/corporate/investor-relations/ir-library/market-holiday
//   AUS             — ASX / NSW public holidays
//
// Note: The ISDA C library uses "None" calendar (weekends only) for bad-day adjustment
// of cash-flow dates, which is a standard approximation. These Swift-side calendars
// are used for trade-date defaulting and settle-date arithmetic only.

struct CDSHolidayCalendar {

    // Touch all four sets on a background thread so they're ready before
    // the user changes region. Call once at app start via Task.detached.
    static func prewarmAll() {
        _ = nyFedSet; _ = targetSet; _ = tokyoSet; _ = sydneySet
    }

    static func prevBusinessDay(_ date: Date, calendarName: String) -> Date {
        var d = date
        while !isBusinessDay(d, calendarName: calendarName) {
            d = Calendar.current.date(byAdding: .day, value: -1, to: d)!
        }
        return d
    }

    static func addBusinessDays(_ n: Int, to date: Date, calendarName: String) -> Date {
        var result = date
        var count  = 0
        while count < n {
            result = Calendar.current.date(byAdding: .day, value: 1, to: result)!
            if isBusinessDay(result, calendarName: calendarName) { count += 1 }
        }
        return result
    }

    static func isBusinessDay(_ date: Date, calendarName: String) -> Bool {
        guard !Calendar.current.isDateInWeekend(date) else { return false }
        return !isHoliday(date, calendarName: calendarName)
    }

    private static func isHoliday(_ date: Date, calendarName: String) -> Bool {
        let key = dayInt(date)
        switch calendarName {
        case "target": return targetSet.contains(key)
        case "tokyo":  return tokyoSet.contains(key)
        case "sydney": return sydneySet.contains(key)
        default:       return nyFedSet.contains(key)  // nyFed, and fallback
        }
    }

    // Encode a Date as YYYYMMDD integer for O(1) Set lookup
    private static func dayInt(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 0) * 10000 + (c.month ?? 0) * 100 + (c.day ?? 0)
    }

    private static func makeDate(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents(); c.year = y; c.month = m; c.day = d
        return Calendar.current.date(from: c)!
    }

    // US Saturday→Friday, Sunday→Monday observed holiday
    private static func usObserved(_ date: Date) -> Date {
        switch Calendar.current.component(.weekday, from: date) {
        case 7: return Calendar.current.date(byAdding: .day, value: -1, to: date)!  // Sat→Fri
        case 1: return Calendar.current.date(byAdding: .day, value:  1, to: date)!  // Sun→Mon
        default: return date
        }
    }

    // Nth weekday of a month (e.g., 3rd Monday = nthWeekday(3, weekday:2, month:1, year:2024))
    // Swift Calendar weekday: 1=Sun 2=Mon 3=Tue 4=Wed 5=Thu 6=Fri 7=Sat
    private static func nthWeekday(_ n: Int, weekday: Int, month: Int, year: Int) -> Date {
        let first = makeDate(year, month, 1)
        let firstWD = Calendar.current.component(.weekday, from: first)
        var offset = weekday - firstWD; if offset < 0 { offset += 7 }
        offset += (n - 1) * 7
        return Calendar.current.date(byAdding: .day, value: offset, to: first)!
    }

    // Last occurrence of `weekday` in `month`
    private static func lastWeekday(_ weekday: Int, month: Int, year: Int) -> Date {
        var c = DateComponents(); c.year = year; c.month = month + 1; c.day = 0
        let last = Calendar.current.date(from: c)!
        let lastWD = Calendar.current.component(.weekday, from: last)
        var offset = lastWD - weekday; if offset < 0 { offset += 7 }
        return Calendar.current.date(byAdding: .day, value: -offset, to: last)!
    }

    // Easter Sunday — Anonymous Gregorian algorithm
    private static func easter(_ year: Int) -> Date {
        let a = year % 19, b = year / 100, c = year % 100
        let d = b / 4,  e = b % 4,  f = (b + 8) / 25,  g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4,  k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let mo = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * mo + 114) / 31
        let day   = (h + l - 7 * mo + 114) % 31 + 1
        return makeDate(year, month, day)
    }

    private static func addDays(_ n: Int, to d: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: n, to: d)!
    }

    // MARK: - Lazy holiday sets (computed once per calendar type)

    private static let nyFedSet:  Set<Int> = buildNYFed()
    private static let targetSet: Set<Int> = buildTarget()
    private static let tokyoSet:  Set<Int> = buildTokyo()
    private static let sydneySet: Set<Int> = buildSydney()

    private static func buildNYFed() -> Set<Int> {
        var s = Set<Int>()
        for y in 2024...2030 {
            // Fixed (adjusted to nearest weekday per US convention)
            [makeDate(y,1,1), makeDate(y,6,19), makeDate(y,7,4),
             makeDate(y,11,11), makeDate(y,12,25)].forEach { s.insert(dayInt(usObserved($0))) }
            // Floating
            s.insert(dayInt(nthWeekday(3, weekday:2, month:1,  year:y)))  // MLK Day
            s.insert(dayInt(nthWeekday(3, weekday:2, month:2,  year:y)))  // Presidents Day
            s.insert(dayInt(lastWeekday(2, month:5, year:y)))              // Memorial Day
            s.insert(dayInt(nthWeekday(1, weekday:2, month:9,  year:y)))  // Labor Day
            s.insert(dayInt(nthWeekday(2, weekday:2, month:10, year:y)))  // Columbus Day
            s.insert(dayInt(nthWeekday(4, weekday:5, month:11, year:y)))  // Thanksgiving
        }
        return s
    }

    private static func buildTarget() -> Set<Int> {
        var s = Set<Int>()
        for y in 2024...2030 {
            let e = easter(y)
            s.insert(dayInt(makeDate(y, 1,  1)))   // New Year's Day
            s.insert(dayInt(addDays(-2, to: e)))    // Good Friday
            s.insert(dayInt(addDays( 1, to: e)))    // Easter Monday
            s.insert(dayInt(makeDate(y, 5,  1)))   // Labour Day
            s.insert(dayInt(makeDate(y, 12, 25)))  // Christmas Day
            s.insert(dayInt(makeDate(y, 12, 26)))  // Boxing Day
        }
        return s
    }

    private static func buildTokyo() -> Set<Int> {
        var s = Set<Int>()
        for y in 2024...2030 {
            // Fixed national holidays
            [makeDate(y,1,1), makeDate(y,2,11), makeDate(y,2,23),
             makeDate(y,4,29), makeDate(y,5,3), makeDate(y,5,4), makeDate(y,5,5),
             makeDate(y,8,11), makeDate(y,11,3), makeDate(y,11,23),
             makeDate(y,12,31)].forEach { s.insert(dayInt($0)) }
            // Floating (TSE calendar uses substitute holiday rule — simplified here)
            s.insert(dayInt(nthWeekday(2, weekday:2, month:1,  year:y)))  // Coming of Age Day
            s.insert(dayInt(nthWeekday(3, weekday:2, month:7,  year:y)))  // Marine Day
            s.insert(dayInt(nthWeekday(3, weekday:2, month:9,  year:y)))  // Respect for the Aged Day
            s.insert(dayInt(nthWeekday(2, weekday:2, month:10, year:y)))  // Sports Day
            // Equinoxes (approximate — vary ±1 day per astronomical computation)
            s.insert(dayInt(makeDate(y, 3, 20)))   // Vernal Equinox
            s.insert(dayInt(makeDate(y, 9, 23)))   // Autumnal Equinox
        }
        return s
    }

    private static func buildSydney() -> Set<Int> {
        var s = Set<Int>()
        for y in 2024...2030 {
            let e = easter(y)
            // Australia Day: Jan 26 (Mon if on weekend)
            let jan26 = makeDate(y, 1, 26)
            let jan26WD = Calendar.current.component(.weekday, from: jan26)
            let ausDay: Date = {
                if jan26WD == 7 { return addDays(2, to: jan26) }  // Sat→Mon
                if jan26WD == 1 { return addDays(1, to: jan26) }  // Sun→Mon
                return jan26
            }()
            s.insert(dayInt(usObserved(makeDate(y, 1, 1))))   // New Year's Day
            s.insert(dayInt(ausDay))                            // Australia Day
            s.insert(dayInt(addDays(-2, to: e)))               // Good Friday
            s.insert(dayInt(addDays(-1, to: e)))               // Easter Saturday
            s.insert(dayInt(addDays( 1, to: e)))               // Easter Monday
            s.insert(dayInt(usObserved(makeDate(y, 4, 25))))  // ANZAC Day
            s.insert(dayInt(nthWeekday(2, weekday:2, month:6,  year:y)))  // King's Birthday (NSW)
            s.insert(dayInt(nthWeekday(1, weekday:2, month:8,  year:y)))  // Bank Holiday (NSW)
            s.insert(dayInt(nthWeekday(1, weekday:2, month:10, year:y)))  // Labour Day (NSW)
            s.insert(dayInt(usObserved(makeDate(y, 12, 25))))  // Christmas Day
            s.insert(dayInt(usObserved(makeDate(y, 12, 26))))  // Boxing Day
        }
        return s
    }
}
