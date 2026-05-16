//
//  ContentView.swift
//  icds
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FeeView()
                .tabItem { Label("Calc", image: "CalcTabbarIcon") }
            LiborView()
                .tabItem { Label("Curves", systemImage: "chart.line.uptrend.xyaxis") }
            InfoView()
                .tabItem { Label("Info", systemImage: "info.circle") }
            DiagnosticsView()
                .tabItem { Label("Diag", systemImage: "testtube.2") }
        }
        .accentColor(.orange)
    }
}

// MARK: - Diagnostics

/// In-app smoke test. Mirrors the Flutter port's DiagnosticsTab so both
/// platforms expose the same five checks: JpmcdsDate sanity, CDS pricing
/// at par / wide / tight, IMM helpers, regional holiday calendar, and
/// live RFR fetcher status.
struct DiagnosticsView: View {
    @ObservedObject private var store = SOFRRateStore.shared

    // === Test 1: JpmcdsDate sanity ===
    private let tdEpoch    = JpmcdsDate(1601, 1, 1)
    private let td2010     = JpmcdsDate(2010, 1, 4)
    private let tdInvalid  = JpmcdsDate(2024, 13, 99)
    private let oneDay     = JpmcdsDate(2026, 5, 5) - JpmcdsDate(2026, 5, 4)
    private var datesOk: Bool {
        tdEpoch != -1 && td2010 != -1 && tdInvalid == -1 && oneDay == 1
    }

    // === Test 2: CDSCalculator pricing ===
    private static let tradeDate = makeDate(2026, 5, 4)
    private let par   = CDSCalculator.calculate(tradeDate: tradeDate, tenorYears: 5,
        parSpreadBp: 100, couponBp: 100, recoveryRate: 0.40, notional: 10_000_000, isBuy: true)
    private let wide  = CDSCalculator.calculate(tradeDate: tradeDate, tenorYears: 5,
        parSpreadBp: 250, couponBp: 100, recoveryRate: 0.40, notional: 10_000_000, isBuy: true)
    private let tight = CDSCalculator.calculate(tradeDate: tradeDate, tenorYears: 5,
        parSpreadBp:  50, couponBp: 100, recoveryRate: 0.40, notional: 10_000_000, isBuy: true)
    private var pricingOk: Bool {
        guard let p = par, let w = wide, let t = tight else { return false }
        return abs(p.upfrontFraction) < 1e-4 && w.upfrontFraction > 0 && t.upfrontFraction < 0
    }

    // === Test 3: IMM helpers ===
    private let nextIMMA = CDSCalculator.nextIMMDate(after: makeDate(2026, 4, 1))
    private let nextIMMB = CDSCalculator.nextIMMDate(after: makeDate(2026, 3, 20))
    private let prevIMMA = CDSCalculator.prevIMMDate(before: makeDate(2026, 4, 1))
    private var immOk: Bool {
        nextIMMA == JpmcdsDate(2026, 6, 20)
            && nextIMMB == JpmcdsDate(2026, 6, 20)
            && CDSCalculator.tdate(from: prevIMMA) == JpmcdsDate(2026, 3, 20)
    }

    // === Test 4: holiday calendar by region ===
    private let july4NY = CDSCalculator.addBusinessDays(1, to: makeDate(2026, 7, 2), calendarName: "nyFed")
    private let july4EU = CDSCalculator.addBusinessDays(1, to: makeDate(2026, 7, 2), calendarName: "target")
    private let may1NY  = CDSCalculator.addBusinessDays(1, to: makeDate(2026, 4, 30), calendarName: "nyFed")
    private let may1EU  = CDSCalculator.addBusinessDays(1, to: makeDate(2026, 4, 30), calendarName: "target")
    private let gwNY    = CDSCalculator.addBusinessDays(3, to: makeDate(2026, 4, 28), calendarName: "nyFed")
    private let gwTok   = CDSCalculator.addBusinessDays(3, to: makeDate(2026, 4, 28), calendarName: "tokyo")
    private var calOk: Bool {
        let cal = Calendar(identifier: .gregorian)
        let eq: (Date, (Int, Int, Int)) -> Bool = { d, ymd in
            cal.component(.year,  from: d) == ymd.0 &&
            cal.component(.month, from: d) == ymd.1 &&
            cal.component(.day,   from: d) == ymd.2
        }
        return eq(july4NY, (2026, 7, 6))
            && eq(july4EU, (2026, 7, 3))
            && eq(may1NY,  (2026, 5, 1))
            && eq(may1EU,  (2026, 5, 4))
            && eq(gwNY,    (2026, 5, 1))
            && eq(gwTok,   (2026, 5, 6))
    }

    private var ok: Bool { datesOk && pricingOk && immOk && calOk }

