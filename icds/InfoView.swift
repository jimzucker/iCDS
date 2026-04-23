//
//  InfoView.swift
//  icds
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//

import SwiftUI

struct InfoView: View {

    private let orange = Color(red: 1, green: 0.502, blue: 0)
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Title
                Text("iCDS")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(orange)

                Text("Credit Default Swap Calculator")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Version \(version)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Divider().background(Color(white: 0.2)).padding(.vertical, 6)

                // Pricing engine attribution
                attributionBlock(
                    title: "Pricing engine",
                    lines: [
                        "ISDA CDS Standard Model",
                        "© 2009 JPMorgan Chase Bank, N.A.",
                        "Licensed under the ISDA CDS Standard Model Public License",
                        "www.cdsmodel.com"
                    ]
                )

                // Reference rates attribution (all 5 central banks we query)
                attributionBlock(
                    title: "Live reference rates",
                    lines: [
                        "USD SOFR — Federal Reserve Bank of New York",
                        "www.newyorkfed.org",
                        "EUR €STR — European Central Bank",
                        "www.ecb.europa.eu",
                        "GBP SONIA — Bank of England",
                        "www.bankofengland.co.uk",
                        "JPY TONA (monthly proxy) — FRED, St. Louis Fed",
                        "fred.stlouisfed.org",
                        "AUD AONIA — Reserve Bank of Australia",
                        "www.rba.gov.au"
                    ]
                )

                // Disclaimer about rate usage
                attributionBlock(
                    title: "Disclaimer",
                    lines: [
                        "Rates shown are informational only and may be delayed.",
                        "Calculations use a flat overnight-rate discount curve —",
                        "a standard simplification for indicative pricing.",
                        "Not suitable for booking, settlement, or trading."
                    ]
                )

                Divider().background(Color(white: 0.2)).padding(.vertical, 6)

                // App copyright + license
                Text("© 2016-2026 James A. Zucker")
                    .font(.caption)
                    .foregroundColor(Color(white: 0.5))

                Text("Licensed under the Apache License, Version 2.0")
                    .font(.caption2)
                    .foregroundColor(Color(white: 0.45))

                Text("apache.org/licenses/LICENSE-2.0")
                    .font(.caption2)
                    .foregroundColor(orange)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .background(Color.black)
    }

    private func attributionBlock(title: String, lines: [String]) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(white: 0.55))
                .padding(.bottom, 2)
            ForEach(lines.indices, id: \.self) { i in
                Text(lines[i])
                    .font(.caption2)
                    .foregroundColor(lines[i].hasPrefix("www.") ? orange : Color(white: 0.75))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 4)
    }
}
