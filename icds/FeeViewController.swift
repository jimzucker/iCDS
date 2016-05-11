//
//  FeeViewController.swift
//  icds
//
//  Created by Jim Zucker on 5/10/16.
//  Copyright © 2016 Strategic Software Engineering LLC. All rights reserved.
//

import UIKit

class FeeViewController: UIViewController {

    
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
    @IBOutlet weak var CpnBpLabel: UILabel!
    @IBOutlet weak var CpnBpStepper: UIStepper!
    let Coupons = ["0", "25", "100", "500", "1000"]
    
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
        
        //setup Cpn bp
        CpnBpStepper.wraps = true
        CpnBpStepper.autorepeat = true
        CpnBpStepper.maximumValue = Double(Coupons.count)-1
        CpnBpStepper.value = 3
        CpnBpLabel.text = String(Coupons[Int(CpnBpStepper.value)]) + " bp"

        //setup Currency
        CurrencyStepper.wraps = true
        CurrencyStepper.autorepeat = true
        CurrencyStepper.maximumValue = Double(CurrencyList.count)-1
        CurrencyStepper.value = Double(CurrencyList.count)-1
        CurrencyLabel.text = String(Coupons[Int(CurrencyStepper.value)])

        //setup traded spread
        TradeBpStepper.wraps = false
        TradeBpStepper.autorepeat = true
        TradeBpStepper.maximumValue = 3000
        TradeBpStepper.value = Double(Coupons[Int(CpnBpStepper.value)])!
        TradeBpLabel.text = Coupons[Int(CpnBpStepper.value)] + " bp"
        
        //setup the slider
        TradeBpSliderSetup(Float(CpnBpStepper.value))
        
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
        print ("BuySell  : " + String(BuySellControl.titleForSegmentAtIndex(BuySellControl.selectedSegmentIndex)) )
        print ("Notional : " + String(NotionalControl.titleForSegmentAtIndex(NotionalControl.selectedSegmentIndex)) )
        print ("Maturity : " + String(MaturityControl.titleForSegmentAtIndex(MaturityControl.selectedSegmentIndex)) )
        print ("Cpn      : " + CpnBpLabel.text!)
        print ("Recovery : " + String(RecoveryControl.titleForSegmentAtIndex(RecoveryControl.selectedSegmentIndex)) )
        print ("Fee      : " + CalculatedFeeLabel.text!)
        print ("Currency : " + CurrencyLabel!.text!)
        print ("----------------------------------------")
    }

    
    @IBAction func SegmentControllerChange(sender: UISegmentedControl) {
        reCalc()
    }
    
    
    @IBAction func CurrencyStepChange(sender: UIStepper) {
        CurrencyLabel.text = String(CurrencyList[Int(sender.value)])
        reCalc()
    }
    
    
    func TradeBpSliderSetup(value: Float)
    {
        TradeBpSlider.value = value
        
        if value > 500 {
            TradeBpSlider.minimumValue = value - 501

        } else {
            TradeBpSlider.minimumValue = 0
        }
        
        TradeBpSlider.maximumValue = value + 500
    }
    
    @IBAction func TradeBpStepChange(sender: UIStepper) {

        //set the label
        let newQuote = sender.value
        TradeBpLabel.text = Int(newQuote).description + " bp"
        
        //reset the slider
        TradeBpSliderSetup (Float(newQuote))
        reCalc()
    }
    
    @IBAction func TradeBpSliderChange(sender: UISlider) {
        let newQuote = Double(sender.value)
        TradeBpLabel.text = Int(newQuote).description + " bp"

            //update the stepper
        TradeBpStepper.value = newQuote
        reCalc()
    }
    
    @IBAction func CpnBpStepChange(sender: UIStepper) {
            //update the labels
        let newQuote = sender.value
        CpnBpLabel.text = Coupons[Int(newQuote)] + " bp"
        TradeBpLabel.text = CpnBpLabel.text
        
        //rest the Controls
        TradeBpStepper.value = Double(Coupons[Int(newQuote)])!
        TradeBpSliderSetup (Float(newQuote))
        
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

