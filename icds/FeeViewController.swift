//
//  FeeViewController.swift
//  icds
//
//  Created by Jim Zucker on 5/10/16.
//  Copyright © 2016 Strategic Software Engineering LLC. All rights reserved.
//

import UIKit

class FeeViewController: UIViewController {

    @IBOutlet weak var ContractRegionController: UISegmentedControl!
    
    //Trading Spread
    @IBOutlet weak var TradeBpLabel: UILabel!
    @IBOutlet weak var TradeBpStepper: UIStepper!
    @IBOutlet weak var TradeBpSlider: UISlider!
    
    //TradeDate
    @IBOutlet weak var TradeDateLabel: UILabel!
    @IBOutlet weak var TradeDateStepper: UIStepper!
    
    //Terms
    @IBOutlet weak var BuySellControl: UISegmentedControl!
    @IBOutlet weak var NotionalControl: UISegmentedControl!
    @IBOutlet weak var MaturityControl: UISegmentedControl!
    
    //Coupon
    @IBOutlet weak var CouponControl: UISegmentedControl!
    
    @IBOutlet weak var CurrencyLabel: UILabel!
    @IBOutlet weak var CurrencyStepper: UIStepper!
    let usdCurrency = "USD"
    var CurrencyList = ["EUR", "GBP", "USD"]

    //Recovery
    @IBOutlet weak var RecoveryControl: UISegmentedControl!
    
    //UpFront Fee
    @IBOutlet weak var CalculatedFeeLabel: UILabel!
    
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
        
        //setup trade date stepper
        TradeDateStepper.wraps = false
        TradeDateStepper.autorepeat = true
        TradeDateStepper.minimumValue = -5
        TradeDateStepper.maximumValue = 0
        TradeDateStepper.value = 0
        let today = Date()
        setTradeDate(today)
        
        reCalc()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func reCalc()
    {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:MM:SS"
        CalculatedFeeLabel.text = dateFormatter.string(from: Date())

        print ("----------------------------------------")
        print ("Quote    : " + TradeBpLabel.text!)
        print ("TradeDate: " + TradeDateLabel.text!)
        print ("BuySell  : " + BuySellControl.titleForSegment(at: BuySellControl.selectedSegmentIndex)!)
        print ("Notional : " + NotionalControl.titleForSegment(at: NotionalControl.selectedSegmentIndex)!)
        print ("Maturity : " + MaturityControl.titleForSegment(at: MaturityControl.selectedSegmentIndex)!)
        print ("Coupon   : " + CouponControl.titleForSegment(at: CouponControl.selectedSegmentIndex)!)
        print ("Recovery : " + String(describing: RecoveryControl.titleForSegment(at: RecoveryControl.selectedSegmentIndex)) )
        print ("Fee      : " + CalculatedFeeLabel.text!)
        print ("Currency : " + CurrencyLabel!.text!)
        print ("----------------------------------------")
    }

    @IBAction func ContractRegionControllerChange(_ sender: UISegmentedControl) {
        //configure the screen based on the region
        configureRegionTerms(contract: isdaContracts[sender.selectedSegmentIndex])
        reCalc()
    }
    
    @IBAction func SegmentControllerChange(_ sender: UISegmentedControl) {
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
        if couponSpread > 500 {
            TradeBpStepper.minimumValue = couponSpread - 500
        } else {
            TradeBpStepper.minimumValue = 0
        }
        TradeBpStepper.maximumValue = couponSpread + 500

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
        tradeDate = (currentCalendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: Int(sender.value), to: tradeDate, options: NSCalendar.Options.matchFirst)!
        
        setTradeDate(tradeDate)
        reCalc()
    }
    
    func setTradeDate( _ tradeDate: Date )
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        TradeDateLabel.text = dateFormatter.string(from: tradeDate)

    }

}

