//
//  ContentView.swift
//  icds
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FeeView()
                .tabItem { Label("Fee", image: "CalcTabbarIcon") }
            LiborView()
                .tabItem { Label("Libor", systemImage: "chart.line.uptrend.xyaxis") }
            InfoView()
                .tabItem { Label("Info", systemImage: "info.circle") }
        }
        .accentColor(.orange)
    }
}
