//
//  icdsTests.swift
//  icdsTests
//
//  Copyright © 2016-2026 James A. Zucker All rights reserved.
//

import XCTest
@testable import icds

class icdsTests: XCTestCase {

    // Fixed reference date for deterministic tests: April 15, 2024
    let refDate: Date = {
        var dc = DateComponents()
        dc.year = 2024; dc.month = 4; dc.day = 15
        return Calendar.current.date(from: dc)!
    }()

    // MARK: - ISDAContract / Plist Loading

    func testContractLoadCount() {
        let contracts = ISDAContract.readFromPlist()
        XCTAssertEqual(contracts.count, 7, "Expected 7 regional contracts")
    }

    func testContractRegionNames() {
        let regions = ISDAContract.readFromPlist().map { $0.region }
        for expected in ["NA", "EU", "EM", "Asia", "Japan", "AUS", "LCDS"] {
            XCTAssertTrue(regions.contains(expected), "Missing region: \(expected)")
        }
    }

    func testNAContractRecovery() {
        let contracts = ISDAContract.readFromPlist()
        let na = contracts.first { $0.region == "NA" }!
        XCTAssertEqual(na.recoveryList.count, 2)
        let rates = Set(na.recoveryList.map { $0.recovery })
        XCTAssertTrue(rates.contains(40), "NA SEN recovery should be 40%")
        XCTAssertTrue(rates.contains(20), "NA SUB recovery should be 20%")
    }

    func testNAContractCoupons() {
        let na = ISDAContract.readFromPlist().first { $0.region == "NA" }!
        XCTAssertTrue(na.coupons.contains(100))
        XCTAssertTrue(na.coupons.contains(500))
    }

    func testLCDSHighRecovery() {
        let lcds = ISDAContract.readFromPlist().first { $0.region == "LCDS" }!
        XCTAssertEqual(lcds.recoveryList.first?.recovery, 70, "LCDS recovery should be 70%")
    }

    func testRecoverySubordinationSortedAlphabetically() {
        // Dictionary keys sorted: SEN before SUB
        let na = ISDAContract.readFromPlist().first { $0.region == "NA" }!
        XCTAssertEqual(na.recoveryList[0].subordination, "SEN")
        XCTAssertEqual(na.recoveryList[1].subordination, "SUB")
    }

    // MARK: - Recovery Model

    func testRecoveryInit() {
        let r = Recovery(subordination: "SEN", recovery: 40)
        XCTAssertEqual(r.subordination, "SEN")
        XCTAssertEqual(r.recovery, 40)
    }

    // MARK: - IMM Date Helpers

    func testNextIMMDateBeforeMarch20() {
        var dc = DateComponents(); dc.year = 2024; dc.month = 3; dc.day = 10
        let imm = CDSCalculator.nextIMMDate(after: Calendar.current.date(from: dc)!)
        var mdy = TMonthDayYear()
        JpmcdsDateToMDY(imm, &mdy)
        XCTAssertEqual(mdy.month, 3); XCTAssertEqual(mdy.day, 20); XCTAssertEqual(mdy.year, 2024)
    }

    func testNextIMMDateAfterDecemberRollsToNextYear() {
        var dc = DateComponents(); dc.year = 2024; dc.month = 12; dc.day = 21
        let imm = CDSCalculator.nextIMMDate(after: Calendar.current.date(from: dc)!)
        var mdy = TMonthDayYear()
        JpmcdsDateToMDY(imm, &mdy)
        XCTAssertEqual(mdy.month, 3); XCTAssertEqual(mdy.year, 2025)
    }

    func testNextIMMDateExactlyOnIMMAdvancesToNext() {
        // On Jun 20 exactly, next IMM is Sep 20
        var dc = DateComponents(); dc.year = 2024; dc.month = 6; dc.day = 20
        let imm = CDSCalculator.nextIMMDate(after: Calendar.current.date(from: dc)!)
        var mdy = TMonthDayYear()
        JpmcdsDateToMDY(imm, &mdy)
        XCTAssertEqual(mdy.month, 9)
        XCTAssertEqual(mdy.year, 2024)
    }

    func testPrevIMMDateBeforeJune20() {
        var dc = DateComponents(); dc.year = 2024; dc.month = 6; dc.day = 15
        let prev = CDSCalculator.prevIMMDate(before: Calendar.current.date(from: dc)!)
        let cal  = Calendar.current
        XCTAssertEqual(cal.component(.month, from: prev), 3)
        XCTAssertEqual(cal.component(.day,   from: prev), 20)
        XCTAssertEqual(cal.component(.year,  from: prev), 2024)
    }

