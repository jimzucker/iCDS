import 'package:flutter/material.dart';
import 'package:icds_spike/reference_curves.dart';
import 'package:icds_spike/sofr_fetcher.dart';

import 'theme.dart';

/// Port of `iCDS/icds/LiborView.swift`. Currency picker color-coded by
/// fetch status, live overnight banner, and the static reference swap
/// curve table for the selected currency.
class CurvesTab extends StatefulWidget {
  const CurvesTab({super.key});

  @override
  State<CurvesTab> createState() => _CurvesTabState();
}

class _CurvesTabState extends State<CurvesTab> {
  final SOFRRateStore _store = SOFRRateStore.shared;
  RFRCurrency _selected = RFRCurrency.usd;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _store.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() { if (mounted) setState(() {}); }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await _store.refreshAll();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// True when every currency is in fallback — i.e. no live data at all.
  /// We treat this as "offline" and show a banner suggesting refresh.
  bool _allFallback() {
    for (final c in RFRCurrency.values) {
      if (_store.statusFor(c) != SOFRDataStatus.fallback) return false;
    }
    return true;
  }

  Widget _offlineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.yellow.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.yellow.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 14, color: Colors.yellow),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'No live rates — showing static fallback values.',
              style: TextStyle(fontSize: 12, color: Colors.yellow, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: _refreshing ? null : _refresh,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry',
                style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Color _accent(SOFRDataStatus s) {
    switch (s) {
      case SOFRDataStatus.live:     return AppTheme.orange;
      case SOFRDataStatus.fallback: return Colors.yellow;
      case SOFRDataStatus.loading:  return const Color(0xFF808080);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selStatus = _store.statusFor(_selected);
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'Reference Rates',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.orange,
                  ),
                ),
                Positioned(
                  right: 16,
                  child: IconButton(
                    tooltip: 'Refresh all currencies',
                    icon: _refreshing
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.orange,
                            ),
                          )
                        : const Icon(Icons.refresh, color: AppTheme.orange),
                    onPressed: _refreshing ? null : _refresh,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Live RFR overnight rates by currency',
              style: TextStyle(fontSize: 12, color: Color(0xFF737373)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _currencyPicker(),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _statusBanner(selStatus),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _overnightBanner(selStatus),
            ),
            if (_allFallback()) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _offlineBanner(),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF333333), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selected.indexName} swap curve',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.dimText,
                    ),
                  ),
                  const Text(
                    'reference · 2021-04-26',
                    style: TextStyle(fontSize: 11, color: Color(0xFF737373)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: ReferenceCurves.forCurrency(_selected).length,
                itemBuilder: (context, i) {
                  final p = ReferenceCurves.forCurrency(_selected)[i];
                  return Container(
                    color: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.tenor,
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Menlo',
                            color: AppTheme.dimText,
                          ),
                        ),
                        Text(
                          '${(p.rate * 100).toStringAsFixed(4)}%',
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Menlo',
                            fontWeight: FontWeight.w600,
                            color: AppTheme.orange,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currencyPicker() {
    return Row(
      children: [
        for (final c in RFRCurrency.values) ...[
          Expanded(child: _ccyButton(c)),
          if (c != RFRCurrency.values.last) const SizedBox(width: 4),
        ],
      ],
    );
  }

  Widget _ccyButton(RFRCurrency ccy) {
    final status = _store.statusFor(ccy);
    final selected = ccy == _selected;
    Color bg;
    Color fg;
    Color border;
    double borderW;
    switch (status) {
      case SOFRDataStatus.fallback:
        bg = selected ? Colors.yellow.withValues(alpha: 0.35)
                      : Colors.yellow.withValues(alpha: 0.12);
        fg = Colors.yellow;
        border = Colors.yellow;
        borderW = 1.5;
        break;
      case SOFRDataStatus.loading:
        bg = selected ? const Color(0xFF333333) : const Color(0xFF1A1A1A);
        fg = const Color(0xFF999999);
        border = Colors.transparent;
        borderW = 0;
        break;
      case SOFRDataStatus.live:
        bg = selected ? AppTheme.orange.withValues(alpha: 0.30)
                      : const Color(0xFF262626);
        fg = selected ? AppTheme.orange : const Color(0xFFCCCCCC);
        border = selected ? AppTheme.orange : Colors.transparent;
        borderW = selected ? 2 : 0;
        break;
    }
    return InkWell(
      onTap: () => setState(() => _selected = ccy),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: borderW),
        ),
        alignment: Alignment.center,
        child: Text(
          ccy.code,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
        ),
      ),
    );
  }

  Widget _statusBanner(SOFRDataStatus s) {
    Widget icon;
    String text;
    Color fg;
    Color bg;
    switch (s) {
      case SOFRDataStatus.loading:
        icon = const _Dot(color: Color(0xFF808080));
        text = 'Fetching ${_selected.indexName}…';
        fg = const Color(0xFF808080);
        bg = const Color(0xFF1A1A1A);
        break;
      case SOFRDataStatus.live:
        icon = const _Dot(color: Colors.green);
        text = 'LIVE  ·  ${_selected.sourceLabel}';
        fg = Colors.green;
        bg = Colors.green.withValues(alpha: 0.08);
        break;
      case SOFRDataStatus.fallback:
        icon = const Icon(Icons.warning_rounded, size: 14, color: Colors.yellow);
        text = 'Reference rate — ${_selected.sourceLabel}';
        fg = Colors.yellow;
        bg = Colors.yellow.withValues(alpha: 0.10);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg)),
        ],
      ),
    );
  }

  Widget _overnightBanner(SOFRDataStatus s) {
    final rate = _store.rateFor(_selected);
    final date = formatIsoDate(_store.effectiveDateFor(_selected));
    final accent = _accent(s);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selected.indexName}  (${_selected.code})',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8C8C8C)),
              ),
              Text(
                s == SOFRDataStatus.loading
                    ? 'loading…'
                    : '${(rate * 100).toStringAsFixed(4)}%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Menlo',
                  color: accent,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('as of', style: TextStyle(fontSize: 11, color: Color(0xFF8C8C8C))),
              Text(
                date.isEmpty ? '—' : date,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Menlo',
                  color: s == SOFRDataStatus.fallback ? Colors.red : const Color(0xFFB3B3B3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
