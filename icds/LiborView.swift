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

            // Currency picker
            Picker("Currency", selection: $selectedCurrency) {
                ForEach(RFRCurrency.allCases) { ccy in
                    Text(ccy.rawValue).tag(ccy)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            statusBanner
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            overnightBanner
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Divider().background(Color(white: 0.2))

            // Legend
            legend
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

            List {
                ForEach(RFRCurrency.allCases) { ccy in
                    row(for: ccy)
                        .listRowBackground(Color.black)
                }
            }
            .listStyle(.plain)
            .background(Color.black)
        }
        .background(Color.black)
    }

    // Legend explaining color coding in the summary list
    private var legend: some View {
        HStack(spacing: 12) {
            legendItem(color: .green,  label: "Live curve")
            legendItem(color: .yellow, label: "Default (no live source)")
            legendItem(color: Color(white: 0.5), label: "Loading")
            Spacer()
        }
        .font(.caption2)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).foregroundColor(Color(white: 0.6))
        }
    }

    // MARK: - Sub-views

    private var ccyStatus: SOFRDataStatus { sofrStore.status(for: selectedCurrency) }

    private var accentColor: Color {
        rowColor(for: ccyStatus)
    }

    private func rowColor(for status: SOFRDataStatus) -> Color {
        switch status {
        case .loading:  return Color(white: 0.5)
        case .live:     return .green     // have the curve
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

    @ViewBuilder
    private func row(for ccy: RFRCurrency) -> some View {
        let rate = sofrStore.rate(for: ccy)
        let date = sofrStore.effectiveDate(for: ccy)
        let status = sofrStore.status(for: ccy)
        HStack {
            Text("\(ccy.rawValue)  \(ccy.indexName)")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color(white: 0.7))
                .frame(width: 130, alignment: .leading)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(status == .loading ? "—" : String(format: "%.4f%%", rate * 100))
                    .font(.system(.body, design: .monospaced).weight(.semibold))
                    .foregroundColor(rowColor(for: status))
                Text(date.isEmpty ? " " : date)
                    .font(.caption2.monospaced())
                    .foregroundColor(Color(white: 0.5))
            }
        }
        .padding(.vertical, 4)
    }
}
