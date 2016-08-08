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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //setup Currency
        CurrencyStepper.wraps = true
        CurrencyStepper.autorepeat = true
        CurrencyStepper.maximumValue = Double(CurrencyList.count)-1
        CurrencyStepper.value = Double(CurrencyList.count)-1
        CurrencyLabel.text = String("USD")

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
        let today = NSDate()
        setTradeDate(today)
        
        reCalc()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func reCalc()
    {

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:MM:SS"
        CalculatedFeeLabel.text = dateFormatter.stringFromDate(NSDate())

        print ("----------------------------------------")
        print ("Quote    : " + TradeBpLabel.text!)
        print ("TradeDate: " + TradeDateLabel.text!)
        print ("BuySell  : " + BuySellControl.titleForSegmentAtIndex(BuySellControl.selectedSegmentIndex)!)
        print ("Notional : " + NotionalControl.titleForSegmentAtIndex(NotionalControl.selectedSegmentIndex)!)
        print ("Maturity : " + MaturityControl.titleForSegmentAtIndex(MaturityControl.selectedSegmentIndex)!)
        print ("Coupon   : " + CouponControl.titleForSegmentAtIndex(CouponControl.selectedSegmentIndex)!)
        print ("Recovery : " + String(RecoveryControl.titleForSegmentAtIndex(RecoveryControl.selectedSegmentIndex)) )
        print ("Fee      : " + CalculatedFeeLabel.text!)
        print ("Currency : " + CurrencyLabel!.text!)
        print ("----------------------------------------")
    }

    @IBAction func ContractRegionControllerChange(sender: UISegmentedControl) {
    }
    
    @IBAction func SegmentControllerChange(sender: UISegmentedControl) {
        reCalc()
    }
    
    
    @IBAction func CurrencyStepChange(sender: UIStepper) {
        CurrencyLabel.text = String(CurrencyList[Int(sender.value)])
        reCalc()
    }
    
    //is based on setting in CpnBpStepper
    //This sets/resets min/max/value for botht the CpnBp stepper and slider
    func TradeBpStepperSetup()
    {
        //This is setup realative to the Coupon Spread selected
        let couponSpread = Double(CouponControl.titleForSegmentAtIndex(CouponControl.selectedSegmentIndex)!)!
 
        //update the labels
        TradeBpLabel.text = Int(couponSpread).description + " bp"

        TradeBpStepper.value = couponSpread
        if couponSpread > 500 {
            TradeBpStepper.minimumValue = couponSpread - 500
        } else {
            TradeBpStepper.minimumValue = 0
        }
        TradeBpStepper.maximumValue = couponSpread + 500
        TradeBpLabel.text = couponSpread.description + " bp"

        //setup the slider
        TradeBpSlider.minimumValue = Float(TradeBpStepper.minimumValue)
        TradeBpSlider.maximumValue = Float(TradeBpStepper.maximumValue)
        TradeBpSlider.value = Float(TradeBpStepper.value)
    }
    
    
    @IBAction func TradeBpStepChange(sender: UIStepper) {

        //set the label
        let newQuote = sender.value
        TradeBpLabel.text = Int(newQuote).description + " bp"
        
        //sync the slider
        TradeBpSlider.value = Float(TradeBpStepper.value)
        
        reCalc()
    }
    
    @IBAction func TradeBpSliderChange(sender: UISlider) {
        let newQuote = Double(sender.value)
        TradeBpLabel.text = Int(newQuote).description + " bp"

            //sync the stepper
        TradeBpStepper.value = newQuote
        reCalc()
    }
    
    
    @IBAction func CouponControllerChange(sender: UISegmentedControl) {
        
        //reset the Controls
        TradeBpStepperSetup()
        
        reCalc()
    }
    
    @IBAction func TradeDateStepChange(sender: UIStepper) {
        var tradeDate = NSDate()
        
        let currentCalendar = NSCalendar.currentCalendar()
        tradeDate = currentCalendar.dateByAddingUnit(NSCalendarUnit.Day, value: Int(sender.value), toDate: tradeDate, options: NSCalendarOptions.MatchFirst)!
        
        setTradeDate(tradeDate)
        reCalc()
    }
    
    func setTradeDate( tradeDate: NSDate )
    {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM d"
        TradeDateLabel.text = dateFormatter.stringFromDate(tradeDate)

    }

}

