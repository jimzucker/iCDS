//
//  SOFRFetcher.swift
//  icds
//
//  Fetches the latest SOFR overnight rate from the NY Fed public API.
//  Falls back to a hardcoded rate if the network is unavailable.
//
//  Copyright © 2026 Strategic Software Engineering LLC. All rights reserved.
//

import Foundation
import Combine

// MARK: - Fetcher

struct SOFRFetcher {
    static let fallbackRate: Double = 0.045

    private static let endpoint = URL(string: "https://markets.newyorkfed.org/api/rates/sofr/last/1.json")!

    // Returns latest SOFR (rate as decimal, effectiveDate). Never throws.
    static func fetchLatest() async -> (rate: Double, effectiveDate: String) {
        return await fetchForDate(Date())
    }

    // Returns SOFR rate on or before `targetDate`. Fetches last 10 observations and picks
    // the most recent one whose effectiveDate ≤ targetDate (handles weekends/holidays).
    static func fetchForDate(_ targetDate: Date) async -> (rate: Double, effectiveDate: String) {
        let url = URL(string: "https://markets.newyorkfed.org/api/rates/sofr/last/10.json")!
        let target = isoDay(targetDate)
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return (fallbackRate, "unavailable")
            }
            if let parsed = parseOnOrBefore(data, target: target) { return parsed }
        } catch {}
        return (fallbackRate, "unavailable")
    }

    private static func isoDay(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: date)
    }

    private static func parseOnOrBefore(_ data: Data, target: String) -> (rate: Double, effectiveDate: String)? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let refRates = json["refRates"] as? [[String: Any]]
        else { return nil }
        // Observations are newest-first; find the first one on or before target date
        let match = refRates.first { ($0["effectiveDate"] as? String ?? "") <= target }
        guard let entry = match,
              let pct  = entry["percentRate"]  as? Double,
              let date = entry["effectiveDate"] as? String
        else { return nil }
        return (pct / 100.0, date)
    }
}

// MARK: - Observable store

enum SOFRDataStatus { case loading, live, fallback }

final class SOFRRateStore: ObservableObject {
    static let shared = SOFRRateStore()

    @Published private(set) var rate: Double = SOFRFetcher.fallbackRate
    @Published private(set) var effectiveDate: String = ""
    @Published private(set) var status: SOFRDataStatus = .loading

    private init() {
        // No auto-fetch here. FeeViewModel's async Task calls updateForTradeDate
        // with the already-snapped trade date (e.g. Friday when today is Sunday),
        // so the first fetch targets the correct date rather than wall-clock today.
        // Removing the auto-fetch also eliminates the race between two concurrent
        // fetches that could let the wall-clock fetch overwrite the snapped-date fetch.
    }

    func updateForTradeDate(_ date: Date) {
        Task { @MainActor in
            await refresh(for: date)
        }
    }

    @MainActor
    private func refresh(for date: Date) async {
        status = .loading
        let (r, d) = await SOFRFetcher.fetchForDate(date)
        rate = r
        if d == "unavailable" {
            effectiveDate = "unavailable"
            status = .fallback
        } else {
            effectiveDate = d
            status = .live
        }
    }
}
