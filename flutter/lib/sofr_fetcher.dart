/// Multi-currency RFR (Risk-Free Rate) fetcher, ported from
/// `iCDS/icds/SOFRFetcher.swift`. Despite the file name, covers SOFR,
/// €STR, SONIA, TONA, AONIA. Mirrors the Swift module's public surface:
///
///   - [RFRCurrency] — the 5 currencies + index/source/fallback metadata.
///   - [RFRFetcher.fetch] — one-shot fetch for a single currency.
///   - [SOFRRateStore] — singleton cache + ChangeNotifier for the UI.
///
/// The Swift implementation publishes via Combine; here we use
/// `ChangeNotifier`, which the Flutter UI can listen to via
/// [AnimatedBuilder] / `ListenableBuilder`.
library;

import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RFRCurrency {
  usd, eur, gbp, jpy, aud;

  String get code {
    switch (this) {
      case RFRCurrency.usd: return 'USD';
      case RFRCurrency.eur: return 'EUR';
      case RFRCurrency.gbp: return 'GBP';
      case RFRCurrency.jpy: return 'JPY';
      case RFRCurrency.aud: return 'AUD';
    }
  }

  String get indexName {
    switch (this) {
      case RFRCurrency.usd: return 'SOFR';
      case RFRCurrency.eur: return '€STR';
      case RFRCurrency.gbp: return 'SONIA';
      case RFRCurrency.jpy: return 'TONA';
      case RFRCurrency.aud: return 'AONIA';
    }
  }

  String get sourceLabel {
    switch (this) {
      case RFRCurrency.usd: return 'NY Fed';
      case RFRCurrency.eur: return 'ECB';
      case RFRCurrency.gbp: return 'Bank of England';
      case RFRCurrency.jpy: return 'FRED · Japan Overnight (monthly)';
      case RFRCurrency.aud: return 'Reserve Bank of Australia';
    }
  }

  /// Fallback rate (decimal) used when live fetch unavailable.
  /// Approximate April 2026 levels.
  double get fallbackRate {
    switch (this) {
      case RFRCurrency.usd: return 0.045;
      case RFRCurrency.eur: return 0.019;
      case RFRCurrency.gbp: return 0.037;
      case RFRCurrency.jpy: return 0.007;
      case RFRCurrency.aud: return 0.041;
    }
  }
}

class RFRFetchResult {
  final double rate;
  final String effectiveDate; // YYYY-MM-DD or "unavailable"
  /// True when the result reflects a fresh successful network fetch.
  /// False when it's a fallback — either because the live fetch failed
  /// or because the source is monthly and we synthesised the expected
  /// last-published date so the UI has something to show.
  final bool isLive;
  const RFRFetchResult(this.rate, this.effectiveDate, {this.isLive = true});
}

class RFRFetcher {
  static const _timeout = Duration(seconds: 15);

  /// FRED's CSV endpoint (used for JPY TONA) accepts the TLS handshake
  /// quickly but the response body trickles in slowly. iOS's URLSession
  /// uses an *idle* timeout so it waits as long as bytes keep arriving;
  /// Dart's `Future.timeout` is a *total* budget. Give FRED a 60 s
  /// budget so Android matches iOS's behaviour in practice.
  static const _slowTimeout = Duration(seconds: 60);

  /// Some government APIs (BoE, ECB) reject non-browser User-Agents.
  static const _headers = {'User-Agent': 'Mozilla/5.0 (iCDS Flutter)'};

  static Future<RFRFetchResult> fetch(RFRCurrency ccy) {
    switch (ccy) {
      case RFRCurrency.usd: return _fetchSOFR();
      case RFRCurrency.eur: return _fetchESTR();
      case RFRCurrency.gbp: return _fetchSONIA();
      case RFRCurrency.jpy: return _fetchTONA();
      case RFRCurrency.aud: return _fetchAONIA();
    }
  }

