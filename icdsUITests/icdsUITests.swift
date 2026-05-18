//
//  icdsUITests.swift
//  icdsUITests
//
//  Created by Jim Zucker on 5/10/16.
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//

import XCTest

class icdsUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    /// Capture App Store screenshots in 6 states.
    /// Run with:
    ///   xcodebuild ... -only-testing:icdsUITests/icdsUITests/testCaptureAppStoreScreenshots
    /// Then extract PNGs from the xcresult bundle via xcresulttool.
    func testCaptureAppStoreScreenshots() {
        let app = XCUIApplication()
        // app was launched in setUp()
        sleep(2) // let initial RFR fetches settle so curves screenshot is meaningful

        // 01 — Calc tab at par (default state on launch: 5Y, 100 bp coupon, 100 bp spread)
        capture(named: "01_calc_par")

        // 03 — Spread picker open at distressed value (1100 bp). Tap the QUOTED SPREAD card.
        let spreadCard = app.buttons.matching(NSPredicate(format: "label CONTAINS 'QUOTED SPREAD'")).firstMatch
        XCTAssertTrue(spreadCard.waitForExistence(timeout: 3), "QUOTED SPREAD card not found")
        spreadCard.tap()

        // Tap "Coupon +1,000" chip (sets spread = coupon + 1000 = 1100 bp)
        let chip = app.buttons["Coupon +1,000"]
        XCTAssertTrue(chip.waitForExistence(timeout: 3), "Coupon +1,000 chip not found")
        chip.tap()
        sleep(1)
        capture(named: "03_spread_picker")

        // 02 — Calc tab distressed: tap Done, capture
        app.buttons["Done"].tap()
        sleep(1)
        capture(named: "02_calc_distressed")

        // 04 — Curves tab (USD selected by default, shows LIVE)
        app.tabBars.buttons["Curves"].tap()
        sleep(2) // RFR rates may finish fetching
        capture(named: "04_curves")

        // 05 — Info tab
        app.tabBars.buttons["Info"].tap()
        sleep(1)
        capture(named: "05_info")

        // 06 — Diag tab
        app.tabBars.buttons["Diag"].tap()
        sleep(2) // let any diag tests render
        capture(named: "06_diag")
    }

    private func capture(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
