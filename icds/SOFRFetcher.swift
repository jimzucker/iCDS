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

    private static let endpoint = URL(string: "https://markets.newyorkfed.org/api/rates/secured/sofr/last/1.json")!

    // Returns latest SOFR (rate as decimal, effectiveDate). Never throws.
    static func fetchLatest() async -> (rate: Double, effectiveDate: String) {
        return await fetchForDate(Date())
    }

    // Returns SOFR rate on or before `targetDate`. Fetches last 10 observations and picks
    // the most recent one whose effectiveDate ≤ targetDate (handles weekends/holidays).
    static func fetchForDate(_ targetDate: Date) async -> (rate: Double, effectiveDate: String) {
        let url = URL(string: "https://markets.newyorkfed.org/api/rates/secured/sofr/last/10.json")!
        let target = isoDay(targetDate)
        print("🔵 SOFR fetch START  target=\(target)")
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("🔴 SOFR fetch HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return (fallbackRate, "unavailable")
            }
            if let parsed = parseOnOrBefore(data, target: target) {
                print("🟢 SOFR fetch OK    rate=\(parsed.rate)  effectiveDate=\(parsed.effectiveDate)")
                return parsed
            }
            print("🟡 SOFR fetch: no observation on or before \(target)")
        } catch {
            print("🔴 SOFR fetch EXCEPTION: \(error.localizedDescription)")
        }
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
        // Fetch immediately for the last weekday — no CDSHolidayCalendar needed,
        // just skip weekends. This is safe on the main thread and gives the correct
        // date (e.g. Friday) when today is Saturday/Sunday without causing a hang.
        // FeeViewModel's async Task calls updateForTradeDate with the full holiday-
        // calendar date to refine for any public holiday edge cases.
        let lastWeekday: Date = {
            var d = Date()
            while Calendar.current.isDateInWeekend(d) {
                d = Calendar.current.date(byAdding: .day, value: -1, to: d)!
            }
            return d
        }()
        print("🔵 SOFRRateStore.init() scheduling fetch for last weekday: \(lastWeekday)")
        Task { @MainActor in
            await refresh(for: lastWeekday)
        }
    }

    func updateForTradeDate(_ date: Date) {
        print("🔵 SOFRRateStore.updateForTradeDate(\(date))")
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