  // === USD — NY Fed SOFR (JSON) ===
  static Future<RFRFetchResult> _fetchSOFR() async {
    final url = Uri.parse('https://markets.newyorkfed.org/api/rates/secured/sofr/last/1.json');
    try {
      final resp = await http.get(url, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) {
        debugPrint('SOFR fetch HTTP ${resp.statusCode}');
        return RFRFetchResult(RFRCurrency.usd.fallbackRate, 'unavailable', isLive: false);
      }
      final json = jsonDecode(resp.body);
      final refRates = json['refRates'] as List?;
      if (refRates == null || refRates.isEmpty) {
        return RFRFetchResult(RFRCurrency.usd.fallbackRate, 'unavailable', isLive: false);
      }
      final first = refRates.first as Map;
      final pct = (first['percentRate'] as num?)?.toDouble();
      final date = first['effectiveDate'] as String?;
      if (pct == null || date == null) {
        return RFRFetchResult(RFRCurrency.usd.fallbackRate, 'unavailable', isLive: false);
      }
      return RFRFetchResult(pct / 100.0, date);
    } catch (e) {
      debugPrint('SOFR fetch failed: $e');
      return RFRFetchResult(RFRCurrency.usd.fallbackRate, 'unavailable', isLive: false);
    }
  }

  // === EUR — ECB €STR (CSV) ===
  static Future<RFRFetchResult> _fetchESTR() {
    final url = Uri.parse(
      'https://data-api.ecb.europa.eu/service/data/EST/B.EU000A2X2A25.WT'
      '?lastNObservations=1&format=csvdata');
    return _fetchCsv(
      tag: '€STR', url: url, dateCol: 4, valueCol: 5,
      fallback: RFRCurrency.eur.fallbackRate);
  }

  // === GBP — Bank of England SONIA (CSV, dd MMM yyyy) ===
  static Future<RFRFetchResult> _fetchSONIA() {
    final today = DateTime.now();
    final from = today.subtract(const Duration(days: 14));
    final boEFmt = DateFormat('dd/MMM/yyyy');
    final fromStr = boEFmt.format(from);
    final toStr = boEFmt.format(today);
    final url = Uri.parse(
      'https://www.bankofengland.co.uk/boeapps/database/_iadb-fromshowcolumns.asp?csv.x=yes'
      '&Datefrom=$fromStr&Dateto=$toStr&SeriesCodes=IUDSOIA&CSVF=TN&UsingCodes=Y&VPD=Y&VFD=N');
    return _fetchCsv(
      tag: 'SONIA', url: url, dateCol: 0, valueCol: 1,
      fallback: RFRCurrency.gbp.fallbackRate,
      dateFormat: 'dd MMM yyyy', takeLast: true);
  }

  // === JPY — FRED Japan Call Money (monthly, CSV) ===
  ///
  /// FRED's load balancer appears to drop a non-trivial fraction of
  /// HTTP/1.1 keep-alive connections — iOS URLSession (HTTP/2 + idle
  /// timeout) tends to break through on the first try, while Dart's
  /// `http` package (HTTP/1.1, total timeout) sees a stalled
  /// connection and gives up. Retry up to 3× with a short backoff so
  /// Android matches iOS's empirical success rate.
  static Future<RFRFetchResult> _fetchTONA() async {
    final url = Uri.parse('https://fred.stlouisfed.org/graph/fredgraph.csv?id=IRSTCI01JPM156N');
    const attempts = 3;
    for (var i = 1; i <= attempts; i++) {
      final result = await _fetchCsv(
        tag: 'TONA(try$i)', url: url, dateCol: 0, valueCol: 1,
        fallback: RFRCurrency.jpy.fallbackRate, takeLast: true,
        // Shorter per-attempt budget so 3 attempts still finish under
        // a minute. If FRED is going to answer at all it does so within
        // 15–20 s once the load balancer picks a healthy backend.
        timeout: const Duration(seconds: 20));
      if (result.isLive) return result;
      if (i < attempts) {
        await Future.delayed(Duration(seconds: 2 * i));
      }
    }
    // All retries failed. FRED's series is monthly with ~45-day
    // publication lag, so synthesise the most-likely last-published
    // date (1st of the month, ~45 days ago) so the UI shows a
    // plausible date instead of "unavailable".
    return RFRFetchResult(RFRCurrency.jpy.fallbackRate,
                          _lastLikelyTonaDate(), isLive: false);
  }

  /// First-of-month date that is ~45 days behind today — matches FRED's
  /// monthly-with-lag publication cadence for `IRSTCI01JPM156N`.
  static String _lastLikelyTonaDate() {
    final probe = DateTime.now().subtract(const Duration(days: 45));
    final firstOfMonth = DateTime(probe.year, probe.month, 1);
    return DateFormat('yyyy-MM-dd').format(firstOfMonth);
  }

