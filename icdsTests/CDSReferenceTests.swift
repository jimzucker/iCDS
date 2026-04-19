//
//  CDSReferenceTests.swift
//  icdsTests
//
//  Validates CDS upfront charge calculation against the QuantLib ISDA engine test
//  Reference: QuantLib test-suite/creditdefaultswap.cpp :: testIsdaEngine
//  Trade date: May 21 2009 — same IR curve, same CDS params, same expected NPV values
//
//  Copyright © 2024 Strategic Software Engineering LLC. All rights reserved.
//

import XCTest
@testable import icds

class CDSReferenceTests: XCTestCase {

    // -----------------------------------------------------------------------
    // QuantLib May 21 2009 USD IR curve
    // Deposits: 1M 2M 3M 6M 9M 12M
    // Swaps:    2Y 3Y 4Y 5Y 6Y 7Y 8Y 9Y 10Y 12Y 15Y 20Y 25Y 30Y
    // -----------------------------------------------------------------------
    private let depositMaturities = ["1M","2M","3M","6M","9M","1Y"]
    private let depositRates = [0.003081, 0.005525, 0.007163, 0.012413, 0.014000, 0.015488]
    private let swapMaturities   = ["2Y","3Y","4Y","5Y","6Y","7Y","8Y","9Y","10Y","12Y","15Y","20Y","25Y","30Y"]
    private let swapRates        = [0.011907, 0.016990, 0.021198, 0.024440, 0.026937, 0.028967,
                                    0.030504, 0.031719, 0.032790, 0.034535, 0.036217, 0.036981,
                                    0.037246, 0.037605]

    // Convenience: build the QuantLib test discount curve
    private func buildQuantLibCurve(valueDate: TDate) -> UnsafeMutablePointer<TCurve>? {
        let allMaturities = depositMaturities + swapMaturities
        let allRates      = depositRates + swapRates
        let types         = String(repeating: "M", count: depositMaturities.count) +
                            String(repeating: "S", count: swapMaturities.count)
        let nInstr        = Int32(allMaturities.count)

        var cMat: [UnsafeMutablePointer<CChar>?] = allMaturities.map { strdup($0) }
        var cRates = allRates
        let holidays = strdup("None")
        let mmDCC    = strdup("Act/360")
        let fixDCC   = strdup("30/360")
        let floatDCC = strdup("Act/360")
        let fixFreq  = strdup("6M")
        let floatFreq = strdup("3M")
        let typesStr  = strdup(types)
        defer {
            cMat.forEach { free($0) }
            free(holidays); free(mmDCC); free(fixDCC); free(floatDCC)
            free(fixFreq); free(floatFreq); free(typesStr)
        }

        // Convert tenor strings to TDates
        var dates = [TDate](repeating: 0, count: allMaturities.count)
        let routine = strdup("test")
        defer { free(routine) }
        for i in 0..<allMaturities.count {
            var ivl = TDateInterval()
            JpmcdsStringToDateInterval(cMat[i], routine, &ivl)
            JpmcdsDateFwdThenAdjust(valueDate, &ivl, Int(UInt8(ascii: "N")), holidays, &dates[i])
        }

        return JpmcdsBuildIRZeroCurve(
            valueDate,
            typesStr,
            &dates,
            &cRates,
            nInstr,
            3,      // JPMCDS_ACT_360
            2,      // fixed semi-annual
            4,      // float quarterly
            4,      // JPMCDS_B30_360
            3,      // JPMCDS_ACT_360
            Int(UInt8(ascii: "M")),  // modified following
            holidays
        )
    }

