//
//  SOFRFetcher.swift
//  icds
//
//  Multi-currency RFR (Risk-Free Rate) fetcher. Despite the file name,
//  this module now covers SOFR, €STR, SONIA, TONA, AONIA.
//  File kept named SOFRFetcher.swift for project.pbxproj stability.
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//

import Foundation
import Combine

// MARK: - RFR currency enum

enum RFRCurrency: String, CaseIterable, Identifiable, Hashable {
    case USD, EUR, GBP, JPY, AUD

    var id: String { rawValue }

    /// Short name of the reference rate for this currency
    var indexName: String {
        switch self {
        case .USD: return "SOFR"
        case .EUR: return "€STR"
        case .GBP: return "SONIA"
        case .JPY: return "TONA"
        case .AUD: return "AONIA"
        }
    }

    /// Publisher/source label shown in UI
    var sourceLabel: String {
        switch self {
        case .USD: return "NY Fed"
        case .EUR: return "ECB"
        case .GBP: return "Bank of England"
        case .JPY: return "FRED · Japan Overnight"
        case .AUD: return "Reserve Bank of Australia"
        }
    }

    /// Fallback rate (decimal) used when live fetch unavailable.
    /// Values approximate April 2026 levels — used only if all fetches fail.
    var fallbackRate: Double {
        switch self {
        case .USD: return 0.045
        case .EUR: return 0.019
        case .GBP: return 0.037
        case .JPY: return 0.007
        case .AUD: return 0.041
        }
    }
}

// MARK: - Per-currency fetchers

struct RFRFetcher {

    /// Fetch the latest available overnight rate for a currency.
    /// Returns (rate as decimal, effectiveDate as YYYY-MM-DD string, source label).
    /// Never throws — falls back gracefully on any error.
    static func fetch(_ ccy: RFRCurrency) async -> (rate: Double, effectiveDate: String) {
        switch ccy {
        case .USD: return await fetchSOFR()
        case .EUR: return await fetchESTR()
        case .GBP: return await fetchSONIA()
        case .JPY: return await fetchTONA()
        case .AUD: return await fetchAONIA()
        }
    }

    /// Per-fetch timeout (seconds). Default URLSession is 60s — too long for UI.
    private static let fetchTimeout: TimeInterval = 15

    /// Build a URLRequest with our standard timeout and User-Agent.
    private static func req(_ url: URL) -> URLRequest {
        var r = URLRequest(url: url)
        r.timeoutInterval = fetchTimeout
        // Some government APIs (BoE, ECB) reject non-browser User-Agents
        r.setValue("Mozilla/5.0 (iCDS iOS)", forHTTPHeaderField: "User-Agent")
        return r
    }

    // MARK: USD — NY Fed SOFR

