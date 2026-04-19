//
//  FeeView.swift
//  icds
//
//  Adapted from version2b storyboard layout.
//  Copyright © 2016-2026 James A. Zucker All rights reserved.
//

import SwiftUI

private let orange    = Color(red: 1, green: 0.502, blue: 0)
private let grayCtrl  = Color(white: 0.667)
private let yellow    = Color(red: 1, green: 0.999, blue: 0.398)

struct FeeView: View {
    @StateObject private var vm = FeeViewModel()

    var body: some View {
        VStack(spacing: 10) {
            // 1. Region
            regionRow

            // 2. Buy/Sell | Notional
            HStack(spacing: 8) {
                segPicker(["Buy", "Sell"], selection: $vm.buySellIndex)
                segPicker(vm.notionalLabels, selection: $vm.notionalIndex)
            }

            // 3. Recovery | Coupon
            if let contract = vm.contract {
                HStack(spacing: 8) {
                    segPicker(contract.recoveryList.map(\.subordination), selection: $vm.recoveryIndex)
                        .onChange(of: vm.recoveryIndex) { _ in vm.recalc() }
                    segPicker(contract.coupons.map(\.description), selection: $vm.couponIndex)
                        .onChange(of: vm.couponIndex) { _ in vm.resetSpreadToCoupon() }
                }
            }

            // 4. Currency (label + stepper) | Maturity
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text(vm.currency)
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                        .frame(minWidth: 44)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                        .background(grayCtrl)
                        .cornerRadius(6)
                    Stepper("", value: $vm.currencyIndex, in: 0...(vm.currencies.count - 1))
                        .labelsHidden()
                        .tint(grayCtrl)
                }
                segPicker(vm.tenorLabels, selection: $vm.maturityIndex)
            }

            // 5. Trade Bp (label + stepper) | Yellow fee result box
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("\(Int(vm.spreadBp)) bp")
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                        .frame(minWidth: 60)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                        .background(grayCtrl)
                        .cornerRadius(6)
                    Stepper("", value: $vm.spreadBp, in: 1...(vm.couponBp + 1000), step: 1)
                        .labelsHidden()
                        .tint(grayCtrl)
                }
                feeBox
            }

            // 6. Slider
            Slider(value: $vm.spreadBp,
                   in: 1...(vm.couponBp + 1000), step: 1)
                .tint(grayCtrl)

            // 7. Results row 1: Recovery | Trade | Settle | Start
            resultRow1

            // 8. Results row 2: Accrual | Spread | Price | Upfront
            resultRow2
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Region

    private var regionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(vm.contracts.indices, id: \.self) { i in
                    Button(vm.contracts[i].region) {
                        vm.regionIndex = i
                        vm.onRegionChanged()
                    }
                    .font(.system(size: 13))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(vm.regionIndex == i ? grayCtrl : Color(white: 0.18))
                    .foregroundColor(vm.regionIndex == i ? .black : .white)
                    .cornerRadius(6)
                }
            }
        }
    }

    // MARK: - Fee result box

    private var feeBox: some View {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = vm.currency
        fmt.maximumFractionDigits = 0
        let text = vm.result.flatMap { fmt.string(from: NSNumber(value: $0.upfrontDollars)) }
                   ?? "---"
        return Text(text)
            .font(.system(size: 20, weight: .bold, design: .monospaced))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, minHeight: 36)
            .padding(.horizontal, 8)
            .background(yellow)
            .cornerRadius(6)
    }

    // MARK: - Result rows

    private var resultRow1: some View {
        HStack(spacing: 4) {
            resultCell("Recovery", vm.recoveryLabel)
            resultCell("Trade",    vm.tradeDateLabel)
            resultCell("Settle",   vm.result.map { formatTDate($0.valueDate) } ?? "---")
            resultCell("Start",    vm.result.map { formatTDate($0.startDate) } ?? "---")
        }
    }

    private var resultRow2: some View {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency; fmt.currencyCode = vm.currency; fmt.maximumFractionDigits = 0
        return HStack(spacing: 4) {
            resultCell("Accrual", vm.result.flatMap { fmt.string(from: NSNumber(value: $0.accrued)) } ?? "---")
            resultCell("Spread",  vm.result.map { String(format: "%.0f", $0.parSpreadBp) } ?? "---")
            resultCell("Price",   vm.result.map { String(format: "%.4f", $0.price) } ?? "---")
            resultCell("Upfront", vm.result.map { String(format: "%.1f", $0.upfrontBp) } ?? "---")
        }
    }

    // MARK: - Helpers

    private func segPicker(_ opts: [String], selection: Binding<Int>) -> some View {
        Picker("", selection: selection) {
            ForEach(opts.indices, id: \.self) { Text(opts[$0]).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    private func resultCell(_ header: String, _ value: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(header)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(value)
                .font(.system(size: 13, design: .monospaced).italic())
                .foregroundColor(orange)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(Color.black)
    }

    private func formatTDate(_ tdate: TDate) -> String {
        var mdy = TMonthDayYear()
        JpmcdsDateToMDY(tdate, &mdy)
        return String(format: "%d-%02d", mdy.day, mdy.month)
    }
}
