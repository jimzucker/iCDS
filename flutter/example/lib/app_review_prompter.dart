/// Tracks "successful pricing sessions" across launches and asks the OS
/// to show its review prompt at a tasteful threshold. Mirrors the Swift
/// app's `AppReviewPrompter` from FeeViewModel.swift — same key, same
/// threshold (5), same once-per-session guard.
///
/// Apple's `SKStoreReviewController` and Google Play's
/// `requestReview()` are both internally rate-limited (Apple: 3 prompts
/// / 365 days), so we just ask once when the counter first crosses the
/// threshold.

import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppReviewPrompter {
  static const _countKey = 'iCDS.successfulSessions';
  static const _promptThreshold = 5;
  static bool _sessionRecorded = false;

  /// Call once per first non-null pricing result during a session.
  /// Subsequent calls in the same session are no-ops.
  static Future<void> recordSuccessfulCalculation() async {
    if (_sessionRecorded) return;
    _sessionRecorded = true;

    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_countKey) ?? 0) + 1;
    await prefs.setInt(_countKey, count);

    if (count == _promptThreshold) {
      // Defer briefly so the prompt doesn't compete with the first
      // calculation animation.
      await Future.delayed(const Duration(seconds: 1));
      final available = await InAppReview.instance.isAvailable();
      if (available) {
        await InAppReview.instance.requestReview();
      }
    }
  }

  /// For tests — wipe the counter and the in-session guard.
  static Future<void> resetForTesting() async {
    _sessionRecorded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_countKey);
  }
}
