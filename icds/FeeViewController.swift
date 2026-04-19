//
//  FeeViewController.swift
//  icds
//
//  Created by Jim Zucker on 5/10/16.
//  Copyright © 2016-2026 James A. Zucker All rights reserved.
//

import UIKit

class FeeViewController: UIViewController {

    @IBOutlet weak var ContractRegionController: UISegmentedControl!
    
    //Trading Spread
    @IBOutlet weak var TradeBpLabel: UITextField!
    @IBOutlet weak var TradeBpStepper: UIStepper!
    @IBOutlet weak var TradeBpSlider: UISlider!
    
    //TradeDate
    @IBOutlet weak var TradeDateLabel: UITextField!
    @IBOutlet weak var TradeDateStepper: UIStepper!
    
    //Terms
    @IBOutlet weak var BuySellControl: UISegmentedControl!
    @IBOutlet weak var NotionalControl: UISegmentedControl!
    @IBOutlet weak var MaturityControl: UISegmentedControl!
    
    //Coupon
    @IBOutlet weak var CouponControl: UISegmentedControl!
    
    @IBOutlet weak var CurrencyLabel: UITextField!
    @IBOutlet weak var CurrencyStepper: UIStepper!
    let usdCurrency = "USD"
    var CurrencyList = ["EUR", "GBP", "USD"]

    //Recovery
    @IBOutlet weak var RecoveryControl: UISegmentedControl!
    @IBOutlet weak var RecoveryLabel: UITextField!
    
    //UpFront Fee
    @IBOutlet weak var CalculatedFeeLabel: UITextField!
    
    //Buttons
    @IBOutlet weak var CurrencyBtn: UIButton!
    @IBOutlet weak var EmailBtn: UIButton!
    
    //Outputs
    @IBOutlet weak var AccruedIntField: UITextField!
    @IBOutlet weak var CalcSpreadField: UITextField!
    @IBOutlet weak var StartDateField: UITextField!
    @IBOutlet weak var SettleDateField: UITextField!
    @IBOutlet weak var PriceField: UITextField!
    @IBOutlet weak var UpfrontBpField: UITextField!
    
    var isdaContracts : [ISDAContract] =  [ISDAContract]()
    
    fileprivate func loadContracts() {
        isdaContracts = ISDAContract.readFromPlist()
    }
    
    fileprivate func configureRegionTerms(contract: ISDAContract) {
        //Configure Recovery
        RecoveryControl.removeAllSegments()
        var i = 0
        for recovery in contract.recoveryList {
            RecoveryControl.insertSegment(withTitle: recovery.subordination, at: i, animated: false)
            i += 1
        }
        RecoveryControl.selectedSegmentIndex = 0
        RecoveryLabel.text = contract.recoveryList[0].recovery.description + "%";
        
        //Configure Coupons
        CouponControl.removeAllSegments()
        i = 0
        for cpn in contract.coupons {
            CouponControl.insertSegment(withTitle: cpn.description, at: i, animated: false)
            i += 1
        }
        CouponControl.selectedSegmentIndex = 0
        TradeBpStepperSetup()
    }
    
    fileprivate func initRegionSelector() {
        ContractRegionController.removeAllSegments()
        var i = 0
        for contract in isdaContracts {
            ContractRegionController.insertSegment(withTitle: contract.region, at: i, animated: false)
            i += 1
        }
        ContractRegionController.selectedSegmentIndex = 0

        //configure the screen based on the region
        configureRegionTerms(contract: isdaContracts[ContractRegionController.selectedSegmentIndex])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Load contract defintions
        loadContracts()

        //setup the Region Select
        initRegionSelector()
        
        //setup Currency
        CurrencyStepper.wraps = true
        CurrencyStepper.autorepeat = true
        CurrencyStepper.maximumValue = Double(CurrencyList.count)-1
        CurrencyStepper.value = Double(CurrencyList.count)-1
        CurrencyLabel.text = usdCurrency

        //setup traded spread
        TradeBpStepper.wraps = false
        TradeBpStepper.autorepeat = true
        TradeBpStepperSetup()
        
        //setup trade date
        let today = Date()
        setTradeDate(today)
        
        CalculatedFeeLabel.textColor = .black

        reCalc()
    }

