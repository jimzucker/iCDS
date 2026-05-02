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

    private let apacheURL = URL(string: "https://www.apache.org/licenses/LICENSE-2.0")!
    private let isdaURL = URL(string: "https://www.cdsmodel.com")!
    private let docsURL = URL(string: "https://jimzucker.github.io/iCDS/")!

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                aboutSection
                Divider().background(Color(white: 0.2))
                dataSourcesSection
                Divider().background(Color(white: 0.2))
                disclaimersSection
                Divider().background(Color(white: 0.2))
                legalSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .background(Color.black)
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(spacing: 6) {
            Text("iCDS")
                .font(.system(size: 52, weight: .bold))
                .foregroundColor(orange)

            Text("Credit Default Swap Calculator")
                .font(.headline)
                .foregroundColor(.white)

            Text("Version \(version)")
                .font(.subheadline)
                .foregroundColor(.gray)

            Link(destination: docsURL) {
                Label("Documentation & Source", systemImage: "book")
                    .font(.callout.weight(.semibold))
                    .foregroundColor(orange)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(orange, lineWidth: 1.2)
                    )
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Data sources

    private var dataSourcesSection: some View {
        VStack(spacing: 14) {
            sectionHeader("Data sources")

            attributionBlock(
                title: "Pricing engine",
                lines: [
                    "ISDA CDS Standard Model",
                    "© 2009 JPMorgan Chase Bank, N.A.",
                    "Licensed under the ISDA CDS Standard Model Public License"
                ],
                link: ("www.cdsmodel.com", isdaURL)
            )

            attributionBlock(
                title: "Live reference rates",
                lines: [
                    "USD SOFR — Federal Reserve Bank of New York (newyorkfed.org)",
                    "EUR €STR — European Central Bank (ecb.europa.eu)",
                    "GBP SONIA — Bank of England (bankofengland.co.uk)",
                    "JPY TONA (monthly proxy) — FRED, St. Louis Fed (fred.stlouisfed.org)",
                    "AUD AONIA — Reserve Bank of Australia (rba.gov.au)"
                ],
                link: nil
            )
        }
    }

    // MARK: - Disclaimers

    private var disclaimersSection: some View {
        VStack(spacing: 8) {
            sectionHeader("Disclaimers")

            disclaimerLine("Indicative pricing only. Not financial, investment, or trading advice.")
            disclaimerLine("Provided AS IS, without warranty of any kind. No liability is accepted for any loss arising from use of this app or its results.")
            disclaimerLine("Rates may be delayed; calculations use a flat overnight-rate discount curve — a standard simplification. Not suitable for booking, settlement, or trading.")
            disclaimerLine("Users are responsible for verifying all results against authoritative sources before acting on them.")
            disclaimerLine("Not affiliated with, endorsed by, or sponsored by ISDA, Markit, JPMorgan Chase, or any rate provider listed above. All trademarks are property of their respective owners.")
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 4) {
            Text("© 2016-2026 James A. Zucker")
                .font(.caption)
                .foregroundColor(Color(white: 0.55))

            Text("Licensed under the Apache License, Version 2.0")
                .font(.caption2)
                .foregroundColor(Color(white: 0.45))

            Link("apache.org/licenses/LICENSE-2.0", destination: apacheURL)
                .font(.caption2)
                .foregroundColor(orange)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(Color(white: 0.55))
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func attributionBlock(title: String, lines: [String], link: (String, URL)?) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(Color(white: 0.7))
                .padding(.bottom, 2)
            ForEach(lines.indices, id: \.self) { i in
                Text(lines[i])
                    .font(.caption2)
                    .foregroundColor(Color(white: 0.75))
                    .multilineTextAlignment(.center)
            }
            if let link = link {
                Link(link.0, destination: link.1)
                    .font(.caption2)
                    .foregroundColor(orange)
                    .padding(.top, 1)
            }
        }
        .padding(.vertical, 2)
    }

    private func disclaimerLine(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(Color(white: 0.72))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}
