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
    var Coupons = ["0", "25", "100", "500", "1000"]
    
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

        
        //setup traded spread
        TradeBpStepper.wraps = false
        TradeBpStepper.autorepeat = true
        TradeBpStepper.maximumValue = 3000
        TradeBpStepper.value = Double(Coupons[Int(CpnBpStepper.value)])!
        TradeBpLabel.text = Coupons[Int(CpnBpStepper.value)] + " bp"
        
        //setup trade date stepper
        TradeDateStepper.wraps = false
        TradeDateStepper.autorepeat = true
        TradeDateStepper.minimumValue = -5
        TradeDateStepper.maximumValue = 0
        TradeDateStepper.value = 0
        let today = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM d"
        TradeDateLabel.text = dateFormatter.stringFromDate(today)
        
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
        print ("Currency : " + CurrencyBtn.titleLabel!.text!)
        print ("----------------------------------------")
    }

    @IBAction func TradeBpStepChange(sender: UIStepper) {
        TradeBpLabel.text = Int(sender.value).description + " bp"
        reCalc()
    }
    
    @IBAction func CpnBpStepChange(sender: UIStepper) {
        CpnBpLabel.text = Coupons[Int(sender.value)] + " bp"
        
        reCalc()
    }
    
    @IBAction func TradeDateStepChange(sender: UIStepper) {
        var tradeDate = NSDate()
        
        let currentCalendar = NSCalendar.currentCalendar()
        tradeDate = currentCalendar.dateByAddingUnit(NSCalendarUnit.Day, value: Int(sender.value), toDate: tradeDate, options: NSCalendarOptions.MatchFirst)!
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM d"
        TradeDateLabel.text = dateFormatter.stringFromDate(tradeDate)

        reCalc()
    }
    
    
    @IBAction func SegmentControllerChange(sender: UISegmentedControl) {
        reCalc()
    }
}