  // === AUD — RBA F1 Interbank Overnight Cash Rate (CSV with header rows) ===
  static Future<RFRFetchResult> _fetchAONIA() {
    final url = Uri.parse('https://www.rba.gov.au/statistics/tables/csv/f1-data.csv');
    return _fetchCsv(
      tag: 'AONIA', url: url, dateCol: 0, valueCol: 3,
      fallback: RFRCurrency.aud.fallbackRate,
      dateFormat: 'dd-MMM-yyyy', takeLast: true);
  }

  // === Generic CSV fetcher ===
  static Future<RFRFetchResult> _fetchCsv({
    required String tag,
    required Uri url,
    required int dateCol,
    required int valueCol,
    required double fallback,
    String dateFormat = 'yyyy-MM-dd',
    bool takeLast = false,
    Duration timeout = _timeout,
  }) async {
    try {
      final resp = await http.get(url, headers: _headers).timeout(timeout);
      if (resp.statusCode != 200) {
        debugPrint('$tag fetch HTTP ${resp.statusCode}');
        return RFRFetchResult(fallback, 'unavailable', isLive: false);
      }
      // Default (en_US) locale — works for all the English-month feeds
      // we hit (BoE, RBA, FRED, ECB, NY Fed) without needing
      // `initializeDateFormatting()` to load locale data at startup.
      final inFmt = DateFormat(dateFormat);
      final outFmt = DateFormat('yyyy-MM-dd');

      final candidates = <_CsvRow>[];
      // Split on either CRLF or LF — the Swift port uses CharacterSet.newlines
      // because plain "\n" misses Windows-style line endings on some feeds.
      for (final raw in resp.body.split(RegExp(r'\r\n|\r|\n'))) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        final cols = line.split(',').map((c) => c.trim().replaceAll('"', '')).toList();
        if (cols.length <= dateCol || cols.length <= valueCol) continue;
        final dateStr = cols[dateCol];
        final valueStr = cols[valueCol];
        final DateTime? d;
        try {
          d = inFmt.parseStrict(dateStr);
        } catch (_) {
          continue;
        }
        final v = double.tryParse(valueStr);
        if (v == null) continue;
        candidates.add(_CsvRow(d, outFmt.format(d), v / 100.0));
      }
      if (candidates.isEmpty) {
        debugPrint('$tag fetch: no parseable rows');
        return RFRFetchResult(fallback, 'unavailable', isLive: false);
      }
      _CsvRow chosen;
      if (takeLast) {
        candidates.sort((a, b) => a.date.compareTo(b.date));
        chosen = candidates.last;
      } else {
        chosen = candidates.first;
      }
      return RFRFetchResult(chosen.value, chosen.dateStr);
    } catch (e) {
      debugPrint('$tag fetch failed: $e');
      return RFRFetchResult(fallback, 'unavailable', isLive: false);
    }
  }
}

class _CsvRow {
  final DateTime date;
  final String dateStr;
  final double value;
  _CsvRow(this.date, this.dateStr, this.value);
}

enum SOFRDataStatus { loading, live, fallback }

class RFRRate {
  final double rate;
  final String effectiveDate;
  final SOFRDataStatus status;
  const RFRRate(this.rate, this.effectiveDate, this.status);
}

/// Singleton observable store. Mirrors `SOFRRateStore` in the Swift app:
/// fetches all 5 currencies once at construction, exposes per-currency
/// rate/date/status, and supports `refreshAll()` for manual refresh.
///
/// Cold-start contract: every entry in [_rates] is populated with a
/// hardcoded fallback at construction *before* the async refresh fires,
/// so any first-frame reader sees a deterministic loading-state record
/// (status=loading, rate=fallback, effectiveDate='—') rather than an
/// empty map. As each live fetch resolves, the entry is replaced and
/// listeners fire.
class SOFRRateStore extends ChangeNotifier {
  static final SOFRRateStore shared = SOFRRateStore._();

  static const _prefsKey = 'icds.rfr.cache.v1';

  final Map<RFRCurrency, RFRRate> _rates = {};
  RFRRate? rateInfo(RFRCurrency ccy) => _rates[ccy];

  double rateFor(RFRCurrency ccy) => _rates[ccy]?.rate ?? ccy.fallbackRate;
  String effectiveDateFor(RFRCurrency ccy) => _rates[ccy]?.effectiveDate ?? '—';
  SOFRDataStatus statusFor(RFRCurrency ccy) =>
      _rates[ccy]?.status ?? SOFRDataStatus.loading;

