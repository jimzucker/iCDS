//
//  ISDAContract.swift
//  icds
///Users/jaz/Dropbox/dev/icds/icds/Base.lproj/Main.storyboard
//  Created by Jim Zucker on 10/4/16.
//  Copyright © 2016 Strategic Software Engineering LLC. All rights reserved.
//

import Foundation

class ISDAContract {
    // MARK: Properties
    
    var region: String
    var recoveryList = [Recovery]()
    var coupons = [Int]()
    
    // MARK: Initialization
    
    init(region: String, recoveryList: Dictionary<String,Int>, coupons: [Int]) {
        self.region = region
        
        //dictionaries do not have order, so we have to sort the keys
        for item in Array(recoveryList.keys).sorted(by: <)
        {
            let rate = recoveryList[item]
            self.recoveryList.append(Recovery(subordination: item, recovery: rate!))
        }
        for item in coupons
        {
            self.coupons.append(item)
        }
    }
    
    convenience init( dataDictionary: Dictionary<String,NSObject> ) {
        self.init(region: dataDictionary["Region"] as! String
                , recoveryList: dataDictionary["Recovery"] as! Dictionary<String, Int>
                , coupons: dataDictionary["Coupons"] as! [Int])
    }
    
    class func readFromPlist() -> [ISDAContract] {
        guard let url = Bundle.main.url(forResource: "contracts", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let entries = plist as? [Dictionary<String, NSObject>] else {
            return []
        }
        return entries.map { ISDAContract(dataDictionary: $0) }
    }
    
    
}
