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
                regionRow
                termRows
                spreadFeeRow
                outputGrid
                defaultRiskChart
                riskRow
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color.black)
        .navigationTitle("iCDS")
    }

    // MARK: - Region

    private var regionRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            label("Region")
            Picker("", selection: $vm.regionIndex) {
                ForEach(vm.contracts.indices, id: \.self) { i in
                    Text(vm.contracts[i].region).tag(i)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: vm.regionIndex) { _ in
                vm.onRegionChanged()
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
                Text("QUOTED SPREAD")
                    .font(.caption2.weight(.semibold))
                    .tracking(1)
                    .foregroundColor(Color(white: 0.55))
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int(vm.spreadBp))")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
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
                VStack(spacing: 4) {
                    Text("DIRTY UPFRONT")
                        .font(.caption2.weight(.semibold))
                        .tracking(1)
                        .foregroundColor(Color(white: 0.30))
                    Text(FeeView.signedCurrencyString(r.upfrontDollars + r.accrued, code: vm.currency))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
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

                // Preset chips — symmetric around par, with a distressed row.
                // Negative chips below par are hidden when coupon - N <= 0
                // (would clamp to 1 bp and confuse rather than help).
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        negChip(label: "Coupon -200", offset: 200, coupon: coupon, pending: pending)
                        negChip(label: "Coupon -100", offset: 100, coupon: coupon, pending: pending)
                        negChip(label: "Coupon -50",  offset: 50,  coupon: coupon, pending: pending)
                    }
                    HStack(spacing: 8) {
                        chip("At Par",      value: coupon,         pending: pending, prominent: true)
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

    /// Estimated-upfront preview card; signed value (+ = pay, − = receive).
    @ViewBuilder
    private func livePreviewCard(pending: Int) -> some View {
        if pending > 0,
           let preview = vm.previewUpfront(forSpread: Double(pending)) {
            let amount = FeeView.signedCurrencyString(preview.upfrontDollars, code: vm.currency)
            VStack(spacing: 4) {
                Text("ESTIMATED UPFRONT FEE")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Color(white: 0.4))
                    .tracking(1.2)
                Text(amount)
                    .font(.system(.title2, design: .monospaced).weight(.bold))
                    .foregroundColor(orange)
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

    private func chip(_ title: String, value: Int, pending: Int, prominent: Bool = false) -> some View {
        let isActive = pending == value
        let bg: Color = isActive ? orange.opacity(0.30)
                       : prominent ? orange.opacity(0.15)
                       : Color(white: 0.15)
        let strokeColor: Color = isActive ? orange.opacity(0.7)
                                : prominent ? orange.opacity(0.4)
                                : .clear
        return Button { spreadBuffer = String(value) } label: {
            Text(title)
                .font(.caption.weight(prominent ? .bold : .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(bg)
                .foregroundColor(orange)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(strokeColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    /// Negative-offset chip that stays as an invisible placeholder when
    /// `coupon - offset <= 0` (would clamp to 1 bp). The `.hidden()` modifier
    /// preserves the row's grid alignment so other rows don't shift.
    @ViewBuilder
    private func negChip(label: String, offset: Int, coupon: Int, pending: Int) -> some View {
        let v = coupon - offset
        if v > 0 {
            chip(label, value: v, pending: pending)
        } else {
            chip(label, value: -1, pending: pending).hidden()
        }
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
                Text("Trade Date")
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

    // MARK: - Output grid

    private var outputGrid: some View {
        VStack(spacing: 6) {
            HStack {
                tradeDateCell
                settleDateCell
            }
            if let r = vm.result {
                let fmt  = currencyFormatter(vm.currency)
                HStack {
                    outputCell("Accrued",   fmt.string(from: NSNumber(value: r.accrued)) ?? "")
                    outputCell("Upfront Fee", FeeView.signedCurrencyString(r.upfrontDollars, code: vm.currency))
                }
                HStack {
                    outputCell("Start",    formatTDate(r.startDate))
                    outputCell("Maturity", formatTDate(r.endDate))
                }
            }
        }
        .sheet(isPresented: $showDatePicker) { datePickerSheet }
    }

    // MARK: - Default-risk-by-maturity chart
    //
    // Flat-hazard cumulative default probability at each SNAC tenor.
    // Bars scale to the longest-tenor probability so the shape stays
    // readable at any spread; tapping a bar selects that maturity.

    private var defaultRiskChart: some View {
        let recovery = Double(vm.recoveryPct) / 100.0
        let probs = vm.tenorYears.map {
            CDSCalculator.cumulativeDefaultProb(spreadBp: vm.spreadBp,
                                                recoveryRate: recovery,
                                                years: Double($0))
        }
        let maxP = max(probs.max() ?? 0, 0.0001)
        let sel = min(max(vm.maturityIndex, 0), probs.count - 1)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("DEFAULT RISK")
                    .font(.caption2.weight(.bold)).tracking(1)
                    .foregroundColor(orange.opacity(0.85))
                Text("· by maturity")
                    .font(.caption2)
                    .foregroundColor(Color(white: 0.55))
                Spacer()
                Text(String(format: "%@  ≈ %.1f%% to default",
                            vm.tenorLabels[sel], probs[sel] * 100))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(orange)
            }
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(vm.tenorYears.indices, id: \.self) { i in
                    let isSel = i == sel
                    VStack(spacing: 3) {
                        Text(String(format: "%.1f%%", probs[i] * 100))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(isSel ? orange : Color(white: 0.55))
                            .lineLimit(1).minimumScaleFactor(0.6)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isSel ? orange : Color(white: 0.23))
                            .frame(height: max(4, CGFloat(probs[i] / maxP) * 64))
                        Text(vm.tenorLabels[i])
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(isSel ? orange : Color(white: 0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { vm.maturityIndex = i }
                }
            }
            .frame(height: 96, alignment: .bottom)
            Text("Cumulative default prob · flat-hazard")
                .font(.system(size: 9))
                .foregroundColor(Color(white: 0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(white: 0.07))
        .cornerRadius(8)
    }

    // MARK: - First-order risk (CS01 / IR DV01 / Rec01)

    @ViewBuilder
    private var riskRow: some View {
        if let rk = vm.risk {
            let fmt = currencyFormatter(vm.currency)
            let money: (Double) -> String = { v in
                let s = fmt.string(from: NSNumber(value: abs(v))) ?? String(format: "%.0f", abs(v))
                return (v < 0 && abs(v) >= 0.5 ? "−" : "") + s
            }
            HStack(spacing: 6) {
                riskCell("CS01",    money(rk.cs01),   "per +1 bp")
                riskCell("IR DV01", money(rk.irDV01), "per +1 bp")
                riskCell("Rec01",   money(rk.rec01),  "per +1 pt")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func riskCell(_ k: String, _ v: String, _ s: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(k).font(.caption2.weight(.semibold)).foregroundColor(Color(white: 0.55))
            Text(v).font(.system(.callout, design: .monospaced))
                .foregroundColor(orange).lineLimit(1).minimumScaleFactor(0.6)
            Text(s).font(.system(size: 9)).foregroundColor(Color(white: 0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(7)
        .background(Color(white: 0.07))
        .cornerRadius(6)
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
                .background(selected ? Color(white: 0.45) : Color(white: 0.18))
                .foregroundColor(.white)
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
        FeeView.currencyFormatter(code)
    }

    /// Currency formatter for the Upfront Fee. Positive values render with
    /// no explicit "+" prefix (it's the default direction — actor pays);
    /// negative values prepend a U+2212 MINUS SIGN so "−$X" reads as
    /// "actor receives".
    private func signedCurrencyFormatter(_ code: String) -> NumberFormatter {
        FeeView.signedCurrencyFormatter(code)
    }

    // Normalize tiny values that would format as "-0" to positive zero
    private func noNegZero(_ value: Double, eps: Double) -> Double {
        FeeView.noNegZero(value, eps: eps)
    }

    // ---- Test-accessible static helpers (mirror the instance ones) ----

    static func currencyFormatter(_ code: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 0
        return f
    }

    static func signedCurrencyFormatter(_ code: String) -> NumberFormatter {
        let f = currencyFormatter(code)
        f.negativePrefix = "−" + (f.currencySymbol ?? "")
        return f
    }

    static func noNegZero(_ value: Double, eps: Double) -> Double {
        abs(value) < eps ? 0.0 : value
    }

    /// Always returns the unsigned "$0" form for values whose absolute
    /// rounds to zero. Used for every signed-dollar cell on the Fee tab.
    static func signedCurrencyString(_ dollars: Double, code: String) -> String {
        let adjusted = noNegZero(dollars, eps: 0.5)
        return signedCurrencyFormatter(code).string(from: NSNumber(value: adjusted))
            ?? String(format: "%+.0f", adjusted)
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
