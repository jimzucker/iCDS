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
                prototypesSection
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
                let fmt = signedCurrencyFormatter(vm.currency)
                let display = noNegZero(r.upfrontDollars, eps: 0.5)
                VStack(spacing: 4) {
                    Text("UPFRONT FEE")
                        .font(.caption2.weight(.semibold))
                        .tracking(1)
                        .foregroundColor(Color(white: 0.30))
                    Text(fmt.string(from: NSNumber(value: display)) ?? String(format: "%+.0f", display))
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

    // MARK: - Prototypes (space-utilization candidates, stacked for comparison)
    //
    // Four ideas for the empty lower third, shown together so they can be
    // compared on-device. Each is headed by a numbered chip. Final design
    // would pick one (or one + the cash footer); this is throwaway scaffolding.

    private var prototypesSection: some View {
        VStack(spacing: 14) {
            protoDivider()
            protoHeader("1 · RISK STRIP")
            riskStripProto
            protoHeader("2 · CASH SETTLEMENT")
            cashSettlementProto
            protoHeader("3 · SPREAD SENSITIVITY")
            sparklineProto
            protoHeader("4 · SCENARIO ROW")
            scenarioRowProto
        }
        .padding(.top, 4)
    }

    private func protoDivider() -> some View {
        HStack(spacing: 8) {
            Rectangle().fill(Color(white: 0.2)).frame(height: 1)
            Text("PROTOTYPES").font(.system(size: 9, weight: .bold)).tracking(2).foregroundColor(Color(white: 0.4))
            Rectangle().fill(Color(white: 0.2)).frame(height: 1)
        }
    }

    private func protoHeader(_ t: String) -> some View {
        HStack {
            Text(t)
                .font(.caption2.weight(.bold))
                .tracking(1.5)
                .foregroundColor(orange.opacity(0.85))
            Spacer()
        }
    }

    // 1 — Risk strip: CS01 / IR DV01 / Rec01 as three dense metric cells.
    private var riskStripProto: some View {
        Group {
            if let rm = vm.riskMeasures {
                let fmt = signedCurrencyFormatter(vm.currency)
                HStack(spacing: 6) {
                    metricCell("CS01", "per +1 bp", fmt.string(from: NSNumber(value: rm.cs01)) ?? "")
                    metricCell("IR DV01", "per +1 bp", fmt.string(from: NSNumber(value: rm.ir01)) ?? "")
                    metricCell("Rec01", "per +1 pt", fmt.string(from: NSNumber(value: rm.rec01)) ?? "")
                }
            } else {
                Color.clear.frame(height: 58)
            }
        }
    }

    private func metricCell(_ title: String, _ sub: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(Color(white: 0.55))
            Text(value)
                .font(.system(.callout, design: .monospaced).weight(.semibold))
                .foregroundColor(orange)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(sub)
                .font(.system(size: 9))
                .foregroundColor(Color(white: 0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(white: 0.07))
        .cornerRadius(6)
    }

    // 2 — Cash settlement: clean upfront + accrued = dirty, with direction.
    private var cashSettlementProto: some View {
        Group {
            if let r = vm.result {
                let fmt = signedCurrencyFormatter(vm.currency)
                let signedAccrued = (vm.buySellIndex == 0) ? r.accrued : -r.accrued
                let dirty = r.upfrontDollars + signedAccrued
                let isBuy = vm.buySellIndex == 0
                let actor = isBuy ? "BUYER" : "SELLER"
                let action = abs(dirty) < 0.5 ? "NETS FLAT"
                             : dirty > 0 ? "\(actor) PAYS"
                             : "\(actor) RECEIVES"
                VStack(spacing: 6) {
                    cashRow("Clean Upfront", fmt.string(from: NSNumber(value: r.upfrontDollars)) ?? "")
                    cashRow("+ Accrued",     fmt.string(from: NSNumber(value: signedAccrued)) ?? "")
                    Divider().background(Color(white: 0.25))
                    HStack {
                        Text(action)
                            .font(.caption.weight(.bold))
                            .foregroundColor(Color(white: 0.6))
                            .tracking(0.5)
                        Spacer()
                        Text(fmt.string(from: NSNumber(value: dirty)) ?? "")
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                            .foregroundColor(orange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
                .padding(10)
                .background(Color(white: 0.07))
                .cornerRadius(8)
            } else {
                Color.clear.frame(height: 92)
            }
        }
    }

    private func cashRow(_ l: String, _ v: String) -> some View {
        HStack {
            Text(l).font(.caption).foregroundColor(Color(white: 0.55))
            Spacer()
            Text(v).font(.system(.callout, design: .monospaced)).foregroundColor(Color(white: 0.8))
        }
    }

    // 3 — Spread sensitivity sparkline: upfront vs spread over a ±150 bp window.
    private var sparklineProto: some View {
        Group {
            let pts = vm.sensitivityCurve(samples: 24)
            if pts.count > 1 {
                let xs = pts.map { $0.spread }
                let ys = pts.map { $0.dollars }
                let minX = xs.min() ?? 0, maxX = xs.max() ?? 1
                let minY = ys.min() ?? 0, maxY = ys.max() ?? 1
                let fmt = signedCurrencyFormatter(vm.currency)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Upfront vs Spread").font(.caption2).foregroundColor(Color(white: 0.55))
                        Spacer()
                        Text("\(Int(minX))–\(Int(maxX)) bp").font(.caption2).foregroundColor(Color(white: 0.4))
                    }
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height
                        let nx: (Double) -> CGFloat = { x in
                            maxX == minX ? 0 : CGFloat((x - minX) / (maxX - minX)) * w
                        }
                        let ny: (Double) -> CGFloat = { y in
                            maxY == minY ? h / 2 : h - CGFloat((y - minY) / (maxY - minY)) * h
                        }
                        ZStack {
                            Path { p in
                                for (i, pt) in pts.enumerated() {
                                    let cgp = CGPoint(x: nx(pt.spread), y: ny(pt.dollars))
                                    if i == 0 { p.move(to: cgp) } else { p.addLine(to: cgp) }
                                }
                            }
                            .stroke(orange, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                            let cx = nx(min(maxX, max(minX, vm.spreadBp)))
                            Path { p in
                                p.move(to: CGPoint(x: cx, y: 0))
                                p.addLine(to: CGPoint(x: cx, y: h))
                            }
                            .stroke(Color(white: 0.45), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        }
                    }
                    .frame(height: 70)
                    HStack {
                        Text(fmt.string(from: NSNumber(value: minY)) ?? "")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Color(white: 0.4))
                        Spacer()
                        Text(fmt.string(from: NSNumber(value: maxY)) ?? "")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Color(white: 0.4))
                    }
                }
                .padding(10)
                .background(Color(white: 0.07))
                .cornerRadius(8)
            } else {
                Color.clear.frame(height: 112)
            }
        }
    }

    // 4 — Scenario row: upfront at ±25 / ±50 bp from the current quote.
    private var scenarioRowProto: some View {
        Group {
            let scen = vm.scenarioUpfronts(offsets: [-50, -25, 25, 50])
            if !scen.isEmpty {
                let fmt = signedCurrencyFormatter(vm.currency)
                HStack(spacing: 6) {
                    ForEach(scen.indices, id: \.self) { i in
                        VStack(spacing: 3) {
                            Text("\(scen[i].label) bp")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(Color(white: 0.55))
                            Text(fmt.string(from: NSNumber(value: scen[i].dollars)) ?? "")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(orange)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(white: 0.07))
                        .cornerRadius(6)
                    }
                }
            } else {
                Color.clear.frame(height: 50)
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
            let dollars = noNegZero(preview.upfrontDollars, eps: 0.5)
            let fmt = signedCurrencyFormatter(vm.currency)
            let amount = fmt.string(from: NSNumber(value: dollars)) ?? String(format: "%+.0f", dollars)
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

    /// Currency formatter for the Upfront Fee. Positive values render with
    /// no explicit "+" prefix (it's the default direction — actor pays);
    /// negative values prepend a U+2212 MINUS SIGN so "−$X" reads as
    /// "actor receives".
    private func signedCurrencyFormatter(_ code: String) -> NumberFormatter {
        let f = currencyFormatter(code)
        f.negativePrefix = "−" + (f.currencySymbol ?? "")
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
