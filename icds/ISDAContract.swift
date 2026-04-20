//
//  ISDAContract.swift
//  icds
//
//  Created by Jim Zucker on 10/4/16.
//  Copyright © 2016-2026 James A. Zucker All rights reserved.
//

import Foundation

class ISDAContract {
    var region: String
    var currency: String
    var settleDays: Int
    var recoveryList = [Recovery]()
    var coupons = [Int]()

    var calendarName: String

    init(region: String, currency: String, calendarName: String, settleDays: Int,
         recoveryList: Dictionary<String, Int>, coupons: [Int]) {
        self.region       = region
        self.currency     = currency
        self.calendarName = calendarName
        self.settleDays   = settleDays

        for key in Array(recoveryList.keys).sorted(by: <) {
            self.recoveryList.append(Recovery(subordination: key, recovery: recoveryList[key]!))
        }
        for item in coupons {
            self.coupons.append(item)
        }
    }

    convenience init(dataDictionary: Dictionary<String, NSObject>) {
        self.init(
            region:       dataDictionary["Region"]     as! String,
            currency:     dataDictionary["Currency"]   as? String ?? "USD",
            calendarName: dataDictionary["Calendar"]   as? String ?? "nyFed",
            settleDays:   dataDictionary["SettleDays"] as? Int    ?? 1,
            recoveryList: dataDictionary["Recovery"]   as! Dictionary<String, Int>,
            coupons:      dataDictionary["Coupons"]    as! [Int]
        )
    }

    class func readFromPlist() -> [ISDAContract] {
        guard let url     = Bundle.main.url(forResource: "contracts", withExtension: "plist"),
              let data    = try? Data(contentsOf: url),
              let plist   = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let entries = plist as? [Dictionary<String, NSObject>] else { return [] }
        return entries.map { ISDAContract(dataDictionary: $0) }
    }
}