    private static func fetchSOFR() async -> (rate: Double, effectiveDate: String) {
        let url = URL(string: "https://markets.newyorkfed.org/api/rates/secured/sofr/last/1.json")!
        do {
            let (data, response) = try await URLSession.shared.data(for: req(url))
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("SOFR fetch HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return (RFRCurrency.USD.fallbackRate, "unavailable")
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let refRates = json["refRates"] as? [[String: Any]],
                  let first = refRates.first,
                  let pct = first["percentRate"] as? Double,
                  let date = first["effectiveDate"] as? String
            else { return (RFRCurrency.USD.fallbackRate, "unavailable") }
            return (pct / 100.0, date)
        } catch {
            print("SOFR fetch failed: \(error.localizedDescription)")
            return (RFRCurrency.USD.fallbackRate, "unavailable")
        }
    }

    // MARK: EUR — ECB €STR via data-api.ecb.europa.eu (CSV)

    private static func fetchESTR() async -> (rate: Double, effectiveDate: String) {
        let url = URL(string: "https://data-api.ecb.europa.eu/service/data/EST/B.EU000A2X2A25.WT?lastNObservations=1&format=csvdata")!
        return await fetchCSV(tag: "€STR", url: url, dateCol: 4, valueCol: 5, fallback: RFRCurrency.EUR.fallbackRate)
    }

    // MARK: GBP — Bank of England SONIA (IUDSOIA)

    private static func fetchSONIA() async -> (rate: Double, effectiveDate: String) {
        let cal = Calendar(identifier: .gregorian)
        let today = Date()
        let from  = cal.date(byAdding: .day, value: -14, to: today)!
        let boEDateFmt = DateFormatter()
        boEDateFmt.dateFormat = "dd/MMM/yyyy"
        boEDateFmt.locale = Locale(identifier: "en_GB")
        let fromStr = boEDateFmt.string(from: from)
        let toStr   = boEDateFmt.string(from: today)
        let urlStr  = "https://www.bankofengland.co.uk/boeapps/database/_iadb-fromshowcolumns.asp?csv.x=yes" +
                      "&Datefrom=\(fromStr)&Dateto=\(toStr)&SeriesCodes=IUDSOIA&CSVF=TN&UsingCodes=Y&VPD=Y&VFD=N"
        guard let url = URL(string: urlStr) else {
            return (RFRCurrency.GBP.fallbackRate, "unavailable")
        }
        return await fetchCSV(tag: "SONIA", url: url, dateCol: 0, valueCol: 1, fallback: RFRCurrency.GBP.fallbackRate,
                               dateFormat: "dd MMM yyyy", takeLast: true)
    }

    // MARK: JPY — FRED "Immediate Rates: Less than 24 Hours: Call Money/Interbank Rate for Japan" (monthly)

    private static func fetchTONA() async -> (rate: Double, effectiveDate: String) {
        let url = URL(string: "https://fred.stlouisfed.org/graph/fredgraph.csv?id=IRSTCI01JPM156N")!
        return await fetchCSV(tag: "TONA", url: url, dateCol: 0, valueCol: 1, fallback: RFRCurrency.JPY.fallbackRate, takeLast: true)
    }

    // MARK: AUD — RBA F1 Interbank Overnight Cash Rate (column 3)

    private static func fetchAONIA() async -> (rate: Double, effectiveDate: String) {
        let url = URL(string: "https://www.rba.gov.au/statistics/tables/csv/f1-data.csv")!
        // RBA CSV has ~10 header rows then data. Date = col 0, Interbank Overnight Cash Rate = col 3
        return await fetchCSV(tag: "AONIA", url: url, dateCol: 0, valueCol: 3, fallback: RFRCurrency.AUD.fallbackRate,
                               dateFormat: "dd-MMM-yyyy", takeLast: true, skipHeaderUntilDate: true)
    }

    // MARK: Generic CSV fetcher used by ECB/BoE/FRED/RBA

    private static func fetchCSV(tag: String, url: URL, dateCol: Int, valueCol: Int, fallback: Double,
                                  dateFormat: String = "yyyy-MM-dd",
                                  takeLast: Bool = false,
                                  skipHeaderUntilDate: Bool = false) async -> (rate: Double, effectiveDate: String) {
        do {
            let (data, response) = try await URLSession.shared.data(for: req(url))
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let text = String(data: data, encoding: .utf8) else {
                print("\(tag) fetch HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return (fallback, "unavailable")
            }
            let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            // Find data rows (first col parses as date)
            let inFmt = DateFormatter()
            inFmt.dateFormat = dateFormat
            inFmt.locale = Locale(identifier: "en_US_POSIX")
            let outFmt = DateFormatter()
            outFmt.dateFormat = "yyyy-MM-dd"
            outFmt.locale = Locale(identifier: "en_US_POSIX")

            var candidates: [(date: Date, dateStr: String, value: Double)] = []
            for raw in lines {
                let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !line.isEmpty else { continue }
                let cols = line.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
                guard cols.count > max(dateCol, valueCol) else { continue }
                let dateStr = cols[dateCol]
                let valueStr = cols[valueCol]
                guard let d = inFmt.date(from: dateStr), let v = Double(valueStr) else {
                    if skipHeaderUntilDate { continue }
                    continue
                }
                candidates.append((d, outFmt.string(from: d), v / 100.0))  // convert percent → decimal
            }
            guard !candidates.isEmpty else {
                print("\(tag) fetch: no parseable rows")
                return (fallback, "unavailable")
            }
            let chosen = takeLast ? candidates.sorted(by: { $0.date < $1.date }).last! : candidates.first!
            return (chosen.value, chosen.dateStr)
        } catch {
            print("\(tag) fetch failed: \(error.localizedDescription)")
            return (fallback, "unavailable")
        }
    }
}

// Legacy SOFR-specific shim (USD only) — preserves date-filtered fetch for tests
struct SOFRFetcher {
    static let fallbackRate: Double = RFRCurrency.USD.fallbackRate

    static func fetchLatest() async -> (rate: Double, effectiveDate: String) {
        await RFRFetcher.fetch(.USD)
    }

    /// Fetch SOFR on or before `targetDate` — last 10 observations, first with date ≤ target.
    static func fetchForDate(_ targetDate: Date) async -> (rate: Double, effectiveDate: String) {
        let url = URL(string: "https://markets.newyorkfed.org/api/rates/secured/sofr/last/10.json")!
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"; fmt.locale = Locale(identifier: "en_US_POSIX")
        let target = fmt.string(from: targetDate)
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return (fallbackRate, "unavailable")
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let refRates = json["refRates"] as? [[String: Any]] else {
                return (fallbackRate, "unavailable")
            }
            let match = refRates.first { ($0["effectiveDate"] as? String ?? "") <= target }
            guard let entry = match,
                  let pct  = entry["percentRate"]  as? Double,
                  let date = entry["effectiveDate"] as? String else {
                return (fallbackRate, "unavailable")
            }
            return (pct / 100.0, date)
        } catch {
            return (fallbackRate, "unavailable")
        }
    }
}

// MARK: - Observable store

enum SOFRDataStatus { case loading, live, fallback }

struct RFRRate {
    let rate: Double
    let effectiveDate: String
    let status: SOFRDataStatus
}

final class SOFRRateStore: ObservableObject {
    static let shared = SOFRRateStore()