    private func nextIMMDate(after date: Date) -> TDate {
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

    private func tdate(from date: Date) -> TDate {
        let cal = Calendar.current
        return JpmcdsDate(
            cal.component(.year,  from: date),
            cal.component(.month, from: date),
            cal.component(.day,   from: date))
    }

    private func formatDate(_ tdate: TDate) -> String {
        var mdy = TMonthDayYear()
        JpmcdsDateToMDY(tdate, &mdy)
        return String(format: "%02d-%02d-%04d", mdy.month, mdy.day, mdy.year)
    }

    func reCalc() {
        let cal = Calendar.current

        // Trade date = today offset by stepper value (days; stepper may not be wired in storyboard)
        let tradeDate = cal.date(byAdding: .day, value: Int(TradeDateStepper?.value ?? 0), to: Date()) ?? Date()
        let today      = tdate(from: tradeDate)
        let valueDate  = today + 1   // T+1 settle
        let stepinDate = today + 1
        let benchmarkStart = today
        let startDate  = today

        // End date: next IMM date after (tradeDate + tenor)
        let tenors = [1, 5, 7, 10]
        let tenorYears = tenors[MaturityControl.selectedSegmentIndex]
        let matDate = cal.date(byAdding: .year, value: tenorYears, to: tradeDate) ?? tradeDate
        let endDate = nextIMMDate(after: matDate)

        // Parse spread in bp
        let spreadText = TradeBpLabel.text?.replacingOccurrences(of: " bp", with: "") ?? "100"
        let parSpreadBp = Double(spreadText) ?? 100.0

        // Coupon in bp
        let couponBp = Double(CouponControl.titleForSegment(at: CouponControl.selectedSegmentIndex) ?? "100") ?? 100.0

        // Recovery rate (decimal)
        let contract = isdaContracts[ContractRegionController.selectedSegmentIndex]
        let recoveryPct = contract.recoveryList[RecoveryControl.selectedSegmentIndex].recovery
        let recovery = Double(recoveryPct) / 100.0

        // Notional
        let notionalMap = ["1M": 1_000_000.0, "5M": 5_000_000.0, "10M": 10_000_000.0, "20M": 20_000_000.0]
        let notionalKey = NotionalControl.titleForSegment(at: NotionalControl.selectedSegmentIndex) ?? "10M"
        let notional = notionalMap[notionalKey] ?? 10_000_000.0

        // isBuy: protection buyer pays upfront when spread > coupon
        let isBuy = BuySellControl.selectedSegmentIndex == 0

        // Build flat discount curve (~4.5% continuous, 30-year maturity)
        var curveEndDate = today + 10957
        var flatRate = 0.045
        guard let discCurve = JpmcdsMakeTCurve(today, &curveEndDate, &flatRate, 1,
                                               Double(JPMCDS_CONTINUOUS_BASIS),
                                               JPMCDS_ACT_365F) else {
            CalculatedFeeLabel.text = "Curve Err"
            return
        }
        defer { JpmcdsFreeTCurve(discCurve) }

        // Quarterly payment interval, front short stub (SNAC)
        var dateInterval = TDateInterval()
        dateInterval.prd = 3
        dateInterval.prd_typ = Int8(bitPattern: UInt8(ascii: "M"))
        dateInterval.flag = 0

        var stubMethod = TStubMethod()
        stubMethod.stubAtEnd = 0
        stubMethod.longStub  = 0

        // calendar must be mutable char* — strdup gives UnsafeMutablePointer<CChar>
        let calendar = strdup("None")
        defer { free(calendar) }

        var upfrontFraction = 0.0
        let status = JpmcdsCdsoneUpfrontCharge(
            today, valueDate, benchmarkStart, stepinDate,
            startDate, endDate,
            couponBp / 10000.0,
            1,                               // payAccruedOnDefault = TRUE
            &dateInterval, &stubMethod,
            JPMCDS_ACT_360,
            Int(UInt8(ascii: "F")),          // JPMCDS_BAD_DAY_FOLLOW
            calendar,
            discCurve,
            parSpreadBp / 10000.0,
            recovery,
            0,                               // payAccruedAtStart = FALSE
            &upfrontFraction
        )

        guard status == SUCCESS else {
            CalculatedFeeLabel.text = "Calc Err"
            return
        }

        let signedFraction = isBuy ? upfrontFraction : -upfrontFraction
        let upfrontDollars = signedFraction * notional
        let upfrontBp      = signedFraction * 10_000.0
        let price          = (1.0 - signedFraction) * 100.0

        let prevIMMDate = prevIMM(before: tradeDate)
        let accrualDays = Double(today - tdate(from: prevIMMDate))
        let accrued = (couponBp / 10_000.0) * (accrualDays / 360.0) * notional

        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.maximumFractionDigits = 0
        fmt.currencyCode = CurrencyLabel.text ?? "USD"

        let bpFmt = NumberFormatter()
        bpFmt.numberStyle = .decimal
        bpFmt.maximumFractionDigits = 1

        CalculatedFeeLabel.text  = fmt.string(from: NSNumber(value: upfrontDollars)) ?? String(format: "%.0f", upfrontDollars)
        AccruedIntField?.text   = fmt.string(from: NSNumber(value: accrued))
        UpfrontBpField.text     = (bpFmt.string(from: NSNumber(value: upfrontBp)) ?? String(format: "%.1f", upfrontBp)) + " bp"
        PriceField.text         = String(format: "%.4f", price)
        StartDateField.text     = formatDate(startDate)
        SettleDateField?.text   = formatDate(valueDate)

        var parSpreadResult = 0.0
        JpmcdsCdsoneSpread(
            today, valueDate, benchmarkStart, stepinDate,
            startDate, endDate,
            couponBp / 10000.0,
            1, &dateInterval, &stubMethod,
            JPMCDS_ACT_360, Int(UInt8(ascii: "F")), calendar,
            discCurve, 0.0, recovery, 0, &parSpreadResult
        )
        CalcSpreadField.text = String(format: "%.0f bp", parSpreadResult * 10_000.0)

        print("Upfront: \(upfrontDollars) (\(upfrontBp) bp)  Price: \(price)  Par: \(parSpreadResult*10000) bp")
    }

    private func prevIMM(before date: Date) -> Date {
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

    @IBAction func SegmentControllerChange(_ sender: UISegmentedControl) {
        reCalc()
    }

    @IBAction func ContractRegionControllerChange(_ sender: UISegmentedControl) {
        //configure the screen based on the region
        configureRegionTerms(contract: isdaContracts[sender.selectedSegmentIndex])
        reCalc()
    }
    
    
    @IBAction func RecoveryControllerChange(_ sender: UISegmentedControl) {
        let contract = isdaContracts[ContractRegionController.selectedSegmentIndex]
        let recovery = contract.recoveryList[sender.selectedSegmentIndex].recovery
        RecoveryLabel.text = recovery.description + "%";
        reCalc()
    }
    

    @IBAction func CurrencyStepChange(_ sender: UIStepper) {
        CurrencyLabel.text = String(CurrencyList[Int(sender.value)])
        reCalc()
    }
    
    //is based on setting in CpnBpStepper
    //This sets/resets min/max/value for botht the CpnBp stepper and slider
    func TradeBpStepperSetup()
    {
        //This is setup realative to the Coupon Spread selected
        let couponSpread = Double(CouponControl.titleForSegment(at: CouponControl.selectedSegmentIndex)!)!
 
        //update the labels
        TradeBpLabel.text = Int(couponSpread).description + " bp"

        //setup the stepper
        TradeBpStepper.value = couponSpread
        TradeBpStepper.minimumValue = 1
        TradeBpStepper.maximumValue = couponSpread + 1000

        //setup the slider
        TradeBpSlider.minimumValue = Float(TradeBpStepper.minimumValue)
        TradeBpSlider.maximumValue = Float(TradeBpStepper.maximumValue)
        TradeBpSlider.value = Float(TradeBpStepper.value)
    }
    
    
    @IBAction func TradeBpStepChange(_ sender: UIStepper) {

        //set the label
        let newQuote = sender.value
        TradeBpLabel.text = Int(newQuote).description + " bp"
        
        //sync the slider
        TradeBpSlider.value = Float(TradeBpStepper.value)
        
        reCalc()
    }
    
    @IBAction func TradeBpSliderChange(_ sender: UISlider) {
        let newQuote = Double(sender.value)
        TradeBpLabel.text = Int(newQuote).description + " bp"

            //sync the stepper
        TradeBpStepper.value = newQuote
        reCalc()
    }
    
    
    @IBAction func CouponControllerChange(_ sender: UISegmentedControl) {
        
        //reset the Controls
        TradeBpStepperSetup()
        
        reCalc()
    }
    
    @IBAction func TradeDateStepChange(_ sender: UIStepper) {
        var tradeDate = Date()
        
        let currentCalendar = Calendar.current
        tradeDate = currentCalendar.date(byAdding: .day, value: Int(sender.value), to: tradeDate)!
        
        setTradeDate(tradeDate)
        reCalc()
    }
    
    func setTradeDate( _ tradeDate: Date )
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d-MMM"
        TradeDateLabel.text = dateFormatter.string(from: tradeDate)

    }

}