  // Legacy USD-only API kept for parity with the Swift store.
  double get rate => rateFor(RFRCurrency.usd);
  String get effectiveDate => effectiveDateFor(RFRCurrency.usd);
  SOFRDataStatus get status => statusFor(RFRCurrency.usd);

  SOFRRateStore._() {
    // Pre-populate so cold-start readers get a deterministic record.
    for (final ccy in RFRCurrency.values) {
      _rates[ccy] = RFRRate(ccy.fallbackRate, '—', SOFRDataStatus.loading);
    }
    // Load persisted cache *then* fire the async refresh. The cache
    // hydration is fire-and-forget too — if it lands before the first
    // fetch resolves, the UI shows the last-known live rate instead of
    // a "loading…" / fallback state. If the fetch wins the race, the
    // live value replaces the cached one without flicker.
    unawaited(_hydrateFromCache().then((_) => refreshAll()));
  }

  /// Fetch all 5 currencies concurrently. Updates listeners as each
  /// completes (so the UI fills in incrementally instead of waiting for
  /// the slowest endpoint).
  Future<void> refreshAll() async {
    final futures = <Future<void>>[];
    for (final ccy in RFRCurrency.values) {
      futures.add(_refresh(ccy));
    }
    await Future.wait(futures);
  }

  Future<void> _refresh(RFRCurrency ccy) async {
    final r = await RFRFetcher.fetch(ccy);
    if (!r.isLive) {
      // Fetch failed. If we have a cached value (regardless of whether
      // its status is `live` or `loading` from cache hydration), keep
      // the cached rate + real effective date so the user sees how
      // stale it is. Otherwise use whatever the fetcher returned —
      // which for JPY is a synthetic "last likely published" date.
      final existing = _rates[ccy];
      if (existing != null &&
          existing.effectiveDate != '—' &&
          existing.effectiveDate != 'unavailable') {
        _rates[ccy] = RFRRate(
            existing.rate, existing.effectiveDate, SOFRDataStatus.fallback);
      } else {
        _rates[ccy] = RFRRate(r.rate, r.effectiveDate, SOFRDataStatus.fallback);
      }
    } else {
      _rates[ccy] = RFRRate(r.rate, r.effectiveDate, SOFRDataStatus.live);
      unawaited(_persistOne(ccy, _rates[ccy]!));
    }
    notifyListeners();
  }

  Future<void> _hydrateFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      var changed = false;
      for (final ccy in RFRCurrency.values) {
        final entry = map[ccy.code] as Map<String, dynamic>?;
        if (entry == null) continue;
        final rate = (entry['rate'] as num?)?.toDouble();
        final date = entry['effectiveDate'] as String?;
        if (rate == null || date == null || date.isEmpty) continue;
        // Skip if a live fetch has already resolved for this ccy.
        if (_rates[ccy]?.status == SOFRDataStatus.live) continue;
        // Mark hydrated values as `loading` — the rate + date are shown
        // to the user immediately, but the status indicator stays in
        // its "fetching" state until the live refresh resolves. If the
        // refresh succeeds we flip to `live` (green); if it fails we
        // flip to `fallback` (yellow). We deliberately do NOT flip
        // straight to `live` here, since hydrating a previously-cached
        // value is not the same as confirming a fresh fetch.
        _rates[ccy] = RFRRate(rate, date, SOFRDataStatus.loading);
        changed = true;
      }
      if (changed) notifyListeners();
    } catch (e) {
      debugPrint('RFR cache hydrate failed: $e');
    }
  }

  Future<void> _persistOne(RFRCurrency ccy, RFRRate r) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      final map = raw == null
          ? <String, dynamic>{}
          : (jsonDecode(raw) as Map<String, dynamic>);
      map[ccy.code] = {'rate': r.rate, 'effectiveDate': r.effectiveDate};
      await prefs.setString(_prefsKey, jsonEncode(map));
    } catch (e) {
      debugPrint('RFR cache persist failed: $e');
    }
  }

  /// Refresh only USD — used when the trade date changes in the Fee tab.
  /// Returns the same Future the underlying fetch produces, so callers
  /// (e.g. FeeViewModel) can await and surface fetch failures.
  Future<void> updateForTradeDate(DateTime _) => _refresh(RFRCurrency.usd);
}