    func testPrevIMMDateOnDecember20IsSameDay() {
        var dc = DateComponents(); dc.year = 2024; dc.month = 12; dc.day = 20
        let prev = CDSCalculator.prevIMMDate(before: Calendar.current.date(from: dc)!)
        let cal  = Calendar.current
        XCTAssertEqual(cal.component(.month, from: prev), 12)
        XCTAssertEqual(cal.component(.day,   from: prev), 20)
        XCTAssertEqual(cal.component(.year,  from: prev), 2024)
    }

    // MARK: - CDS Calculation: Core Financial Properties

    func testCalculationReturnsResult() {
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 100, couponBp: 100,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)
        XCTAssertNotNil(r)
    }

    func testAtParSpreadUpfrontNearZero() {
        // Spread = coupon → upfront ≈ 0
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 100, couponBp: 100,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertEqual(r.upfrontFraction, 0.0, accuracy: 0.005)
    }

    func testSpreadAboveCouponBuyerPays() {
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 300, couponBp: 100,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertGreaterThan(r.upfrontFraction, 0)
        XCTAssertGreaterThan(r.upfrontDollars,  0)
    }

    func testSpreadBelowCouponBuyerReceives() {
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 50, couponBp: 100,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertLessThan(r.upfrontFraction, 0)
        XCTAssertLessThan(r.upfrontDollars,  0)
    }

    func testSellIsOppositeOfBuy() {
        let buy  = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                           parSpreadBp: 200, couponBp: 100,
                                           recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        let sell = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                           parSpreadBp: 200, couponBp: 100,
                                           recoveryRate: 0.40, notional: 10_000_000, isBuy: false)!
        XCTAssertEqual(buy.upfrontDollars, -sell.upfrontDollars, accuracy: 1.0)
    }

    func testUpfrontIncreasesMonotonicallyWithSpread() {
        var prev = -Double.greatestFiniteMagnitude
        for s in [50.0, 100.0, 200.0, 300.0, 500.0] {
            let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                            parSpreadBp: s, couponBp: 100,
                                            recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
            XCTAssertGreaterThan(r.upfrontDollars, prev, "Upfront should increase with spread")
            prev = r.upfrontDollars
        }
    }

    func testLongerTenorLargerUpfront() {
        let r1 = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 1,
                                         parSpreadBp: 300, couponBp: 100,
                                         recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        let r5 = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                         parSpreadBp: 300, couponBp: 100,
                                         recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertGreaterThan(r5.upfrontDollars, r1.upfrontDollars)
    }

    func testHigherRecoveryLowerUpfront() {
        let rLow  = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                            parSpreadBp: 300, couponBp: 100,
                                            recoveryRate: 0.20, notional: 10_000_000, isBuy: true)!
        let rHigh = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                            parSpreadBp: 300, couponBp: 100,
                                            recoveryRate: 0.60, notional: 10_000_000, isBuy: true)!
        XCTAssertGreaterThan(rLow.upfrontDollars, rHigh.upfrontDollars,
                             "Higher recovery → smaller upfront (less risky)")
    }

    func testPriceIsOneMinusUpfrontPercent() {
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 200, couponBp: 100,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertEqual(r.price, (1.0 - r.upfrontFraction) * 100.0, accuracy: 0.0001)
    }

    func testNotionalScalesLinearly() {
        let r1 = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                         parSpreadBp: 200, couponBp: 100,
                                         recoveryRate: 0.40, notional: 5_000_000, isBuy: true)!
        let r2 = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                         parSpreadBp: 200, couponBp: 100,
                                         recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertEqual(r2.upfrontDollars, r1.upfrontDollars * 2.0, accuracy: 1.0)
    }

    func testParSpreadRoundTrip() {
        // Par spread back-calculated at zero upfront should equal the input spread
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 150, couponBp: 100,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertEqual(r.parSpreadBp, 150.0, accuracy: 1.0)
    }

    func testAllTenorsSucceed() {
        for tenor in [1, 5, 7, 10] {
            let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: tenor,
                                            parSpreadBp: 200, couponBp: 100,
                                            recoveryRate: 0.40, notional: 10_000_000, isBuy: true)
            XCTAssertNotNil(r, "\(tenor)Y tenor should succeed")
        }
    }

    func testAllRegionRecoveryRatesProduceResults() {
        let contracts = ISDAContract.readFromPlist()
        for contract in contracts {
            for rec in contract.recoveryList {
                let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                                parSpreadBp: 200,
                                                couponBp: Double(contract.coupons.first ?? 100),
                                                recoveryRate: Double(rec.recovery) / 100.0,
                                                notional: 10_000_000, isBuy: true)
                XCTAssertNotNil(r, "\(contract.region)/\(rec.subordination) should produce a result")
            }
        }
    }

    // MARK: - ISDA Standard: 500bp Coupon (NA Distressed)

    func testAtParSpread500bpCouponUpfrontNearZero() {
        // NA distressed standard uses 500bp fixed coupon; at-par spread → upfront ≈ 0
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 500, couponBp: 500,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertEqual(r.upfrontFraction, 0.0, accuracy: 0.005)
    }

    func testSpreadAbove500bpCouponBuyerPays() {
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 1000, couponBp: 500,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertGreaterThan(r.upfrontFraction, 0)
    }

    func testSpreadBelow500bpCouponBuyerReceives() {
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 100, couponBp: 500,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertLessThan(r.upfrontFraction, 0)
    }

    func testBuySellSymmetry500bpCoupon() {
        let buy  = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                           parSpreadBp: 800, couponBp: 500,
                                           recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        let sell = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                           parSpreadBp: 800, couponBp: 500,
                                           recoveryRate: 0.40, notional: 10_000_000, isBuy: false)!
        XCTAssertEqual(buy.upfrontDollars, -sell.upfrontDollars, accuracy: 1.0)
    }

    func testCouponLevelAffectsUpfront() {
        // Same par spread (300bp); 100bp coupon → buyer pays; 500bp coupon → buyer receives
        let r100 = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                           parSpreadBp: 300, couponBp: 100,
                                           recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        let r500 = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                           parSpreadBp: 300, couponBp: 500,
                                           recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertGreaterThan(r100.upfrontFraction, r500.upfrontFraction)
    }

    func testParSpreadRoundTrip500bpCoupon() {
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 600, couponBp: 500,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertEqual(r.parSpreadBp, 600.0, accuracy: 1.0)
    }

    // MARK: - ISDA Standard: Edge Cases

    func testVeryHighSpreadProducesResult() {
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 2000, couponBp: 500,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)
        XCTAssertNotNil(r, "2000bp distressed spread should produce a result")
    }

    func testNearZeroSpreadProducesResult() {
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 1, couponBp: 100,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)
        XCTAssertNotNil(r)
    }

    func testAccruedInterestIsNonNegative() {
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 200, couponBp: 100,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertGreaterThanOrEqual(r.accrued, 0)
    }

    func testPriceRangeReasonable() {
        for spread in [50.0, 100.0, 200.0, 500.0, 1000.0] {
            let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                            parSpreadBp: spread, couponBp: 100,
                                            recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
            XCTAssertGreaterThan(r.price, 50.0, "price sanity low bound at \(spread)bp")
            XCTAssertLessThan(r.price,   120.0, "price sanity high bound at \(spread)bp")
        }
    }

    // MARK: - Region Contract Validation

    func testEUContractHasCoupons() {
        let eu = ISDAContract.readFromPlist().first { $0.region == "EU" }!
        XCTAssertFalse(eu.coupons.isEmpty)
    }

    func testEMContractHasRecovery() {
        let em = ISDAContract.readFromPlist().first { $0.region == "EM" }!
        XCTAssertFalse(em.recoveryList.isEmpty)
    }

    func testAllRegionsAtParCouponNearZeroUpfront() {
        // For every region × coupon combination, at-par spread → upfront ≈ 0
        let contracts = ISDAContract.readFromPlist()
        for contract in contracts {
            let recovery = Double(contract.recoveryList.first?.recovery ?? 40) / 100.0
            for coupon in contract.coupons {
                let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                                parSpreadBp: Double(coupon),
                                                couponBp: Double(coupon),
                                                recoveryRate: recovery,
                                                notional: 10_000_000, isBuy: true)
                XCTAssertNotNil(r, "\(contract.region) coupon=\(coupon)bp at-par failed")
                XCTAssertEqual(r!.upfrontFraction, 0.0, accuracy: 0.005,
                               "\(contract.region) coupon=\(coupon)bp at-par upfront should be ~0")
            }
        }
    }

    // MARK: - Performance

    func testCalculationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                            parSpreadBp: 150, couponBp: 100,
                                            recoveryRate: 0.40, notional: 10_000_000, isBuy: true)
            }
        }
    }
}
