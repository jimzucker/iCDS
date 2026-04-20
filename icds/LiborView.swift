//
//  LiborView.swift
//  icds
//
//  Copyright © 2016-2026 James A. Zucker All rights reserved.
//

import SwiftUI

struct LiborView: View {

    private let orange = Color(red: 1, green: 0.502, blue: 0)
    @ObservedObject private var sofrStore = SOFRRateStore.shared

    private let curve: [(tenor: String, rate: String)] = [
        ("1M",  "5.31%"), ("3M",  "5.33%"), ("6M",  "5.20%"),
        ("1Y",  "4.88%"), ("2Y",  "4.42%"), ("3Y",  "4.25%"),
        ("5Y",  "4.15%"), ("7Y",  "4.18%"), ("10Y", "4.22%"),
        ("20Y", "4.48%"), ("30Y", "4.38%"),
    ]

    // Colors driven by data status
    private var accentColor: Color {
        switch sofrStore.status {
        case .loading:  return Color(white: 0.5)
        case .live:     return orange
        case .fallback: return .red
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("USD Reference Curve")
                .font(.title2.bold())
                .foregroundColor(orange)
                .padding(.top, 16)

            // Status banner
            statusBanner
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Text("LIBOR discontinued Jun 2023 · Reference curve is SOFR-based USD swap mid-market (2024 static)")
                .font(.caption)
                .foregroundColor(Color(white: 0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 10)

            // SOFR overnight rate box
            overnightBanner
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            Divider().background(Color(white: 0.2))

            List(curve, id: \.tenor) { entry in
                HStack {
                    Text(entry.tenor)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(white: 0.7))
                    Spacer()
                    Text(entry.rate)
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .foregroundColor(accentColor)
                }
                .listRowBackground(Color.black)
            }
            .listStyle(.plain)
            .background(Color.black)
        }
        .background(Color.black)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var statusBanner: some View {
        HStack(spacing: 6) {
            switch sofrStore.status {
            case .loading:
                Circle().fill(Color(white: 0.5)).frame(width: 8, height: 8)
                Text("Fetching live rates…")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color(white: 0.5))
            case .live:
                Circle().fill(Color.green).frame(width: 8, height: 8)
                Text("LIVE  ·  NY Fed SOFR")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.green)
            case .fallback:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                Text("DEFAULT RATES  ·  No network — rates below may be stale")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.red)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusBannerBackground)
        .cornerRadius(6)
    }

    private var statusBannerBackground: Color {
        switch sofrStore.status {
        case .loading:  return Color(white: 0.1)
        case .live:     return Color.green.opacity(0.08)
        case .fallback: return Color.red.opacity(0.10)
        }
    }

    private var overnightBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SOFR Overnight")
                    .font(.caption2)
                    .foregroundColor(Color(white: 0.55))
                Text(sofrStore.status == .loading
                     ? "loading…"
                     : String(format: "%.4f%%", sofrStore.rate * 100))
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("as of")
                    .font(.caption2)
                    .foregroundColor(Color(white: 0.55))
                Text(sofrStore.effectiveDate.isEmpty ? "—" : sofrStore.effectiveDate)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(sofrStore.status == .fallback ? .red : Color(white: 0.7))
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
