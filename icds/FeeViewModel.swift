//
//  FeeViewModel.swift
//  icds
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//

import Foundation
import Combine
import StoreKit
import UIKit

// Tracks "successful pricing sessions" across launches and asks the system
// to show the App Store review prompt at a tasteful threshold. Apple itself
// rate-limits requestReview to 3 times per 365 days regardless of how often
// it's called, so we just ask once when the counter first crosses the bar.
private enum AppReviewPrompter {
    private static let countKey = "iCDS.successfulSessions"
    private static let promptThreshold = 5
    private static var sessionRecorded = false

    static func recordSuccessfulCalculation() {
        guard !sessionRecorded else { return }
        sessionRecorded = true

        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: countKey) + 1
        defaults.set(count, forKey: countKey)

        if count == promptThreshold {
            requestReviewSoon()
        }
    }

    private static func requestReviewSoon() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            else { return }
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

final class FeeViewModel: ObservableObject {

    // MARK: - Inputs
    @Published var regionIndex:   Int = 0
    @Published var buySellIndex:  Int = 0       // 0=Buy 1=Sell
    @Published var notionalIndex: Int = 2       // 10M default
    @Published var maturityIndex: Int = 1       // 5Y default
    @Published var couponIndex:   Int = 0
    @Published var recoveryIndex: Int = 0
    @Published var spreadBp:      Double = 100
    @Published var tradeDateOffset: Int = 0    // days from today
    @Published var currencyIndex: Int = 4       // USD

    // MARK: - Static option lists
    let notionalLabels = ["1M", "5M", "10M", "20M"]
    let notionalValues = [1_000_000.0, 5_000_000.0, 10_000_000.0, 20_000_000.0]
    let tenorLabels    = ["1Y", "5Y", "7Y", "10Y"]
    let tenorYears     = [1, 5, 7, 10]
    let currencies     = ["AUD", "EUR", "GBP", "JPY", "USD"]

    // MARK: - Derived
    @Published private(set) var contracts: [ISDAContract] = []
    @Published private(set) var result: CDSResult? = nil

    var contract: ISDAContract? {
        contracts.indices.contains(regionIndex) ? contracts[regionIndex] : nil
    }
    var couponBp: Double {
        guard let c = contract, c.coupons.indices.contains(couponIndex) else { return 100 }
        return Double(c.coupons[couponIndex])
    }
    var recoveryPct: Int {
        guard let c = contract, c.recoveryList.indices.contains(recoveryIndex) else { return 40 }
        return c.recoveryList[recoveryIndex].recovery
    }
    var recoveryLabel: String { "\(recoveryPct)%" }
    var currency: String { currencies[currencyIndex] }
    // Raw date from stepper offset, snapped to the last valid business day for the region
    var tradeDate: Date {
        let raw = Calendar.current.date(byAdding: .day, value: tradeDateOffset, to: Date()) ?? Date()
        return CDSCalculator.lastValidTradeDate(on: raw, calendarName: contract?.calendarName ?? "nyFed")
    }
    var tradeDateLabel: String {
        let fmt = DateFormatter(); fmt.dateFormat = "dd-MMM-yy"
        return fmt.string(from: tradeDate)
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        contracts = ISDAContract.readFromPlist()
        // Sync the default spread to the default contract's first coupon so the
        // input is always meaningful at first render (e.g. SNAC NA = 100 bp).
        // Without this, spreadBp could be left at the literal 100 default while
        // a contract with a different first coupon is selected, and the spread
        // picker would open showing the stale value.
        if let firstCoupon = contracts.first?.coupons.first {
            spreadBp = Double(firstCoupon)
        }
        // result stays nil here → FeeView shows "Calculating…" for one frame

        // Pre-warm all holiday calendar sets at high priority so they are
        // likely ready before the @MainActor Task below needs them.
        Task.detached(priority: .userInitiated) { CDSHolidayCalendar.prewarmAll() }

        // Snap trade date to last valid business day, run first calculation
        // with correct settle date, then fetch live SOFR for that date.
        // Done in a Task so CDSHolidayCalendar static initialisation happens
        // after launch rather than blocking the launch screen transition.
        Task { @MainActor in
            let region  = self.contract?.calendarName ?? "nyFed"
            let lastBiz = CDSCalculator.lastValidTradeDate(on: Date(), calendarName: region)
            let offset  = Calendar.current.dateComponents([.day], from: Date(), to: lastBiz).day ?? 0
            if self.tradeDateOffset != offset { self.tradeDateOffset = offset }
            self.recalculate()                                   // first result, fallback SOFR rate
            SOFRRateStore.shared.updateForTradeDate(self.tradeDate) // live rate triggers another recalc
        }

        // Recalculate whenever any input changes
        Publishers.MergeMany(
            $regionIndex.map { _ in () }.eraseToAnyPublisher(),
            $buySellIndex.map { _ in () }.eraseToAnyPublisher(),
            $notionalIndex.map { _ in () }.eraseToAnyPublisher(),
            $maturityIndex.map { _ in () }.eraseToAnyPublisher(),
            $couponIndex.map { _ in () }.eraseToAnyPublisher(),
            $recoveryIndex.map { _ in () }.eraseToAnyPublisher(),
            $spreadBp.map { _ in () }.eraseToAnyPublisher(),
            $tradeDateOffset.map { _ in () }.eraseToAnyPublisher(),
            $currencyIndex.map { _ in () }.eraseToAnyPublisher()
        )
        .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
        .sink { [weak self] in self?.recalculate() }
        .store(in: &cancellables)

        // Re-fetch SOFR when trade date changes (use curve as of trade date)
        $tradeDateOffset
            .dropFirst()
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                SOFRRateStore.shared.updateForTradeDate(self.tradeDate)
            }
            .store(in: &cancellables)