    // -----------------------------------------------------------------------
    // Compute upfront fraction using JpmcdsCdsoneUpfrontCharge directly
    // with the QuantLib IR curve
    // -----------------------------------------------------------------------
    private func upfront(tradeDate: TDate, valueDate: TDate, stepinDate: TDate,
                         startDate: TDate, endDate: TDate,
                         couponBp: Double, spreadBp: Double, recovery: Double,
                         notional: Double) -> Double? {

        guard let curve = buildQuantLibCurve(valueDate: valueDate) else { return nil }
        defer { JpmcdsFreeTCurve(curve) }

        var ivl = TDateInterval()
        ivl.prd = 3; ivl.prd_typ = Int8(bitPattern: UInt8(ascii: "M")); ivl.flag = 0

        var stub = TStubMethod()
        stub.stubAtEnd = 0; stub.longStub = 0

        let cal = strdup("None")
        defer { free(cal) }

        var result = 0.0
        let status = JpmcdsCdsoneUpfrontCharge(
            tradeDate, valueDate, startDate, stepinDate,
            startDate, endDate,
            couponBp / 10000.0, 1,
            &ivl, &stub,
            JPMCDS_ACT_360, Int(UInt8(ascii: "F")),
            cal, curve,
            spreadBp / 10000.0, recovery, 0,
            &result
        )
        return status == SUCCESS ? result : nil
    }

    // -----------------------------------------------------------------------
    // Reference dates: May 21 2009 trade
    //   value date  = T+3 business = May 26 2009
    //   stepin date = T+1 calendar = May 22 2009
    //   start date  = prev IMM     = Mar 20 2009
    // -----------------------------------------------------------------------
    let tradeDate  = JpmcdsDate(2009, 5, 21)
    let valueDate  = JpmcdsDate(2009, 5, 26)
    let stepinDate = JpmcdsDate(2009, 5, 22)
    let startDate  = JpmcdsDate(2009, 3, 20)   // previous IMM

    // QuantLib NPV values (protection buyer perspective, notional 10M)
    // Source: QuantLib test-suite/creditdefaultswap.cpp markitValues[]
    // Relationship: ISDA upfrontCharge ≈ QuantLib NPV / notional
    // Tolerance 5% to allow for clean/dirty and date-handling differences

    // MARK: - 1Y maturity (end Jun 20 2010)

    func test1Y_spread10bp_recovery40() {
        let end = JpmcdsDate(2010, 6, 20)
        guard let u = upfront(tradeDate: tradeDate, valueDate: valueDate, stepinDate: stepinDate,
                               startDate: startDate, endDate: end,
                               couponBp: 100, spreadBp: 10, recovery: 0.40,
                               notional: 10_000_000) else { XCTFail("Calc failed"); return }
        // QuantLib NPV = -97,776.12  →  fraction ≈ -0.009778
        let qlFraction = -97776.11889 / 10_000_000.0
        XCTAssertEqual(u, qlFraction, accuracy: abs(qlFraction) * 0.05,
                       "1Y 10bp spread R=40% upfront should match QuantLib within 5%")
    }

    func test1Y_spread1000bp_recovery40() {
        let end = JpmcdsDate(2010, 6, 20)
        guard let u = upfront(tradeDate: tradeDate, valueDate: valueDate, stepinDate: stepinDate,
                               startDate: startDate, endDate: end,
                               couponBp: 100, spreadBp: 1000, recovery: 0.40,
                               notional: 10_000_000) else { XCTFail("Calc failed"); return }
        // QuantLib NPV = +894,985.63  →  fraction ≈ +0.089499
        let qlFraction = 894985.6298 / 10_000_000.0
        XCTAssertEqual(u, qlFraction, accuracy: abs(qlFraction) * 0.05,
                       "1Y 1000bp spread R=40% upfront should match QuantLib within 5%")
    }

    func test1Y_spread10bp_recovery20() {
        let end = JpmcdsDate(2010, 6, 20)
        guard let u = upfront(tradeDate: tradeDate, valueDate: valueDate, stepinDate: stepinDate,
                               startDate: startDate, endDate: end,
                               couponBp: 100, spreadBp: 10, recovery: 0.20,
                               notional: 10_000_000) else { XCTFail("Calc failed"); return }
        let qlFraction = -97798.29358 / 10_000_000.0
        XCTAssertEqual(u, qlFraction, accuracy: abs(qlFraction) * 0.05)
    }