    // Per-currency rates
    @Published private(set) var rates: [RFRCurrency: RFRRate] = [:]

    // Legacy single-value API (USD only) — kept for existing callers
    var rate: Double { rates[.USD]?.rate ?? RFRCurrency.USD.fallbackRate }
    var effectiveDate: String { rates[.USD]?.effectiveDate ?? "" }
    var status: SOFRDataStatus { rates[.USD]?.status ?? .loading }

    private init() {
        Task { @MainActor in
            await refreshAll()
        }
    }

    /// Fetch overnight rates for all currencies concurrently.
    @MainActor
    func refreshAll() async {
        await withTaskGroup(of: (RFRCurrency, RFRRate).self) { group in
            for ccy in RFRCurrency.allCases {
                group.addTask {
                    let (r, d) = await RFRFetcher.fetch(ccy)
                    let status: SOFRDataStatus = (d == "unavailable" || d == "static") ? .fallback : .live
                    return (ccy, RFRRate(rate: r, effectiveDate: d, status: status))
                }
            }
            for await (ccy, rate) in group {
                rates[ccy] = rate
            }
        }
    }

    /// Legacy single-currency API. Refreshes USD only.
    func updateForTradeDate(_ date: Date) {
        Task { @MainActor in
            let (r, d) = await RFRFetcher.fetch(.USD)
            let status: SOFRDataStatus = (d == "unavailable" || d == "static") ? .fallback : .live
            rates[.USD] = RFRRate(rate: r, effectiveDate: d, status: status)
        }
    }

    /// Get rate for a specific currency (falls back to USD, then hardcoded).
    func rate(for ccy: RFRCurrency) -> Double {
        rates[ccy]?.rate ?? ccy.fallbackRate
    }

    func effectiveDate(for ccy: RFRCurrency) -> String {
        rates[ccy]?.effectiveDate ?? "—"
    }

    func status(for ccy: RFRCurrency) -> SOFRDataStatus {
        rates[ccy]?.status ?? .loading
    }
}
