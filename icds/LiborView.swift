//
//  LiborView.swift
//  icds
//
//  Copyright © 2016-2026 James A. Zucker All rights reserved.
//

import SwiftUI

struct LiborView: View {

    private let orange = Color(red: 1, green: 0.502, blue: 0)

    private let curve: [(tenor: String, rate: String)] = [
        ("1M",  "5.31%"), ("3M",  "5.33%"), ("6M",  "5.20%"),
        ("1Y",  "4.88%"), ("2Y",  "4.42%"), ("3Y",  "4.25%"),
        ("5Y",  "4.15%"), ("7Y",  "4.18%"), ("10Y", "4.22%"),
        ("20Y", "4.48%"), ("30Y", "4.38%"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("USD Reference Curve")
                .font(.title2.bold())
                .foregroundColor(orange)
                .padding(.top, 16)

            Text("LIBOR discontinued Jun 2023 · Rates shown are SOFR-based USD swap mid-market reference (2024)")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 12)

            Divider().background(Color(white: 0.2))

            List(curve, id: \.tenor) { entry in
                HStack {
                    Text(entry.tenor)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(white: 0.7))
                    Spacer()
                    Text(entry.rate)
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .foregroundColor(orange)
                }
                .listRowBackground(Color.black)
            }
            .listStyle(.plain)
            .background(Color.black)
        }
        .background(Color.black)
    }
}
