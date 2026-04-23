//
//  LiborView.swift
//  icds
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//

import SwiftUI

struct LiborView: View {

    private let orange = Color(red: 1, green: 0.502, blue: 0)
    @ObservedObject private var sofrStore = SOFRRateStore.shared
    @State private var selectedCurrency: RFRCurrency = .USD

    var body: some View {
        VStack(spacing: 0) {
            Text("Reference Rates")
                .font(.title2.bold())
                .foregroundColor(orange)
                .padding(.top, 16)

            Text("Live RFR overnight rates by currency")
                .font(.caption)
                .foregroundColor(Color(white: 0.45))
                .padding(.top, 4)
                .padding(.bottom, 10)

            // Currency picker — color-coded by fetch status
            currencyPicker
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            statusBanner
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            overnightBanner
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Divider().background(Color(white: 0.2))

            // Per-currency reference swap curve (static 2021 snapshot)
            curveTableHeader
                .padding(.horizontal, 16)
                .padding(.top, 8)

            List {
                ForEach(tenorsForSelected(), id: \.tenor) { entry in
                    HStack {
                        Text(entry.tenor)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Color(white: 0.7))
                        Spacer()
                        Text(String(format: "%.4f%%", entry.rate * 100))
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                            .foregroundColor(orange)
                    }
                    .listRowBackground(Color.black)
                }
            }
            .listStyle(.plain)
            .background(Color.black)
        }
        .background(Color.black)
    }

    // MARK: - Reference swap curves (ISDA RFR test grid · 2021-04-26 snapshot)

    private var curveTableHeader: some View {
        HStack {
            Text("\(selectedCurrency.indexName) swap curve")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(white: 0.65))
            Spacer()
            Text("reference · 2021-04-26")
                .font(.caption2)
                .foregroundColor(Color(white: 0.4))
        }
    }

    private func tenorsForSelected() -> [(tenor: String, rate: Double)] {
        switch selectedCurrency {
        case .USD: return zip(usdTenors, usdRates).map { ($0, $1) }
        case .EUR: return zip(eurTenors, eurRates).map { ($0, $1) }
        case .GBP: return zip(gbpTenors, gbpRates).map { ($0, $1) }
        case .JPY: return zip(jpyTenors, jpyRates).map { ($0, $1) }
        case .AUD: return zip(audTenors, audRates).map { ($0, $1) }
        }
    }

    // --- USD (SOFR) ---
    private let usdTenors: [String] = ["1M","2M","3M","6M","1Y","2Y","3Y","4Y","5Y","6Y","7Y","8Y","9Y","10Y","12Y","15Y","20Y","25Y","30Y"]
    private let usdRates:  [Double] = [0.000162, 0.00025, 0.00029, 0.00037, 0.000475, 0.001101, 0.002731, 0.004851, 0.006832, 0.008592, 0.010081, 0.011242, 0.012202, 0.013032, 0.014311, 0.01554, 0.016521, 0.016871, 0.016979]

    // --- EUR (€STR) ---
    private let eurTenors: [String] = ["1M","3M","6M","1Y","2Y","3Y","4Y","5Y","6Y","7Y","8Y","9Y","10Y","12Y","15Y","20Y","30Y"]
    private let eurRates:  [Double] = [-0.005683, -0.005699, -0.005727, -0.00576, -0.00572, -0.005399, -0.00489, -0.00429, -0.00361, -0.00289, -0.00217, -0.00145, -0.00078, 0.000431, 0.00189, 0.00313, 0.00336]

    // --- GBP (SONIA) ---
    private let gbpTenors: [String] = ["1M","2M","3M","6M","1Y","2Y","3Y","4Y","5Y","6Y","7Y","8Y","9Y","10Y","12Y","15Y","20Y","25Y","30Y"]
    private let gbpRates:  [Double] = [0.000494, 0.000494, 0.000494, 0.000496, 0.000541, 0.001096, 0.002129, 0.003182, 0.004173, 0.004981, 0.005687, 0.006298, 0.00684, 0.007314, 0.008028, 0.008676, 0.009064, 0.009052, 0.008867]

    // --- JPY (TONA) ---
    private let jpyTenors: [String] = ["1M","2M","3M","6M","1Y","2Y","3Y","4Y","5Y","6Y","7Y","8Y","9Y","10Y","12Y","15Y","20Y","30Y"]
    private let jpyRates:  [Double] = [-0.000188, -0.0002, -0.000225, -0.000263, -0.000388, -0.000581, -0.000638, -0.0006, -0.000488, -0.00035, -0.000163, 6.3e-05, 0.0003, 0.000576, 0.001138, 0.002001, 0.003188, 0.004563]

    // --- AUD (AONIA) ---
    private let audTenors: [String] = ["1M","2M","3M","6M","1Y","2Y","3Y","4Y","5Y","6Y","7Y","8Y","9Y","10Y","12Y","15Y","20Y","25Y","30Y"]
    private let audRates:  [Double] = [0.000315, 0.000305, 0.000315, 0.00035, 0.000495, 0.001121, 0.002559, 0.004592, 0.006868, 0.008915, 0.010933, 0.012285, 0.013666, 0.015018, 0.016713, 0.01828, 0.019156, 0.019176, 0.018727]

    // MARK: - Sub-views

    private var ccyStatus: SOFRDataStatus { sofrStore.status(for: selectedCurrency) }

    private var accentColor: Color {
        rowColor(for: ccyStatus)
    }

    /// Color-coded currency buttons. Green = live, yellow = default, gray = loading.
    /// Selected currency is shown at full opacity; others are dimmed.
    private var currencyPicker: some View {
        HStack(spacing: 4) {
            ForEach(RFRCurrency.allCases) { ccy in
                Button {
                    selectedCurrency = ccy
                } label: {
                    Text(ccy.rawValue)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(buttonBackground(for: ccy))
                        .foregroundColor(buttonForeground(for: ccy))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(buttonBorderColor(for: ccy),
                                        lineWidth: buttonBorderWidth(for: ccy))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func buttonBorderColor(for ccy: RFRCurrency) -> Color {
        let status = sofrStore.status(for: ccy)
        if status == .fallback { return .yellow }   // always flag fallbacks
        return selectedCurrency == ccy ? orange : .clear
    }

    private func buttonBorderWidth(for ccy: RFRCurrency) -> CGFloat {
        let status = sofrStore.status(for: ccy)
        if status == .fallback { return 1.5 }
        return selectedCurrency == ccy ? 2 : 0
    }

    // Only currencies with issues are color-marked — live ones use the app's
    // neutral accent, which keeps problems visible at a glance.
    private func buttonBackground(for ccy: RFRCurrency) -> Color {
        let status = sofrStore.status(for: ccy)
        let selected = selectedCurrency == ccy
        switch status {
        case .fallback:
            return selected ? Color.yellow.opacity(0.35) : Color.yellow.opacity(0.12)
        case .loading:
            return selected ? Color(white: 0.5).opacity(0.35) : Color(white: 0.5).opacity(0.12)
        case .live:
            return selected ? orange.opacity(0.30) : Color(white: 0.15)
        }
    }

    private func buttonForeground(for ccy: RFRCurrency) -> Color {
        let status = sofrStore.status(for: ccy)
        let selected = selectedCurrency == ccy
        switch status {
        case .fallback:
            return .yellow
        case .loading:
            return Color(white: 0.6)
        case .live:
            return selected ? orange : Color(white: 0.8)
        }
    }

    private func rowColor(for status: SOFRDataStatus) -> Color {
        switch status {
        case .loading:  return Color(white: 0.5)
        case .live:     return orange     // neutral / app accent
        case .fallback: return .yellow    // defaulting to static reference
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        HStack(spacing: 6) {
            switch ccyStatus {
            case .loading:
                Circle().fill(Color(white: 0.5)).frame(width: 8, height: 8)
                Text("Fetching \(selectedCurrency.indexName)…")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color(white: 0.5))
            case .live:
                Circle().fill(Color.green).frame(width: 8, height: 8)
                Text("LIVE  ·  \(selectedCurrency.sourceLabel)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.green)
            case .fallback:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                Text("Reference rate — \(selectedCurrency.sourceLabel)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.yellow)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusBannerBackground)
        .cornerRadius(6)
    }

    private var statusBannerBackground: Color {
        switch ccyStatus {
        case .loading:  return Color(white: 0.1)
        case .live:     return Color.green.opacity(0.08)
        case .fallback: return Color.yellow.opacity(0.10)
        }
    }

    private var overnightBanner: some View {
        let rate = sofrStore.rate(for: selectedCurrency)
        let date = sofrStore.effectiveDate(for: selectedCurrency)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selectedCurrency.indexName)  (\(selectedCurrency.rawValue))")
                    .font(.caption2)
                    .foregroundColor(Color(white: 0.55))
                Text(ccyStatus == .loading
                     ? "loading…"
                     : String(format: "%.4f%%", rate * 100))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("as of")
                    .font(.caption2)
                    .foregroundColor(Color(white: 0.55))
                Text(date.isEmpty ? "—" : date)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(ccyStatus == .fallback ? .red : Color(white: 0.7))
            }
        }
        .padding(12)
        .background(Color(white: 0.08))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(accentColor.opacity(0.5), lineWidth: 1)
        )
    }

}
