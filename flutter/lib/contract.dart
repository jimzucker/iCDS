/// SNAC contract metadata loaded from contracts.json (the JSON-converted
/// form of iCDS/icds/contracts.plist). Mirrors `ISDAContract.swift`.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'cds_holiday_calendar.dart';

class Recovery {
  final String subordination; // "SEN", "SUB"
  final int recovery;          // percent

  const Recovery(this.subordination, this.recovery);
}

class ISDAContract {
  final String region;        // "NA", "EU", ...
  final String currency;      // "USD", "EUR", ...
  final CdsRegion calendar;   // mapped from "nyFed"/"target"/"tokyo"/"sydney"
  final int settleDays;
  final List<Recovery> recoveryList;
  final List<int> coupons;

  const ISDAContract({
    required this.region,
    required this.currency,
    required this.calendar,
    required this.settleDays,
    required this.recoveryList,
    required this.coupons,
  });

  static List<ISDAContract> _parse(List<dynamic> raw) {
    return raw.map((e) {
      final m = e as Map<String, dynamic>;
      final rec = (m['Recovery'] as Map<String, dynamic>);
      final keys = rec.keys.toList()..sort();
      return ISDAContract(
        region: m['Region'] as String,
        currency: (m['Currency'] as String?) ?? 'USD',
        calendar: CdsRegion.fromName((m['Calendar'] as String?) ?? 'nyFed'),
        settleDays: (m['SettleDays'] as int?) ?? 1,
        recoveryList: keys
            .map((k) => Recovery(k, (rec[k] as num).toInt()))
            .toList(growable: false),
        coupons: (m['Coupons'] as List<dynamic>)
            .map((c) => (c as num).toInt())
            .toList(growable: false),
      );
    }).toList(growable: false);
  }

  /// Load from the bundled `assets/contracts.json` asset.
  static Future<List<ISDAContract>> loadFromAsset(
      [String path = 'assets/contracts.json']) async {
    final text = await rootBundle.loadString(path);
    return _parse(jsonDecode(text) as List<dynamic>);
  }
}
