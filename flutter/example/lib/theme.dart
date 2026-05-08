import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Single source of the orange/black palette shared across tabs.
/// Mirrors `Color(red: 1, green: 0.502, blue: 0)` from the Swift app.
class AppTheme {
  static const orange = Color(0xFFFF8000);
  static const yellow = Color(0xFFFFFF65);
  static const offWhite = Color(0xFFE0E0E0);
  static const dimText = Color(0xFFB3B3B3);
  static const captionText = Color(0xFF8C8C8C);
  static const cardFill = Color(0xFF121212);
  static const cardBorder = Color(0xFF2D2D2D);
}

/// `dd-MMM-yy` formatter shared across tabs (matches Swift `formatTDate`).
String formatDdMmmYy(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final dd = d.day.toString().padLeft(2, '0');
  final yy = (d.year % 100).toString().padLeft(2, '0');
  return '$dd-${months[d.month - 1]}-$yy';
}

/// Reformat an ISO `yyyy-MM-dd` string into the `dd-MMM-yy` form.
String formatIsoDate(String iso) {
  if (iso.isEmpty || iso == '—' || iso == 'unavailable') return iso;
  try {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    return formatDdMmmYy(d);
  } catch (_) {
    return iso;
  }
}

/// Currency formatter matching the Swift app's `NumberFormatter(.currency)`
/// — proper grouping/separator/symbol per ISO code, integer cents (no
/// fractional digits, mirroring the Swift `maximumFractionDigits = 0`).
String formatCurrency(double dollars, String code) {
  final fmt = NumberFormat.simpleCurrency(name: code, decimalDigits: 0);
  return fmt.format(dollars);
}
