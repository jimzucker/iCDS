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
    @State private var showDatePicker = false
    @State private var showSpreadPicker = false
    @State private var spreadBuffer: String = ""

    // Absolute cap on the quoted spread (bp). 10000 bp = 100%/yr, deep
    // into distressed territory and well beyond any realistic CDS quote.
    private static let maxSpreadBp: Int = 10000

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                sofrIndicator
                regionRow
                termRows
                spreadFeeRow
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
        let dateStr = FeeView.formatISODate(vm.discountRateDate)
        return HStack(spacing: 6) {
            Text("Discount:").font(.caption2).foregroundColor(Color(white: 0.45))
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
            // Row 1: Buy/Sell  |  Recovery
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    label("Buy / Sell")
                    segPicker(["Buy", "Sell"], selection: $vm.buySellIndex)
                }
                if let contract = vm.contract {
                    VStack(alignment: .leading, spacing: 4) {
                        label("Recovery  \(vm.recoveryLabel)")
                        segPicker(contract.recoveryList.map(\.subordination), selection: $vm.recoveryIndex)
                    }
                }
            }
            // Row 2: Maturity (full width)
            VStack(alignment: .leading, spacing: 4) {
                label("Maturity")
                segPicker(vm.tenorLabels, selection: $vm.maturityIndex)
            }
            // Row 3: Coupon  |  Notional
            if let contract = vm.contract {
                HStack(alignment: .bottom, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        label("Coupon (bp)")
                        segPicker(contract.coupons.map(\.description), selection: $vm.couponIndex)
                            .onChange(of: vm.couponIndex) { _ in vm.resetSpreadToCoupon() }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        label("Notional")
                        segPicker(vm.notionalLabels, selection: $vm.notionalIndex)
                    }
                }
            }
        }
        .sheet(isPresented: $showSpreadPicker) {
            spreadPickerSheet
                .onAppear {
                    // Belt-and-suspenders: refresh buffer at presentation time
                    // in case the button action's state write hasn't landed yet.
                    spreadBuffer = String(Int(vm.spreadBp))
                }
        }
    }

    // MARK: - Spread + Fee equal-prominence row
    //
    // The Quoted Spread (input) and Upfront Fee (output) share one row with
    // identical card geometry: same width, same minHeight, same internal
    // structure (caption + big monospaced value). The orange tint on the
    // spread side signals 'tappable input'; the yellow on the fee side
    // signals 'computed output'. They read as a cause/effect pair.

    private var spreadFeeRow: some View {
        HStack(spacing: 8) {
            spreadCard
            feeCard
        }
    }

    private var spreadCard: some View {
        Button {
            spreadBuffer = String(Int(vm.spreadBp))
            showSpreadPicker = true
        } label: {
            VStack(spacing: 4) {
                Text("QUOTED SPREAD · tap")
                    .font(.caption2.weight(.semibold))
                    .tracking(1)
                    .foregroundColor(Color(white: 0.55))
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int(vm.spreadBp))")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(orange)
                    Text("bp")
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundColor(orange)
                    Image(systemName: "pencil")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(orange)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(orange.opacity(0.18))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(orange.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var feeCard: some View {
        Group {
            if let r = vm.result {
                let fmt = currencyFormatter(vm.currency)
                let display = noNegZero(r.upfrontDollars, eps: 0.5)
                let labelText = directionalLabel(r.upfrontDollars)
                VStack(spacing: 4) {
                    Text(labelText)
                        .font(.caption2.weight(.semibold))
                        .tracking(1)
                        .foregroundColor(Color(white: 0.30))
                    Text(fmt.string(from: NSNumber(value: abs(display))) ?? String(format: "%.0f", abs(display)))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(red: 1, green: 0.999, blue: 0.397))
                .cornerRadius(8)
            } else {
                VStack(spacing: 4) {
                    Text("CALCULATING")
                        .font(.caption2.weight(.semibold))
                        .tracking(1)
                        .foregroundColor(Color(white: 0.30))
                    Text("…")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(red: 1, green: 0.999, blue: 0.397))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Spread picker sheet (preset chips + numeric keypad)

    private var spreadPickerSheet: some View {
        let coupon = Int(vm.couponBp)
        let cap = Self.maxSpreadBp
        // Always fall back to the current spread value when the buffer is
        // empty or stale — fixes a SwiftUI timing race where the sheet body
        // is evaluated before the button action's spreadBuffer write lands.
        let pending: Int = {
            if let v = Int(spreadBuffer), v > 0 { return v }
            return Int(vm.spreadBp)
        }()
        let isOverCap = pending > cap
        let valueColor: Color = isOverCap ? .red : orange

        return NavigationView {
            VStack(spacing: 12) {
                // Spread block: pending value + coupon context + relation + cap hint
                VStack(spacing: 4) {
                    Text("\(pending) bp")
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                        .foregroundColor(valueColor)

                    HStack(spacing: 8) {
                        Text("Coupon \(coupon) bp")
                            .font(.caption2)
                            .foregroundColor(Color(white: 0.5))
                        Text("·")
                            .font(.caption2)
                            .foregroundColor(Color(white: 0.3))
                        Text(pendingHint(pending: pending, coupon: coupon, cap: cap))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(isOverCap ? .red : Color(white: 0.7))
                    }
                    Text("max \(cap) bp")
                        .font(.caption2)
                        .foregroundColor(Color(white: 0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                // Result preview card — separate visual block.
                // Skip preview when over cap so we don't show a number that
                // won't be committed.
                livePreviewCard(pending: isOverCap ? 0 : pending)
                    .padding(.horizontal, 12)

                // Preset chips — symmetric around par, with a distressed row
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        chip("Coupon -200", value: max(1, coupon - 200), pending: pending)
                        chip("Coupon -100", value: max(1, coupon - 100), pending: pending)
                        chip("Coupon -50",  value: max(1, coupon - 50),  pending: pending)
                    }
                    HStack(spacing: 8) {
                        chip("At Par",      value: coupon,         pending: pending)
                        chip("Coupon +50",  value: coupon + 50,    pending: pending)
                        chip("Coupon +100", value: coupon + 100,   pending: pending)
                    }
                    HStack(spacing: 8) {
                        chip("Coupon +200", value: coupon + 200,   pending: pending)
                        chip("Coupon +500", value: coupon + 500,   pending: pending)
                        chip("Coupon +1000",value: coupon + 1000,  pending: pending)
                    }
                    HStack(spacing: 8) {
                        chip("Coupon +2000",value: coupon + 2000,  pending: pending)
                        chip("Coupon +5000",value: coupon + 5000,  pending: pending)
                        chip("Max \(cap)",  value: cap,            pending: pending)
                    }
                }
                .padding(.horizontal, 12)

                Divider().background(Color(white: 0.2)).padding(.horizontal, 16)

                // 3 × 4 numeric keypad
                VStack(spacing: 10) {
                    HStack(spacing: 10) { keypadDigit("1"); keypadDigit("2"); keypadDigit("3") }
                    HStack(spacing: 10) { keypadDigit("4"); keypadDigit("5"); keypadDigit("6") }
                    HStack(spacing: 10) { keypadDigit("7"); keypadDigit("8"); keypadDigit("9") }
                    HStack(spacing: 10) {
                        keypadAction(systemImage: "delete.left") {
                            if !spreadBuffer.isEmpty { spreadBuffer.removeLast() }
                        }
                        keypadDigit("0")
                        keypadAction(systemImage: "xmark.circle") {
                            spreadBuffer = ""
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .navigationTitle("Quoted Spread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSpreadPicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { commitSpreadBuffer(cap: cap) }
                        .disabled(pending <= 0 || pending > cap)
                }
            }
        }
    }

    /// Estimated-upfront preview card with directional caption.
    @ViewBuilder
    private func livePreviewCard(pending: Int) -> some View {
        if pending > 0,
           let preview = vm.previewUpfront(forSpread: Double(pending)) {
            let dollars = preview.upfrontDollars
            let mag = Swift.abs(dollars)
            let fmt = currencyFormatter(vm.currency)
            let amount = fmt.string(from: NSNumber(value: mag)) ?? String(format: "%.0f", mag)
            let isBuy = vm.buySellIndex == 0
            let actor = isBuy ? "BUYER" : "SELLER"
            let action = mag < 0.5 ? "AT PAR · NO UPFRONT"
                         : dollars > 0 ? "\(actor) PAYS"
                         : "\(actor) RECEIVES"
            VStack(spacing: 4) {
                Text("ESTIMATED UPFRONT")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Color(white: 0.4))
                    .tracking(1.2)
                Text(amount)
                    .font(.system(.title2, design: .monospaced).weight(.bold))
                    .foregroundColor(orange)
                Text(action)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(white: 0.6))
                    .tracking(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(white: 0.10))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(white: 0.18), lineWidth: 1)
            )
        } else {
            // Same height as the populated card to prevent layout jump
            Color.clear.frame(height: 88)
        }
    }

    private func pendingHint(pending: Int, coupon: Int, cap: Int) -> String {
        if pending > cap { return "exceeds max \(cap) bp" }
        if pending == 0 { return " " }
        if pending == coupon { return "AT PAR" }
        let diff = pending - coupon
        return diff > 0 ? "Coupon + \(diff) bp" : "Coupon − \(-diff) bp"
    }

    private func chip(_ title: String, value: Int, pending: Int) -> some View {
        let isActive = pending == value
        return Button { spreadBuffer = String(value) } label: {
            Text(title)
                .font(.caption.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isActive ? orange.opacity(0.30) : Color(white: 0.15))
                .foregroundColor(orange)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isActive ? orange.opacity(0.7) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func keypadDigit(_ d: String) -> some View {
        Button {
            // Cap to 5 digits (99999 covers anything realistic)
            if spreadBuffer.count < 5 {
                if spreadBuffer == "0" { spreadBuffer = d } else { spreadBuffer += d }
            }
        } label: {
            Text(d)
                .font(.system(size: 26, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(white: 0.12))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func keypadAction(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(Color(white: 0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(white: 0.10))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func commitSpreadBuffer(cap: Int) {
        guard let v = Int(spreadBuffer), v >= 1, v <= cap else { return }
        vm.spreadBp = Double(v)
        showSpreadPicker = false
    }

    // MARK: - Trade / Settle output cells (the trade date cell is tappable)

    private var tradeDateCell: some View {
        Button { showDatePicker = true } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("Trade Date  ·  tap to pick")
                    .font(.caption2)
                    .foregroundColor(Color(white: 0.55))
                HStack(spacing: 6) {
                    Text(vm.tradeDateLabel)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundColor(orange)
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(orange.opacity(0.18))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(orange.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var settleDateCell: some View {
        let value = vm.result.map { formatTDate($0.valueDate) } ?? "—"
        return outputCell("Settle Date", value)
    }

    private var datePickerSheet: some View {
        let today = Date()
        let binding = Binding<Date>(
            get: { vm.tradeDate },
            set: { newValue in
                // Future trade dates are not meaningful — clamp to <= today
                let days = Calendar.current.dateComponents([.day], from: today, to: newValue).day ?? 0
                vm.tradeDateOffset = max(-365, min(0, days))
            }
        )
        let minDate = Calendar.current.date(byAdding: .year, value: -1, to: today)!
        return NavigationView {
            // ScrollView gives the underlying UICalendarView the height it needs;
            // a plain VStack-with-Spacer was triggering the 'smaller than it can
            // render its content' warning on first present.
            ScrollView {
                DatePicker("Trade Date",
                           selection: binding,
                           in: minDate...today,
                           displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .frame(minHeight: 380)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            .navigationTitle("Pick Trade Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showDatePicker = false }
                }
            }
        }
    }

    /// Directional description based on sign + buy/sell
    private func directionalLabel(_ upfrontDollars: Double) -> String {
        if abs(upfrontDollars) < 0.5 { return "NO UPFRONT · AT PAR" }
        let isBuy = vm.buySellIndex == 0
        let actor = isBuy ? "BUYER" : "SELLER"
        let action = upfrontDollars > 0 ? "PAYS" : "RECEIVES"
        return "\(actor) \(action)"
    }

    // MARK: - Output grid

    private var outputGrid: some View {
        VStack(spacing: 6) {
            HStack {
                tradeDateCell
                settleDateCell
            }
            if let r = vm.result {
                let fmt = currencyFormatter(vm.currency)
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
                    outputCell("Maturity", formatTDate(r.endDate))
                }
            }
        }
        .sheet(isPresented: $showDatePicker) { datePickerSheet }
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

    /// Display date format used everywhere in the app (e.g. "27-Apr-26").
    private func formatTDate(_ tdate: TDate) -> String {
        var mdy = TMonthDayYear()
        JpmcdsDateToMDY(tdate, &mdy)
        var c = DateComponents()
        c.year = Int(mdy.year); c.month = Int(mdy.month); c.day = Int(mdy.day)
        guard let date = Calendar.current.date(from: c) else { return "" }
        let fmt = DateFormatter(); fmt.dateFormat = "dd-MMM-yy"
        return fmt.string(from: date)
    }

    /// Reformat a SOFR/RFR ISO date ("yyyy-MM-dd") into the app's "dd-MMM-yy" form.
    static func formatISODate(_ iso: String) -> String {
        guard !iso.isEmpty else { return iso }
        let inFmt = DateFormatter(); inFmt.dateFormat = "yyyy-MM-dd"; inFmt.locale = Locale(identifier: "en_US_POSIX")
        guard let d = inFmt.date(from: iso) else { return iso }
        let outFmt = DateFormatter(); outFmt.dateFormat = "dd-MMM-yy"
        return outFmt.string(from: d)
    }
}
