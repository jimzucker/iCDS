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

    private var sofrRate: Double = SOFRFetcher.fallbackRate
    private var sofrEffectiveDate: String = "fallback"
    
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

        Task { @MainActor in
            let (rate, date) = await SOFRFetcher.fetchLatest()
            sofrRate = rate
            sofrEffectiveDate = date
            print("SOFR: \(String(format: "%.4f%%", rate * 100)) as of \(date)")
            reCalc()
        }
    }

    private func formatDate(_ tdate: TDate) -> String {
        var mdy = TMonthDayYear()
        JpmcdsDateToMDY(tdate, &mdy)
        return String(format: "%02d-%02d-%04d", mdy.month, mdy.day, mdy.year)
    }

    func reCalc() {
        let cal = Calendar.current
        let tradeDate = cal.date(byAdding: .day, value: Int(TradeDateStepper?.value ?? 0), to: Date()) ?? Date()

        let spreadText = TradeBpLabel.text?.replacingOccurrences(of: " bp", with: "") ?? "100"
        let parSpreadBp = Double(spreadText) ?? 100.0
        let couponBp    = Double(CouponControl.titleForSegment(at: CouponControl.selectedSegmentIndex) ?? "100") ?? 100.0

        let contract    = isdaContracts[ContractRegionController.selectedSegmentIndex]
        let recovery    = Double(contract.recoveryList[RecoveryControl.selectedSegmentIndex].recovery) / 100.0

        let notionalMap = ["1M": 1_000_000.0, "5M": 5_000_000.0, "10M": 10_000_000.0, "20M": 20_000_000.0]
        let notional    = notionalMap[NotionalControl.titleForSegment(at: NotionalControl.selectedSegmentIndex) ?? "10M"] ?? 10_000_000.0
        let isBuy       = BuySellControl.selectedSegmentIndex == 0
        let tenors      = [1, 5, 7, 10]
        let tenorYears  = tenors[MaturityControl.selectedSegmentIndex]

        guard let r = CDSCalculator.calculate(tradeDate: tradeDate, tenorYears: tenorYears,
                                              parSpreadBp: parSpreadBp, couponBp: couponBp,
                                              recoveryRate: recovery, notional: notional,
                                              isBuy: isBuy, discountRate: sofrRate) else {
            CalculatedFeeLabel.text = "Calc Err"
            return
        }

        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.maximumFractionDigits = 0
        fmt.currencyCode = CurrencyLabel.text ?? "USD"

        let bpFmt = NumberFormatter()
        bpFmt.numberStyle = .decimal
        bpFmt.maximumFractionDigits = 1

        CalculatedFeeLabel.text = fmt.string(from: NSNumber(value: r.upfrontDollars)) ?? String(format: "%.0f", r.upfrontDollars)
        AccruedIntField?.text   = fmt.string(from: NSNumber(value: r.accrued))
        UpfrontBpField.text     = (bpFmt.string(from: NSNumber(value: r.upfrontBp)) ?? String(format: "%.1f", r.upfrontBp)) + " bp"
        PriceField.text         = String(format: "%.4f", r.price)
        StartDateField.text     = formatDate(r.startDate)
        SettleDateField?.text   = formatDate(r.valueDate)
        CalcSpreadField.text    = String(format: "%.0f bp", r.parSpreadBp)

        print("Upfront: \(r.upfrontDollars) (\(r.upfrontBp) bp)  Price: \(r.price)  Par: \(r.parSpreadBp) bp")
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

