//
//  icdsTests.swift
//  icdsTests
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
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
        XCTAssertEqual(contracts.count, 6, "Expected 6 regional contracts")
    }

    func testContractRegionNames() {
        let regions = ISDAContract.readFromPlist().map { $0.region }
        for expected in ["NA", "EU", "EM", "Asia", "Japan", "AUS"] {
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

    // LCDS removed — Loan CDS market has been largely dormant since ~2016.

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

    func testAtParSpreadUpfrontIsExactlyZero() {
        // SNAC invariant: spread == coupon → clean upfront = 0 (tight tolerance)
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 100, couponBp: 100,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertEqual(r.upfrontFraction, 0.0, accuracy: 0.00001,
                       "Par trade must give $0 upfront, not a 1-day coupon residual")
        XCTAssertEqual(r.upfrontDollars, 0.0, accuracy: 1.0,
                       "Par trade upfront in dollars must be < $1 on $10M")
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

    func testAtParSpread500bpCouponIsExactlyZero() {
        // NA distressed standard uses 500bp fixed coupon; at-par spread → upfront = 0
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 500, couponBp: 500,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertEqual(r.upfrontFraction, 0.0, accuracy: 0.00001)
        XCTAssertEqual(r.upfrontDollars,  0.0, accuracy: 1.0)
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

    // MARK: - Spread ceiling (10000 bp = FeeView.maxSpreadBp)
    //
    // 10000 bp = 100%/yr — effectively default-certain over the contract life.
    // The upfront should approach the loss-given-default ((1 - recovery) ×
    // notional) discounted to PV, less the present value of the running
    // coupon. For 5Y / 40% recovery / 4.5% flat discount, that's roughly
    // 50% of notional. These tests pin down the math at the new ceiling
    // and the round-trip behaviour the picker relies on.

    func test10kSpreadProducesPositiveUpfront() {
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 10000, couponBp: 100,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)
        XCTAssertNotNil(r, "10000bp ceiling spread must produce a result")
        XCTAssertGreaterThan(r!.upfrontDollars, 0,
                             "Buyer pays substantial upfront at 10000 bp on a 100 bp coupon")
    }

    func test10kSpreadUpfrontIsBoundedByLossGivenDefault() {
        // upfront fraction cannot exceed (1 - recovery): you can never
        // owe more than the loss-given-default at default certainty.
        // Allow a 5% absolute margin for accrued / numerical slack.
        let recovery = 0.40
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 10000, couponBp: 100,
                                        recoveryRate: recovery, notional: 10_000_000, isBuy: true)!
        XCTAssertLessThan(r.upfrontFraction, (1 - recovery) + 0.05,
                          "Upfront fraction must not exceed loss-given-default")
        XCTAssertGreaterThan(r.upfrontFraction, 0.30,
                             "5Y at 10000 bp on 100 bp coupon should be a substantial fraction (>30%)")
    }

    func test10kSpreadRoundTrip() {
        // Par spread back-calculated from a 10000 bp upfront should
        // recover the 10000 bp input. Tight tolerance: 1 bp on $10M.
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 10000, couponBp: 100,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        XCTAssertEqual(r.parSpreadBp, 10000.0, accuracy: 1.0,
                       "parSpread round-trip must recover 10000 bp at the cap")
    }

    func test10kSpreadBuySellSymmetric() {
        let buy  = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                           parSpreadBp: 10000, couponBp: 100,
                                           recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        let sell = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                           parSpreadBp: 10000, couponBp: 100,
                                           recoveryRate: 0.40, notional: 10_000_000, isBuy: false)!
        XCTAssertEqual(buy.upfrontDollars, -sell.upfrontDollars, accuracy: 1.0,
                       "Buy and sell upfronts must be exact opposites at the 10000 bp ceiling")
    }

    // MARK: - Spread picker chip grid
    //
    // The Quoted Spread sheet exposes a 4 × 3 chip grid. For each chip we
    // verify three things at once:
    //   1. the calculator returns a result (no crash, no nil)
    //   2. the directional sign matches the chip's relation to coupon
    //      (below-par → buyer receives, at-par → ~$0, above-par → buyer pays)
    //   3. parSpread round-trips back to the chip's bp value within 1 bp on
    //      $10M, so the result panel's reported par spread agrees with what
    //      the user picked

    /// Walks every visible chip for the default 100 bp coupon (the picker's
    /// initial state for NA SNAC) and checks calculator output and round-trip.
    func testChipGridDefault100bpCoupon() {
        let coupon = 100.0
        // (bp value, expected upfront sign, chip label) — labels mirror FeeView
        let chips: [(bp: Double, sign: Int, label: String)] = [
            // Row 1 negatives: -200 and -100 are hidden for coupon=100 (would
            // clamp to 1 bp and confuse). -50 is the only visible neg chip.
            (50,    -1, "Coupon -50"),
            // Row 2 near-par
            (100,    0, "At Par"),
            (150,   +1, "Coupon +50"),
            (200,   +1, "Coupon +100"),
            // Row 3 medium
            (300,   +1, "Coupon +200"),
            (600,   +1, "Coupon +500"),
            (1100,  +1, "Coupon +1000"),
            // Row 4 distressed
            (2100,  +1, "Coupon +2000"),
            (5100,  +1, "Coupon +5000"),
            (10000, +1, "Max 10000"),
        ]
        var prevUpfront: Double = -.infinity
        for spec in chips {
            guard let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                                  parSpreadBp: spec.bp, couponBp: coupon,
                                                  recoveryRate: 0.40, notional: 10_000_000,
                                                  isBuy: true) else {
                XCTFail("\(spec.label) (\(spec.bp) bp): calculator returned nil")
                continue
            }
            switch spec.sign {
            case -1:
                XCTAssertLessThan(r.upfrontDollars, -1.0,
                                  "\(spec.label) (\(spec.bp) bp): buyer should receive (< -$1)")
            case 0:
                XCTAssertEqual(r.upfrontDollars, 0.0, accuracy: 1.0,
                               "\(spec.label) (\(spec.bp) bp): at-par upfront must be ~$0 on $10M")
            case 1:
                XCTAssertGreaterThan(r.upfrontDollars, 1.0,
                                     "\(spec.label) (\(spec.bp) bp): buyer should pay (> $1)")
            default: break
            }
            XCTAssertEqual(r.parSpreadBp, spec.bp, accuracy: 1.0,
                           "\(spec.label) (\(spec.bp) bp): parSpread round-trip mismatch")
            XCTAssertGreaterThan(r.upfrontDollars, prevUpfront,
                                 "\(spec.label) (\(spec.bp) bp): chip grid must be monotonic in upfront")
            prevUpfront = r.upfrontDollars
        }
    }

    /// With a 500 bp coupon the three below-par chips (-200, -100, -50) are
    /// all visible. Each should produce a buyer-receives upfront of the right
    /// magnitude ordering: -200 most negative, -50 least negative.
    func testChipGridBelowParChipsHighCoupon() {
        let coupon = 500.0
        let chips: [(bp: Double, label: String)] = [
            (300, "Coupon -200"),  // most below par → most buyer-receives
            (400, "Coupon -100"),
            (450, "Coupon -50"),   // least below par
        ]
        var prevUpfront: Double = -.infinity
        for spec in chips {
            let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                            parSpreadBp: spec.bp, couponBp: coupon,
                                            recoveryRate: 0.40, notional: 10_000_000,
                                            isBuy: true)!
            XCTAssertLessThan(r.upfrontDollars, -1.0,
                              "\(spec.label) (\(spec.bp) bp): buyer should receive on a 500 bp coupon")
            XCTAssertGreaterThan(r.upfrontDollars, prevUpfront,
                                 "\(spec.label) (\(spec.bp) bp): below-par chips must be monotonic")
            prevUpfront = r.upfrontDollars
            XCTAssertEqual(r.parSpreadBp, spec.bp, accuracy: 1.0,
                           "\(spec.label) (\(spec.bp) bp): parSpread round-trip mismatch")
        }
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

    /// SNAC convention pin: accrued endpoint is stepinDate (T+1 calendar),
    /// not T. This regression test guards against re-introducing the
    /// off-by-one that historically displayed (T - prevIMM) days instead
    /// of (stepinDate - prevIMM) days.
    ///
    /// For refDate = 2024-04-15 (Mon):
    ///   stepinDate    = 2024-04-16 (T + 1 calendar)
    ///   prevIMM       = 2024-03-20
    ///   day count ACT = 27 days
    ///   accrued       = $10M × 1% × 27/360 = $7,500
    func testAccruedUsesStepinDateNotTradeDate() {
        let r = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                        parSpreadBp: 100, couponBp: 100,
                                        recoveryRate: 0.40, notional: 10_000_000, isBuy: true)!
        let expected = 10_000_000.0 * 0.01 * 27.0 / 360.0
        XCTAssertEqual(r.accrued, expected, accuracy: 0.01,
                       "Accrued must be (stepinDate - prevIMM)/360 × coupon × notional, "
                       + "= 27/360 days for refDate. Off-by-one if it equals $7,222.22 (= 26 days, T-prevIMM).")
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

    func testAllRegionsAtParCouponAreExactlyZero() {
        // SNAC invariant for every region × coupon: par spread → $0 upfront (tight tolerance)
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
                XCTAssertEqual(r!.upfrontFraction, 0.0, accuracy: 0.00001,
                               "\(contract.region) coupon=\(coupon)bp at-par upfront must be $0, not a residual")
            }
        }
    }

    // MARK: - Holiday Calendar: nyFed (US Federal Reserve)

    func testNYFedMLKDayIsHoliday() {
        // 3rd Monday January 2025 = Jan 20
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,1,20), calendarName: "nyFed"))
    }

    func testNYFedMemorialDayIsHoliday() {
        // Last Monday May 2025 = May 26
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,5,26), calendarName: "nyFed"))
    }

    func testNYFedIndependenceDayIsHoliday() {
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,7,4), calendarName: "nyFed"))
    }

    func testNYFedThanksgivingIsHoliday() {
        // 4th Thursday November 2025 = Nov 27
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,11,27), calendarName: "nyFed"))
    }

    func testNYFedGoodFridayIsNOTHoliday() {
        // Good Friday is NYSE but NOT Federal Reserve — key CDS convention distinction
        XCTAssertTrue(CDSHolidayCalendar.isBusinessDay(d(2025,4,18), calendarName: "nyFed"))
    }

    func testNYFedRegularWednesdayIsBusinessDay() {
        XCTAssertTrue(CDSHolidayCalendar.isBusinessDay(d(2025,3,12), calendarName: "nyFed"))
    }

    // MARK: - Holiday Calendar: TARGET (ECB)

    func testTargetGoodFridayIsHoliday() {
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,4,18), calendarName: "target"))
    }

    func testTargetEasterMondayIsHoliday() {
        // Easter 2025 = April 20; Easter Monday = April 21
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,4,21), calendarName: "target"))
    }

    func testTargetMayDayIsHoliday() {
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,5,1), calendarName: "target"))
    }

    func testTargetBoxingDayIsHoliday() {
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,12,26), calendarName: "target"))
    }

    func testGoodFridayDiffersAcrossCalendars() {
        // Good Friday Apr 18 2025: TARGET holiday, nyFed is open — key EU vs NA difference
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,4,18), calendarName: "target"))
        XCTAssertTrue( CDSHolidayCalendar.isBusinessDay(d(2025,4,18), calendarName: "nyFed"))
    }

    // MARK: - Holiday Calendar: Tokyo (TSE)

    func testTokyoComingOfAgeDayIsHoliday() {
        // 2nd Monday January 2025 = Jan 13
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,1,13), calendarName: "tokyo"))
    }

    func testTokyoGoldenWeekIsHoliday() {
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,5,3), calendarName: "tokyo"))
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,5,5), calendarName: "tokyo"))
    }

    func testTokyoYearEndIsHoliday() {
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,12,31), calendarName: "tokyo"))
    }

    func testTokyoRegularDayIsBusinessDay() {
        XCTAssertTrue(CDSHolidayCalendar.isBusinessDay(d(2025,3,12), calendarName: "tokyo"))
    }

    // MARK: - Holiday Calendar: Sydney (ASX/NSW)

    func testSydneyAustraliaDayObservedMonday() {
        // Jan 26 2025 is Sunday → observed Monday Jan 27 is the public holiday
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,1,27), calendarName: "sydney"))
        XCTAssertTrue( CDSHolidayCalendar.isBusinessDay(d(2025,1,28), calendarName: "sydney"))
    }

    func testSydneyGoodFridayIsHoliday() {
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,4,18), calendarName: "sydney"))
    }

    func testSydneyANZACDayIsHoliday() {
        // Apr 25 2025 = Friday
        XCTAssertFalse(CDSHolidayCalendar.isBusinessDay(d(2025,4,25), calendarName: "sydney"))
    }

    // MARK: - Last Valid Trade Date

    func testLastValidTradeDateSaturdaySnapsToFriday() {
        let last = CDSCalculator.lastValidTradeDate(on: d(2025,4,5), calendarName: "nyFed")
        XCTAssertEqual(isoDay(last), "2025-04-04")
    }

    func testLastValidTradeDateSundaySnapsToFriday() {
        let last = CDSCalculator.lastValidTradeDate(on: d(2025,4,6), calendarName: "nyFed")
        XCTAssertEqual(isoDay(last), "2025-04-04")
    }

    func testLastValidTradeDateNYFedHolidaySnapsBack() {
        // MLK Day Jan 20 2025 (Monday) → last valid = Friday Jan 17
        let last = CDSCalculator.lastValidTradeDate(on: d(2025,1,20), calendarName: "nyFed")
        XCTAssertEqual(isoDay(last), "2025-01-17")
    }

    func testLastValidTradeDateTargetGoodFridaySnapsToThursday() {
        // Good Friday Apr 18 2025 is TARGET holiday → last valid = Thursday Apr 17
        let last = CDSCalculator.lastValidTradeDate(on: d(2025,4,18), calendarName: "target")
        XCTAssertEqual(isoDay(last), "2025-04-17")
    }

    func testLastValidTradeDateRegularDayUnchanged() {
        let last = CDSCalculator.lastValidTradeDate(on: d(2025,3,12), calendarName: "nyFed")
        XCTAssertEqual(isoDay(last), "2025-03-12")
    }

    func testLastValidTradeDateNYFedOpenOnGoodFriday() {
        // Good Friday is NOT a nyFed holiday → trade date stays Apr 18
        let last = CDSCalculator.lastValidTradeDate(on: d(2025,4,18), calendarName: "nyFed")
        XCTAssertEqual(isoDay(last), "2025-04-18")
    }

    // MARK: - Discount Rate Effect on Calculation

    func testHigherDiscountRateReducesUpfrontAboveCoupon() {
        // Higher discount rate → lower risky annuity → lower (spread−coupon)×annuity → lower upfront
        let lo = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                         parSpreadBp: 300, couponBp: 100,
                                         recoveryRate: 0.40, notional: 10_000_000,
                                         isBuy: true, discountRate: 0.02)!
        let hi = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                         parSpreadBp: 300, couponBp: 100,
                                         recoveryRate: 0.40, notional: 10_000_000,
                                         isBuy: true, discountRate: 0.08)!
        XCTAssertGreaterThan(lo.upfrontDollars, hi.upfrontDollars)
    }

    func testAtParSpreadIsExactlyZeroRegardlessOfDiscountRate() {
        // Discount rate affects risky annuity, but hazard rate re-calibrates → upfront stays $0
        let lo = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                         parSpreadBp: 100, couponBp: 100,
                                         recoveryRate: 0.40, notional: 10_000_000,
                                         isBuy: true, discountRate: 0.02)!
        let hi = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 5,
                                         parSpreadBp: 100, couponBp: 100,
                                         recoveryRate: 0.40, notional: 10_000_000,
                                         isBuy: true, discountRate: 0.08)!
        XCTAssertEqual(lo.upfrontFraction, 0.0, accuracy: 0.00001)
        XCTAssertEqual(hi.upfrontFraction, 0.0, accuracy: 0.00001)
    }

    func testDiscountRateImpactSignificantFor10YTenor() {
        // 10Y: 1% vs 10% discount rate should produce > 1% upfront difference
        let lo = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 10,
                                         parSpreadBp: 200, couponBp: 100,
                                         recoveryRate: 0.40, notional: 10_000_000,
                                         isBuy: true, discountRate: 0.01)!
        let hi = CDSCalculator.calculate(tradeDate: refDate, tenorYears: 10,
                                         parSpreadBp: 200, couponBp: 100,
                                         recoveryRate: 0.40, notional: 10_000_000,
                                         isBuy: true, discountRate: 0.10)!
        XCTAssertGreaterThan(abs(lo.upfrontFraction - hi.upfrontFraction), 0.01)
    }

    // MARK: - SOFR Network (live — skipped gracefully if offline)

    func testSOFRFetchLatestReturnsPlausibleRate() async {
        let (rate, date) = await SOFRFetcher.fetchLatest()
        guard date != "unavailable" else { return }
        XCTAssertGreaterThan(rate, 0.001, "SOFR should be > 0.1%")
        XCTAssertLessThan(rate, 0.20,    "SOFR should be < 20%")
    }

    func testSOFRFetchLatestDateFormatIsISO() async {
        let (_, effectiveDate) = await SOFRFetcher.fetchLatest()
        guard effectiveDate != "unavailable" else { return }
        let parts = effectiveDate.split(separator: "-")
        XCTAssertEqual(parts.count, 3)
        XCTAssertEqual(parts[0].count, 4, "Year should be 4 digits")
        XCTAssertEqual(parts[1].count, 2, "Month should be 2 digits")
        XCTAssertEqual(parts[2].count, 2, "Day should be 2 digits")
    }

    func testSOFRFetchForDateOnOrBeforeTarget() async {
        let today = Date()
        let (rate, effectiveDate) = await SOFRFetcher.fetchForDate(today)
        guard effectiveDate != "unavailable" else { return }
        XCTAssertGreaterThan(rate, 0.001)
        XCTAssertLessThanOrEqual(effectiveDate, isoDay(today),
                                  "Returned SOFR date must be on or before requested date")
    }

    func testSOFRFetchForRecentWeekendReturnsPriorBusinessDay() async {
        // Find the most recent Saturday and verify SOFR date is before it
        let cal = Calendar.current
        var sat = Date()
        while cal.component(.weekday, from: sat) != 7 {
            sat = cal.date(byAdding: .day, value: -1, to: sat)!
        }
        let (_, effectiveDate) = await SOFRFetcher.fetchForDate(sat)
        guard effectiveDate != "unavailable" else { return }
        XCTAssertLessThan(effectiveDate, isoDay(sat),
                           "Weekend fetch should return a prior weekday SOFR date")
    }

    // MARK: - Helpers

    private func d(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var c = DateComponents(); c.year = year; c.month = month; c.day = day
        return Calendar.current.date(from: c)!
    }

    private func isoDay(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: date)
    }

    // MARK: - Settle Date: Full Calendar Accuracy
    // These tests verify that addBusinessDays and calculate() use the full
    // holiday calendar (not just weekends) for settle date computation.

    func testSettleDateSkipsNYFedMemorialDay() {
        // May 23 2025 (Fri) + T+1 nyFed: weekends-only → May 26 (Memorial Day, wrong)
        //                                 full calendar  → May 27 (correct)
        XCTAssertEqual(isoDay(CDSCalculator.addBusinessDays(1, to: d(2025,5,23), calendarName: "nyFed")),
                       "2025-05-27", "T+1 settle should skip Memorial Day May 26")
    }

    func testSettleDateSkipsTARGETGoodFridayAndEasterMonday() {
        // Thu Apr 17 2025 + T+1 TARGET: Apr 18=Good Friday, Apr 21=Easter Monday → Apr 22
        XCTAssertEqual(isoDay(CDSCalculator.addBusinessDays(1, to: d(2025,4,17), calendarName: "target")),
                       "2025-04-22", "T+1 TARGET settle should skip Good Friday and Easter Monday")
    }

    func testSettleDateT3ForEM() {
        // Mon Apr 14 2025 + T+3 nyFed → April 17 (Thu)
        XCTAssertEqual(isoDay(CDSCalculator.addBusinessDays(3, to: d(2025,4,14), calendarName: "nyFed")),
                       "2025-04-17")
    }

    func testCalculateValueDateReflectsHolidayCalendar() {
        // End-to-end: CDSResult.valueDate must skip Memorial Day May 26 2025
        let r = CDSCalculator.calculate(tradeDate: d(2025,5,23), tenorYears: 5,
                                         parSpreadBp: 100, couponBp: 100,
                                         recoveryRate: 0.40, notional: 10_000_000,
                                         isBuy: true, settleDays: 1,
                                         calendarName: "nyFed")!
        var mdy = TMonthDayYear()
        JpmcdsDateToMDY(r.valueDate, &mdy)
        XCTAssertEqual(mdy.month, 5)
        XCTAssertEqual(mdy.day,   27)   // skips Sat, Sun, Memorial Day
        XCTAssertEqual(mdy.year,  2025)
    }

    func testCalculateValueDateTARGETSkipsEasterCluster() {
        // End-to-end for EU: settle on Thursday before Easter skips 4 days
        let r = CDSCalculator.calculate(tradeDate: d(2025,4,17), tenorYears: 5,
                                         parSpreadBp: 100, couponBp: 100,
                                         recoveryRate: 0.40, notional: 10_000_000,
                                         isBuy: true, settleDays: 1,
                                         calendarName: "target")!
        var mdy = TMonthDayYear()
        JpmcdsDateToMDY(r.valueDate, &mdy)
        XCTAssertEqual(mdy.month, 4)
        XCTAssertEqual(mdy.day,   22)   // skips Good Fri, Sat, Sun, Easter Mon
        XCTAssertEqual(mdy.year,  2025)
    }

    // MARK: - FeeViewModel Async Init Flow

    @MainActor
    func testFeeViewModelResultIsNilBeforeAsyncInit() {
        let vm = FeeViewModel()
        XCTAssertNil(vm.result, "result must be nil until the @MainActor Task completes")
    }

    @MainActor
    func testFeeViewModelResultNonNilAfterAsyncInit() async throws {
        let vm = FeeViewModel()
        XCTAssertNil(vm.result, "result starts nil")
        // 1s covers prewarm (~50-200ms) + calendar snap + recalculate
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertNotNil(vm.result, "result should be available after async init task")
    }

    @MainActor
    func testFeeViewModelTradeDateIsBusinessDay() async throws {
        let vm = FeeViewModel()
        // Allow the trade-date snap Task to run
        try await Task.sleep(nanoseconds: 500_000_000)
        let region = vm.contract?.calendarName ?? "nyFed"
        XCTAssertTrue(CDSHolidayCalendar.isBusinessDay(vm.tradeDate, calendarName: region),
                      "FeeViewModel trade date must be a valid business day after async init")
    }

    @MainActor
    func testFeeViewModelResultUpdatesAfterSOFRFetch() async throws {
        let vm = FeeViewModel()
        try await Task.sleep(nanoseconds: 1_000_000_000)  // let init Task complete
        guard let r1 = vm.result else { XCTFail("No initial result"); return }

        // Trigger a new SOFR fetch; result should remain valid (may update if live rate differs)
        SOFRRateStore.shared.updateForTradeDate(vm.tradeDate)
        try await Task.sleep(nanoseconds: 1_000_000_000)  // allow fetch + recalculate

        XCTAssertNotNil(vm.result, "result should remain non-nil after SOFR refresh")
        // Price should always be in a sane range regardless of rate
        XCTAssertGreaterThan(vm.result!.price, 50.0)
        XCTAssertLessThan(vm.result!.price, 120.0)
        // par spread should approximately equal the input spread
        XCTAssertEqual(vm.result!.parSpreadBp, r1.parSpreadBp, accuracy: 2.0)
    }

    // MARK: - FeeViewModel spread initialization

    @MainActor
    func testFeeViewModelSpreadBpIsPositiveAtInit() {
        let vm = FeeViewModel()
        XCTAssertGreaterThan(vm.spreadBp, 0,
            "spreadBp must never be 0 at init — that would open the picker showing 0 bp")
    }

    @MainActor
    func testFeeViewModelSpreadBpMatchesDefaultCouponAtInit() {
        let vm = FeeViewModel()
        // Synced in init() so the spread input is meaningful before the user
        // touches the coupon segmented control. Without this, switching
        // coupon was the only way to populate a real spread value.
        XCTAssertEqual(vm.spreadBp, vm.couponBp, accuracy: 0.001,
            "spreadBp at init should equal the default contract's first coupon")
    }

    @MainActor
    func testFeeViewModelPreviewUpfrontUsesCurrentSpread() async throws {
        let vm = FeeViewModel()
        try await Task.sleep(nanoseconds: 1_000_000_000)  // let async init finish
        // At par (spread == coupon) the upfront should be ~0.
        let atPar = vm.previewUpfront(forSpread: vm.couponBp)
        XCTAssertNotNil(atPar)
        XCTAssertLessThan(abs(atPar!.upfrontDollars), 1.0,
            "preview at par should produce zero upfront")

        // At spread well above coupon, buyer of protection pays a positive upfront.
        let wide = vm.previewUpfront(forSpread: vm.couponBp + 200)
        XCTAssertNotNil(wide)
        XCTAssertGreaterThan(wide!.upfrontDollars, 0)
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