    var body: some View {
        let section = Font.system(size: 16, weight: .bold)
        let row     = Font.system(size: 12, design: .monospaced)
        let off     = Color(white: 0.92)
        return ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text("Test 1 — JpmcdsDate").font(section).foregroundColor(.orange)
                Text("JpmcdsDate(1601, 1, 1) = \(tdEpoch)").font(row).foregroundColor(off)
                Text("JpmcdsDate(2010, 1, 4) = \(td2010)").font(row).foregroundColor(off)
                Text("JpmcdsDate(2024, 13, 99) = \(tdInvalid) (expect -1)").font(row).foregroundColor(off)
                Text("Δ(2026-05-05, 2026-05-04) = \(oneDay) (expect 1)").font(row).foregroundColor(off)

                Text("Test 2 — CDSCalculator ($10M, 5Y, today=2026-05-04)")
                    .font(section).foregroundColor(.orange).padding(.top, 12)
                Text("par   (sp=100, cp=100): \(bp(par))  / \(usd(par))").font(row).foregroundColor(off)
                Text("wide  (sp=250, cp=100): \(bp(wide)) / \(usd(wide))").font(row).foregroundColor(off)
                Text("tight (sp= 50, cp=100): \(bp(tight)) / \(usd(tight))").font(row).foregroundColor(off)

                Text("Test 3 — IMM helpers").font(section).foregroundColor(.orange).padding(.top, 12)
                Text("next IMM after 2026-04-01 = \(ymd(nextIMMA))").font(row).foregroundColor(off)
                Text("next IMM after 2026-03-20 = \(ymd(nextIMMB)) (strictly after)").font(row).foregroundColor(off)
                Text("prev IMM before 2026-04-01 = \(ymd(prevIMMA))").font(row).foregroundColor(off)

                Text("Test 4 — Holiday calendar by region").font(section).foregroundColor(.orange).padding(.top, 12)
                Text("Thu 2026-07-02 + 1 BD nyFed  = \(ymd(july4NY))").font(row).foregroundColor(off)
                Text("Thu 2026-07-02 + 1 BD target = \(ymd(july4EU))").font(row).foregroundColor(off)
                Text("Thu 2026-04-30 + 1 BD nyFed  = \(ymd(may1NY))").font(row).foregroundColor(off)
                Text("Thu 2026-04-30 + 1 BD target = \(ymd(may1EU))").font(row).foregroundColor(off)
                Text("Tue 2026-04-28 + 3 BD nyFed  = \(ymd(gwNY))").font(row).foregroundColor(off)
                Text("Tue 2026-04-28 + 3 BD tokyo  = \(ymd(gwTok))").font(row).foregroundColor(off)

                Text("Test 5 — RFR fetcher (live)").font(section).foregroundColor(.orange).padding(.top, 12)
                ForEach(RFRCurrency.allCases) { ccy in
                    let s = store.status(for: ccy)
                    let r = store.rate(for: ccy)
                    let d = store.effectiveDate(for: ccy)
                    Text("\(statusMark(s)) \(ccy.indexName.padding(toLength: 6, withPad: " ", startingAt: 0))" +
                         " \(String(format: "%.3f", r * 100))% (\(d))  \(ccy.sourceLabel)")
                        .font(row).foregroundColor(off)
                }

                Text(ok
                     ? "✓ All deterministic tests pass on this platform."
                     : "✗ Something is off — see rows above.")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ok ? .green : .red)
                    .padding(.top, 16)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: helpers

    private static func makeDate(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var dc = DateComponents(); dc.year = y; dc.month = m; dc.day = d
        return Calendar(identifier: .gregorian).date(from: dc) ?? Date()
    }
    private func bp(_ r: CDSResult?) -> String {
        guard let r = r else { return "nil" }
        return String(format: "%.2f bp", r.upfrontBp)
    }
    private func usd(_ r: CDSResult?) -> String {
        guard let r = r else { return "nil" }
        return String(format: "$%.0f", r.upfrontDollars)
    }
    private func ymd(_ td: TDate) -> String {
        var mdy = TMonthDayYear()
        JpmcdsDateToMDY(td, &mdy)
        return String(format: "%04d-%02d-%02d", Int(mdy.year), Int(mdy.month), Int(mdy.day))
    }
    private func ymd(_ d: Date) -> String {
        let c = Calendar(identifier: .gregorian)
        return String(format: "%04d-%02d-%02d",
                      c.component(.year, from: d),
                      c.component(.month, from: d),
                      c.component(.day, from: d))
    }
    private func statusMark(_ s: SOFRDataStatus) -> String {
        switch s {
        case .live:     return "✓"
        case .fallback: return "·"
        case .loading:  return "…"
        }
    }
}
