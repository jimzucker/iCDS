//
//  iCDSApp.swift
//  icds
//
//  Copyright © 2010-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//

import SwiftUI

@main
struct iCDSApp: App {
    var body: some Scene {
        WindowGroup {
            // iPhone + iPad: force dark — the orange/yellow palette was
            // designed for a black background. Mac Catalyst: honor system
            // appearance so the window blends with the user's desktop.
            #if targetEnvironment(macCatalyst)
            ContentView()
            #else
            ContentView().preferredColorScheme(.dark)
            #endif
        }
    }
}
