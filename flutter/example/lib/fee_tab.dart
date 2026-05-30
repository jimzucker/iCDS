//
//  fee_tab.dart
//  icds
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:icds_spike/cds_calculator.dart';
import 'package:icds_spike/fee_view_model.dart';
import 'package:icds_spike/sofr_fetcher.dart';

import 'app_review_prompter.dart';
import 'spread_picker_sheet.dart';
import 'theme.dart';

/// Port of `iCDS/icds/FeeView.swift` — region/buy-sell/maturity/coupon/
/// notional/recovery inputs, an editable spread, and the upfront fee
/// outputs (par spread, upfront bp, accrued, price, start, maturity,
/// settle). The complex numeric-keypad sheet from the Swift app is
/// simplified here to a TextField inside a dialog — same job, less
/// chrome — leaving room to grow the chip grid in a follow-up if the
/// Flutter port becomes the production app.
class FeeTab extends StatefulWidget {
  const FeeTab({super.key});

  @override
  State<FeeTab> createState() => _FeeTabState();
}

class _FeeTabState extends State<FeeTab> {
  late final FeeViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = FeeViewModel();
    _vm.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _vm.removeListener(_onUpdate);
    _vm.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    if (_vm.result != null) {
      // Fire-and-forget; the prompter has its own once-per-session guard.
      AppReviewPrompter.recordSuccessfulCalculation();
    }
    setState(() {});
  }

  double _noNegZero(double v, double eps) => v.abs() < eps ? 0.0 : v;

  static final _bpFmt = NumberFormat('#,##0');
  String _bpWithCommas(int bp) => _bpFmt.format(bp);

  @override
  Widget build(BuildContext context) {
    if (_vm.contracts.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: AppTheme.orange)),
      );
    }
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _regionRow(),
              const SizedBox(height: 3),
              _termRows(),
              const SizedBox(height: 3),
              _spreadFeeRow(),
              const SizedBox(height: 3),
              _outputGrid(),
              const SizedBox(height: 3),
              _defaultRiskChart(),
              const SizedBox(height: 3),
              _riskRow(),
              const SizedBox(height: 3),
              _dateFooterRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _regionRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Region'),
        const SizedBox(height: 2),
        _SegRow(
          options: _vm.contracts.map((c) => c.region).toList(),
          selected: _vm.regionIndex,
          onChange: (i) => _vm.regionIndex = i,
        ),
      ],
    );
  }

  Widget _termRows() {
    final c = _vm.contract!;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Buy / Sell'),
                  const SizedBox(height: 2),
                  _SegRow(
                    options: const ['Buy', 'Sell'],
                    selected: _vm.buySellIndex,
                    onChange: (i) => _vm.buySellIndex = i,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Recovery  ${_vm.recoveryPct}%'),
                  const SizedBox(height: 2),
                  _SegRow(
                    options: c.recoveryList.map((r) => r.subordination).toList(),
                    selected: _vm.recoveryIndex,
                    onChange: (i) => _vm.recoveryIndex = i,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('Maturity'),
            const SizedBox(height: 2),
            _SegRow(
              options: FeeViewModel.tenorLabels,
              selected: _vm.maturityIndex,
              onChange: (i) => _vm.maturityIndex = i,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Coupon (bp)'),
                  const SizedBox(height: 2),
                  _SegRow(
                    options: c.coupons.map((v) => v.toString()).toList(),
                    selected: _vm.couponIndex,
                    onChange: (i) => _vm.couponIndex = i,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Notional'),
                  const SizedBox(height: 2),
                  _SegRow(
                    options: FeeViewModel.notionalLabels,
                    selected: _vm.notionalIndex,
                    onChange: (i) => _vm.notionalIndex = i,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _spreadFeeRow() {
    return Row(
      children: [
        Expanded(child: _spreadCard()),
        const SizedBox(width: 8),
        Expanded(child: _feeCard()),
      ],
    );
  }

  Widget _spreadCard() {
    return InkWell(
      onTap: _editSpread,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.orange.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.orange.withValues(alpha: 0.6)),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Text('QUOTED SPREAD',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.captionText, letterSpacing: 1)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _bpWithCommas(_vm.spreadBp.round()),
                  style: const TextStyle(
                    fontSize: 22, fontFamily: 'Menlo',
                    fontWeight: FontWeight.bold, color: AppTheme.orange,
                  ),
                ),
                const SizedBox(width: 5),
                const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text('bp', style: TextStyle(
                    fontSize: 13, fontFamily: 'Menlo',
                    fontWeight: FontWeight.w600, color: AppTheme.orange,
                  )),
                ),
                const SizedBox(width: 3),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.edit, size: 12, color: AppTheme.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeCard() {
    final r = _vm.result;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.yellow,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: r == null
          ? const Column(
              children: [
                Text('CALCULATING',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4D4D4D), letterSpacing: 1)),
                SizedBox(height: 2),
                Text('…', style: TextStyle(fontSize: 22, fontFamily: 'Menlo', fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            )
          : Column(
              children: [
                const Text(
                  'DIRTY UPFRONT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4D4D4D), letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatSignedCurrency(_noNegZero(r.upfrontDollars + r.accruedDollars, 0.5), _vm.currency),
                    style: const TextStyle(
                      fontSize: 22, fontFamily: 'Menlo',
                      fontWeight: FontWeight.bold, color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _editSpread() async {
    final v = await SpreadPickerSheet.show(context, _vm);
    if (v != null && v >= 1 && v <= 10000) {
      _vm.spreadBp = v.toDouble();
    }
  }

  Widget _outputGrid() {
    final r = _vm.result;
    if (r == null) return const SizedBox.shrink();
    return Column(
      children: [
        // Cash split — the two components of the DIRTY UPFRONT headline
        // above. Rendered larger to mark their role in the hierarchy.
        Row(
          children: [
            Expanded(child: _outputCell('Accrued',
              formatCurrency(r.accruedDollars, _vm.currency),
              emphasized: true)),
            const SizedBox(width: 6),
            Expanded(child: _outputCell('Upfront Fee',
              formatSignedCurrency(r.upfrontDollars, _vm.currency),
              emphasized: true)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _outputCell('Start', formatDdMmmYy(r.startDate))),
            const SizedBox(width: 6),
            Expanded(child: _outputCell('Maturity', formatDdMmmYy(r.endDate))),
          ],
        ),
      ],
    );
  }

  /// Trade Date / Settle Date row at the bottom of the Calc tab.
  /// Defaults to today / T+1 and rarely changed in normal use — sits low
  /// to keep prime real estate for the cash split and analytics above.
  Widget _dateFooterRow() {
    final r = _vm.result;
    return Row(
      children: [
        Expanded(child: _tradeDateCell()),
        const SizedBox(width: 6),
        Expanded(child: _outputCell('Settle Date',
          r != null ? formatDdMmmYy(r.valueDate) : '—')),
      ],
    );
  }

  Widget _tradeDateCell() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _stepperButton(Icons.chevron_left, _stepBack),
          Expanded(
            child: InkWell(
              onTap: _pickTradeDate,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trade Date',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8C8C8C))),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          formatDdMmmYy(_vm.tradeDate),
                          style: const TextStyle(
                            fontSize: 14, fontFamily: 'Menlo', color: AppTheme.orange,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          _stepperButton(Icons.chevron_right, _stepForward),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 30, height: 36,
        alignment: Alignment.center,
        child: Icon(icon, size: 22, color: AppTheme.orange),
      ),
    );
  }

  /// Step back to the previous business day for the current region.
  /// We move the offset by 1 calendar day at a time and let the VM's
  /// tradeDate getter snap to the last valid business day, but to land
  /// on a *different* business day we may need multiple decrements
  /// (e.g. Mon → previous Fri = -3 cal days). Loop until tradeDate
  /// changes — capped at 7 attempts so a fully-blocked week doesn't hang.
  void _stepBack() {
    final start = _vm.tradeDate;
    var off = _vm.tradeDateOffset;
    for (var i = 0; i < 7; i++) {
      off -= 1;
      _vm.tradeDateOffset = off;
      if (_vm.tradeDate != start) return;
    }
  }

  void _stepForward() {
    final start = _vm.tradeDate;
    var off = _vm.tradeDateOffset;
    for (var i = 0; i < 7; i++) {
      // tradeDate is clamped to today by the VM (offset clamped to <= 0),
      // so once we're at 0 we can't go forward.
      if (off >= 0) return;
      off += 1;
      _vm.tradeDateOffset = off;
      if (_vm.tradeDate != start) return;
    }
  }

  Future<void> _pickTradeDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _vm.tradeDate,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.orange),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final daysDelta = picked
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    _vm.tradeDateOffset = daysDelta;
  }

  /// Computed-value cell. `emphasized` bumps the value text to 18pt
  /// semibold for the cash split (Accrued / Upfront Fee) which compose
  /// the headline Dirty Upfront card above.
  Widget _outputCell(String label, String value, {bool emphasized = false}) {
    return Container(
      padding: EdgeInsets.all(emphasized ? 7 : 6),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8C8C8C))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(
            fontSize: emphasized ? 18 : 14,
            fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
            fontFamily: 'Menlo',
            color: const Color(0xFFEBEBEB),
          )),
        ],
      ),
    );
  }

  /// First-order risk (CS01 / IR DV01 / Rec01) by bump-and-reprice.
  /// Port of Swift `FeeView.riskRow`.
  Widget _riskRow() {
    final rk = _vm.risk;
    if (rk == null) return const SizedBox.shrink();
    String money(double v) {
      final s = formatCurrency(v.abs(), _vm.currency);
      return (v < 0 && v.abs() >= 0.5) ? '−$s' : s;
    }

    return Row(
      children: [
        Expanded(child: _riskCell('CS01', money(rk.cs01), 'per +1 bp')),
        const SizedBox(width: 6),
        Expanded(child: _riskCell('IR DV01', money(rk.irDV01), 'per +1 bp')),
        const SizedBox(width: 6),
        Expanded(child: _riskCell('Rec01', money(rk.rec01), 'per +1 pt')),
      ],
    );
  }

  Widget _riskCell(String k, String v, String s) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF8C8C8C))),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(v, style: const TextStyle(
              fontSize: 14, fontFamily: 'Menlo', color: Color(0xFFEBEBEB))),
          ),
          const SizedBox(height: 1),
          Text(s, style: const TextStyle(fontSize: 9, color: Color(0xFF595959))),
        ],
      ),
    );
  }

  /// Flat-hazard cumulative default probability at each SNAC tenor.
  /// Bars scale to the longest-tenor probability; tapping a bar selects
  /// that maturity. Port of Swift `FeeView.defaultRiskChart`.
  Widget _defaultRiskChart() {
    final recovery = _vm.recoveryPct / 100.0;
    const years = FeeViewModel.tenorYearsList;
    const labels = FeeViewModel.tenorLabels;
    final probs = [
      for (final y in years)
        CdsCalculator.cumulativeDefaultProb(
          spreadBp: _vm.spreadBp,
          recoveryRate: recovery,
          years: y,
        ),
    ];
    final maxP = probs.fold<double>(0.0001, (m, p) => p > m ? p : m);
    final sel = _vm.maturityIndex.clamp(0, probs.length - 1).toInt();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('DEFAULT RISK',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                  letterSpacing: 1, color: Color(0xFFA6A6A6))),
              const SizedBox(width: 4),
              const Text('· by maturity',
                style: TextStyle(fontSize: 10, color: Color(0xFF8C8C8C))),
              const Spacer(),
              Text(
                '${labels[sel]}  ≈ ${(probs[sel] * 100).toStringAsFixed(1)}% to default',
                style: const TextStyle(fontSize: 10, fontFamily: 'Menlo', color: AppTheme.orange),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 82,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < years.length; i++) ...[
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _vm.maturityIndex = i,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${(probs[i] * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 9, fontFamily: 'Menlo',
                              color: i == sel ? AppTheme.orange : const Color(0xFF8C8C8C),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: (probs[i] / maxP * 46).clamp(4.0, 46.0).toDouble(),
                            decoration: BoxDecoration(
                              color: i == sel ? AppTheme.orange : const Color(0xFF3A3A3A),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 10, fontFamily: 'Menlo',
                              color: i == sel ? AppTheme.orange : const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (i != years.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text('Cumulative default prob · flat-hazard',
            style: TextStyle(fontSize: 9, color: Color(0xFF666666))),
        ],
      ),
    );
  }
}

extension _IndexNameHelper on FeeViewModel {
  String _indexNameForCurrency() {
    switch (currency) {
      case 'EUR': return RFRCurrency.eur.indexName;
      case 'GBP': return RFRCurrency.gbp.indexName;
      case 'JPY': return RFRCurrency.jpy.indexName;
      case 'AUD': return RFRCurrency.aud.indexName;
      default:    return RFRCurrency.usd.indexName;
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.dimText));
}

/// _SegRow rebuilds whenever the parent FeeTab calls setState (i.e. on
/// every VM notify, including unrelated input changes). This is fine at
/// today's interaction rate — Flutter's Element reconciler reuses the
/// underlying InkWell/Container nodes — but if jank ever shows up the
/// optimization is to wrap each input group in its own `ListenableBuilder`
/// listening to a Selector slice of FeeViewModel rather than the whole VM.
/// iOS-style segmented control: a single rounded "pill" containing
/// all options with one inset highlight on the selected cell. Matches
/// SwiftUI's `Picker(.segmented)` look (no internal dividers).
class _SegRow extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChange;
  const _SegRow({required this.options, required this.selected, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChange(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: i == selected
                      ? const Color(0xFF737373)
                      : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    options[i],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

