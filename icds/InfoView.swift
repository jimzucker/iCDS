//
//  InfoView.swift
//  icds
//
//  Copyright © 2016-2026 James A. Zucker. All rights reserved.
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

                // Reference rates attribution
                attributionBlock(
                    title: "Reference rates",
                    lines: [
                        "SOFR data: Federal Reserve Bank of New York",
                        "www.newyorkfed.org"
                    ]
                )

                Divider().background(Color(white: 0.2)).padding(.vertical, 6)

                // App copyright
                Text("© 2016-2026 James A. Zucker")
                    .font(.caption)
                    .foregroundColor(Color(white: 0.5))

                Text("All rights reserved.")
                    .font(.caption2)
                    .foregroundColor(Color(white: 0.35))
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
