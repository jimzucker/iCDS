//
//  Recovery.swift
//  icds
//
//  Created by Jim Zucker on 10/4/16.
//  Copyright © 2016 Strategic Software Engineering LLC. All rights reserved.
//

import Foundation

class Recovery {
    var subordination: String
    var recovery: Int
    
    init( subordination: String, recovery: Int )
    {
        self.subordination = subordination
        self.recovery = recovery
    }
}
