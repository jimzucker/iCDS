//
//  FeeView.swift
//  icds
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//

import SwiftUI

private let orange = Color(red: 1, green: 0.502, blue: 0)

struct FeeView: View {
    @StateObject private var vm = FeeViewModel()
    @ObservedObject private var sofrStore = SOFRRateStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                sofrIndicator
                regionRow
                termRows
                spreadRow
                tradeDateCurrencyRow
                resultBox
                outputGrid
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color.black)
        .navigationTitle("iCDS")
    }

    // MARK: - SOFR indicator (shows which discount rate is in use)

    private var sofrIndicator: some View {
        let ccyStr = vm.contract?.currency ?? "USD"
        let ccy = RFRCurrency(rawValue: ccyStr) ?? .USD
        let indexName = ccy.indexName
        let rate = vm.discountRate * 100
        let dateStr = vm.discountRateDate
        return HStack(spacing: 6) {
            switch vm.discountRateStatus {
            case .loading:
                Circle().fill(Color(white: 0.5)).frame(width: 6, height: 6)
                Text("\(indexName) loading…").font(.caption2).foregroundColor(Color(white: 0.55))
            case .live:
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text(String(format: "%@ %.4f%% · %@", indexName, rate, dateStr))
                    .font(.caption2).foregroundColor(Color(white: 0.7))
            case .fallback:
                Image(systemName: "exclamationmark.triangle.fill").font(.caption2).foregroundColor(.yellow)
                Text(String(format: "%@ unavailable — using %.3f%% reference", indexName, rate))
                    .font(.caption2).foregroundColor(.yellow)
            }
            Spacer()
        }
    }

    // MARK: - Region

    private var regionRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            label("Region")
            HStack(spacing: 6) {
                ForEach(vm.contracts.indices, id: \.self) { i in
                    segButton(vm.contracts[i].region, selected: vm.regionIndex == i) {
                        vm.regionIndex = i
                        vm.onRegionChanged()
                    }
                }
            }
        }
    }

    // MARK: - Terms

    private var termRows: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    label("Buy / Sell")
                    segPicker(["Buy", "Sell"], selection: $vm.buySellIndex)
                }
                VStack(alignment: .leading, spacing: 4) {
                    label("Notional")
                    segPicker(vm.notionalLabels, selection: $vm.notionalIndex)
                }
            }
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    label("Maturity")
                    segPicker(vm.tenorLabels, selection: $vm.maturityIndex)
                }
            }
            if let contract = vm.contract {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        label("Coupon (bp)")
                        segPicker(contract.coupons.map(\.description), selection: $vm.couponIndex)
                            .onChange(of: vm.couponIndex) { _ in vm.resetSpreadToCoupon() }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        label("Recovery  \(vm.recoveryLabel)")
                        segPicker(contract.recoveryList.map(\.subordination), selection: $vm.recoveryIndex)
                    }
                }
            }
        }
    }

    // MARK: - Spread

    private var spreadRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                label("Quoted Spread")
                Spacer()
                Text("\(Int(vm.spreadBp)) bp")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(orange)
                Stepper("", value: $vm.spreadBp, in: 1...(vm.couponBp + 1000), step: 1)
                    .labelsHidden()
                    .frame(width: 80)
            }
            Slider(value: $vm.spreadBp,
                   in: 1...(vm.couponBp + 1000),
                   step: 1)
                .accentColor(orange)
        }
    }

    // MARK: - Trade date (currency is implicit from region, shown in SOFR indicator)

    private var tradeDateCurrencyRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            label("Trade Date")
            HStack(spacing: 12) {
                Text(vm.tradeDateLabel)
                    .foregroundColor(orange)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                Spacer()
                // Step buttons — more discoverable than a macOS-style stepper
                Button {
                    vm.tradeDateOffset -= 1
                } label: {
                    Image(systemName: "chevron.left").foregroundColor(orange).frame(width: 28, height: 28)
                }
                .background(Color(white: 0.12))
                .cornerRadius(6)
                .disabled(vm.tradeDateOffset <= -30)

                Button {
                    vm.tradeDateOffset += 1
                } label: {
                    Image(systemName: "chevron.right").foregroundColor(orange).frame(width: 28, height: 28)
                }
                .background(Color(white: 0.12))
                .cornerRadius(6)
                .disabled(vm.tradeDateOffset >= 30)

                Button("Today") { vm.tradeDateOffset = 0 }
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color(white: 0.7))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color(white: 0.12))
                    .cornerRadius(6)
            }
        }
    }

    // MARK: - Result box

    private var resultBox: some View {
        Group {
            if let r = vm.result {
                let fmt = currencyFormatter(vm.currency)
                let display = noNegZero(r.upfrontDollars, eps: 0.5)
                Text(fmt.string(from: NSNumber(value: display)) ?? String(format: "%.0f", display))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 1, green: 0.999, blue: 0.397))
                    .cornerRadius(8)
            } else {
                Text("Calculating…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 1, green: 0.999, blue: 0.397))
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Output grid

    private var outputGrid: some View {
        Group {
            if let r = vm.result {
                let fmt = currencyFormatter(vm.currency)
                VStack(spacing: 6) {
                    HStack {
                        outputCell("Par Spread",  String(format: "%.0f bp", noNegZero(r.parSpreadBp, eps: 0.5)))
                        outputCell("Upfront",     String(format: "%.1f bp", noNegZero(r.upfrontBp, eps: 0.05)))
                    }
                    HStack {
                        outputCell("Accrued", fmt.string(from: NSNumber(value: r.accrued)) ?? "")
                        outputCell("Price",   String(format: "%.4f", r.price))
                    }
                    HStack {
                        outputCell("Start",    formatTDate(r.startDate))
                        outputCell("Settle",   formatTDate(r.valueDate))
                    }
                    HStack {
                        outputCell("Maturity", formatTDate(r.endDate))
                        outputCell("Tenor",    "\(Int(r.endDate - r.startDate)) days")
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(Color(white: 0.65))
    }

    private func segButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .frame(maxWidth: .infinity)       // fill equal share of row
                .padding(.vertical, 8)
                .background(selected ? orange : Color(white: 0.18))
                .foregroundColor(selected ? .black : .white)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func segPicker(_ options: [String], selection: Binding<Int>) -> some View {
        Picker("", selection: selection) {
            ForEach(options.indices, id: \.self) { i in
                Text(options[i]).tag(i)
            }
        }
        .pickerStyle(.segmented)
    }

    private func outputCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(Color(white: 0.55))
            Text(value)
                .font(.system(.callout, design: .monospaced))
                .foregroundColor(orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(white: 0.07))
        .cornerRadius(6)
    }

    private func currencyFormatter(_ code: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 0
        return f
    }

    // Normalize tiny values that would format as "-0" to positive zero
    private func noNegZero(_ value: Double, eps: Double) -> Double {
        abs(value) < eps ? 0.0 : value
    }

    private func formatTDate(_ tdate: TDate) -> String {
        var mdy = TMonthDayYear()
        JpmcdsDateToMDY(tdate, &mdy)
        return String(format: "%02d-%02d-%04d", mdy.month, mdy.day, mdy.year)
    }
}