        // Recalculate when any live RFR rate arrives or refreshes
        SOFRRateStore.shared.$rates
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.recalculate() }
            .store(in: &cancellables)
    }

    func onRegionChanged() {
        couponIndex   = 0
        recoveryIndex = 0
        resetSpreadToCoupon()
        if let regionCurrency = contract?.currency,
           let idx = currencies.firstIndex(of: regionCurrency) {
            currencyIndex = idx
        }
    }

    func resetSpreadToCoupon() {
        spreadBp = couponBp
    }

    /// Discount rate for the current region's currency
    var discountRate: Double {
        guard let ccyStr = contract?.currency,
              let ccy = RFRCurrency(rawValue: ccyStr) else {
            return RFRCurrency.USD.fallbackRate
        }
        return SOFRRateStore.shared.rate(for: ccy)
    }

    /// Effective date of the rate used (for display)
    var discountRateDate: String {
        guard let ccyStr = contract?.currency,
              let ccy = RFRCurrency(rawValue: ccyStr) else { return "—" }
        return SOFRRateStore.shared.effectiveDate(for: ccy)
    }

    /// Status of the rate used (for display)
    var discountRateStatus: SOFRDataStatus {
        guard let ccyStr = contract?.currency,
              let ccy = RFRCurrency(rawValue: ccyStr) else { return .loading }
        return SOFRRateStore.shared.status(for: ccy)
    }

    private func recalculate() {
        result = CDSCalculator.calculate(
            tradeDate:    tradeDate,
            tenorYears:   tenorYears[maturityIndex],
            parSpreadBp:  spreadBp,
            couponBp:     couponBp,
            recoveryRate: Double(recoveryPct) / 100.0,
            notional:     notionalValues[notionalIndex],
            isBuy:        buySellIndex == 0,
            settleDays:   contract?.settleDays   ?? 1,
            calendarName: contract?.calendarName ?? "nyFed",
            discountRate: discountRate,
            minSettle:    Date()
        )
        if result != nil {
            AppReviewPrompter.recordSuccessfulCalculation()
        }
    }

    /// Recompute upfront for a hypothetical spread without committing it.
    /// Used by the spread picker sheet to preview the dollar impact live.
    func previewUpfront(forSpread spread: Double) -> CDSResult? {
        CDSCalculator.calculate(
            tradeDate:    tradeDate,
            tenorYears:   tenorYears[maturityIndex],
            parSpreadBp:  spread,
            couponBp:     couponBp,
            recoveryRate: Double(recoveryPct) / 100.0,
            notional:     notionalValues[notionalIndex],
            isBuy:        buySellIndex == 0,
            settleDays:   contract?.settleDays   ?? 1,
            calendarName: contract?.calendarName ?? "nyFed",
            discountRate: discountRate,
            minSettle:    Date()
        )
    }

    // MARK: - Prototype helpers (space-utilization candidates)
    //
    // All reuse CDSCalculator with one bumped input (finite difference).
    // These are computed on demand by the prototype views; they are not
    // cached, so stacking all four re-prices the trade ~30× per state
    // change. Acceptable for an on-device eyeball test, not for ship.

    struct RiskMeasures { let cs01: Double; let ir01: Double; let rec01: Double }
    struct CurvePoint   { let spread: Double; let dollars: Double }
    struct Scenario     { let label: String; let spread: Double; let dollars: Double }

    private func calc(spreadBp s: Double,
                      recoveryRate rec: Double,
                      discountRate disc: Double) -> CDSResult? {
        CDSCalculator.calculate(
            tradeDate:    tradeDate,
            tenorYears:   tenorYears[maturityIndex],
            parSpreadBp:  s,
            couponBp:     couponBp,
            recoveryRate: rec,
            notional:     notionalValues[notionalIndex],
            isBuy:        buySellIndex == 0,
            settleDays:   contract?.settleDays   ?? 1,
            calendarName: contract?.calendarName ?? "nyFed",
            discountRate: disc,
            minSettle:    Date()
        )
    }

    /// Finite-difference sensitivities of the upfront ($), trade-direction signed.
    /// CS01: +1 bp spread. IR DV01: +1 bp discount rate. Rec01: +1 pt recovery.
    var riskMeasures: RiskMeasures? {
        let rec = Double(recoveryPct) / 100.0
        guard
            let base = calc(spreadBp: spreadBp,       recoveryRate: rec,        discountRate: discountRate),
            let sUp  = calc(spreadBp: spreadBp + 1.0, recoveryRate: rec,        discountRate: discountRate),
            let iUp  = calc(spreadBp: spreadBp,       recoveryRate: rec,        discountRate: discountRate + 0.0001),
            let rUp  = calc(spreadBp: spreadBp,       recoveryRate: rec + 0.01, discountRate: discountRate)
        else { return nil }
        return RiskMeasures(
            cs01:  sUp.upfrontDollars - base.upfrontDollars,
            ir01:  iUp.upfrontDollars - base.upfrontDollars,
            rec01: rUp.upfrontDollars - base.upfrontDollars
        )
    }

    /// Upfront ($) sampled across a ±150 bp window for the sensitivity sparkline.
    func sensitivityCurve(samples: Int = 24) -> [CurvePoint] {
        guard samples > 1 else { return [] }
        let rec  = Double(recoveryPct) / 100.0
        let lo   = max(1.0, spreadBp - 150)
        let hi   = spreadBp + 150
        let step = (hi - lo) / Double(samples - 1)
        return (0..<samples).compactMap { i in
            let s = lo + Double(i) * step
            guard let r = calc(spreadBp: s, recoveryRate: rec, discountRate: discountRate) else { return nil }
            return CurvePoint(spread: s, dollars: r.upfrontDollars)
        }
    }

    /// Upfront ($) at spread offsets from the current quote for the scenario row.
    func scenarioUpfronts(offsets: [Int]) -> [Scenario] {
        let rec = Double(recoveryPct) / 100.0
        return offsets.compactMap { off in
            let s = max(1.0, spreadBp + Double(off))
            guard let r = calc(spreadBp: s, recoveryRate: rec, discountRate: discountRate) else { return nil }
            let sign = off > 0 ? "+" : ""
            return Scenario(label: "\(sign)\(off)", spread: s, dollars: r.upfrontDollars)
        }
    }
}
