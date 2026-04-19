//
//  FeeViewModel.swift
//  icds
//
//  Copyright © 2016-2026 James A. Zucker All rights reserved.
//

import Foundation
import Combine

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
    @Published var currencyIndex: Int = 2       // USD

    // MARK: - Static option lists
    let notionalLabels = ["1M", "5M", "10M", "20M"]
    let notionalValues = [1_000_000.0, 5_000_000.0, 10_000_000.0, 20_000_000.0]
    let tenorLabels    = ["1Y", "5Y", "7Y", "10Y"]
    let tenorYears     = [1, 5, 7, 10]
    let currencies     = ["EUR", "GBP", "USD"]

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
    var tradeDate: Date {
        Calendar.current.date(byAdding: .day, value: tradeDateOffset, to: Date()) ?? Date()
    }
    var tradeDateLabel: String {
        let fmt = DateFormatter(); fmt.dateFormat = "d-MMM"
        return fmt.string(from: tradeDate)
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        contracts = ISDAContract.readFromPlist()
        recalculate()

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
    }

    func onRegionChanged() {
        couponIndex   = 0
        recoveryIndex = 0
        resetSpreadToCoupon()
    }

    func resetSpreadToCoupon() {
        spreadBp = couponBp
    }

    func recalc() { recalculate() }

    private func recalculate() {
        result = CDSCalculator.calculate(
            tradeDate:    tradeDate,
            tenorYears:   tenorYears[maturityIndex],
            parSpreadBp:  spreadBp,
            couponBp:     couponBp,
            recoveryRate: Double(recoveryPct) / 100.0,
            notional:     notionalValues[notionalIndex],
            isBuy:        buySellIndex == 0
        )
    }
}