    // MARK: - 2Y maturity (end Jun 20 2011)

    func test2Y_spread10bp_recovery40() {
        let end = JpmcdsDate(2011, 6, 20)
        guard let u = upfront(tradeDate: tradeDate, valueDate: valueDate, stepinDate: stepinDate,
                               startDate: startDate, endDate: end,
                               couponBp: 100, spreadBp: 10, recovery: 0.40,
                               notional: 10_000_000) else { XCTFail("Calc failed"); return }
        let qlFraction = -186839.8148 / 10_000_000.0
        XCTAssertEqual(u, qlFraction, accuracy: abs(qlFraction) * 0.05)
    }

    func test2Y_spread1000bp_recovery40() {
        let end = JpmcdsDate(2011, 6, 20)
        guard let u = upfront(tradeDate: tradeDate, valueDate: valueDate, stepinDate: stepinDate,
                               startDate: startDate, endDate: end,
                               couponBp: 100, spreadBp: 1000, recovery: 0.40,
                               notional: 10_000_000) else { XCTFail("Calc failed"); return }
        let qlFraction = 1579803.626 / 10_000_000.0
        XCTAssertEqual(u, qlFraction, accuracy: abs(qlFraction) * 0.05)
    }

    // MARK: - 5Y maturity (end Jun 20 2014)

    func test5Y_spread10bp_recovery40() {
        let end = JpmcdsDate(2014, 6, 20)
        guard let u = upfront(tradeDate: tradeDate, valueDate: valueDate, stepinDate: stepinDate,
                               startDate: startDate, endDate: end,
                               couponBp: 100, spreadBp: 10, recovery: 0.40,
                               notional: 10_000_000) else { XCTFail("Calc failed"); return }
        let qlFraction = -274122.4725 / 10_000_000.0
        XCTAssertEqual(u, qlFraction, accuracy: abs(qlFraction) * 0.05)
    }

    func test5Y_spread1000bp_recovery40() {
        let end = JpmcdsDate(2014, 6, 20)
        guard let u = upfront(tradeDate: tradeDate, valueDate: valueDate, stepinDate: stepinDate,
                               startDate: startDate, endDate: end,
                               couponBp: 100, spreadBp: 1000, recovery: 0.40,
                               notional: 10_000_000) else { XCTFail("Calc failed"); return }
        let qlFraction = 2147972.527 / 10_000_000.0
        XCTAssertEqual(u, qlFraction, accuracy: abs(qlFraction) * 0.05)
    }

    // MARK: - 10Y maturity (end Jun 20 2019)

    func test10Y_spread10bp_recovery40() {
        let end = JpmcdsDate(2019, 6, 20)
        guard let u = upfront(tradeDate: tradeDate, valueDate: valueDate, stepinDate: stepinDate,
                               startDate: startDate, endDate: end,
                               couponBp: 100, spreadBp: 10, recovery: 0.40,
                               notional: 10_000_000) else { XCTFail("Calc failed"); return }
        let qlFraction = -591571.2294 / 10_000_000.0
        XCTAssertEqual(u, qlFraction, accuracy: abs(qlFraction) * 0.05)
    }

    func test10Y_spread1000bp_recovery40() {
        let end = JpmcdsDate(2019, 6, 20)
        guard let u = upfront(tradeDate: tradeDate, valueDate: valueDate, stepinDate: stepinDate,
                               startDate: startDate, endDate: end,
                               couponBp: 100, spreadBp: 1000, recovery: 0.40,
                               notional: 10_000_000) else { XCTFail("Calc failed"); return }
        let qlFraction = 3545843.418 / 10_000_000.0
        XCTAssertEqual(u, qlFraction, accuracy: abs(qlFraction) * 0.05)
    }
}
