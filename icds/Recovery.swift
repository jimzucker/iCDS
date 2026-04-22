//
//  Recovery.swift
//  icds
//
//  Created by Jim Zucker on 10/4/16.
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
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
