import 'package:flutter/material.dart';
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

  String _directionalLabel(double dollars) {
    if (dollars.abs() < 0.5) return 'NO UPFRONT · AT PAR';
    final actor = _vm.buySellIndex == 0 ? 'BUYER' : 'SELLER';
    return '$actor ${dollars > 0 ? "PAYS" : "RECEIVES"}';
  }

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
              _discountIndicator(),
              const SizedBox(height: 12),
              _regionRow(),
              const SizedBox(height: 12),
              _termRows(),
              const SizedBox(height: 12),
              _spreadFeeRow(),
              const SizedBox(height: 12),
              _outputGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _discountIndicator() {
    final rate = _vm.discountRate * 100;
    final indexName = _vm._indexNameForCurrency();
    final dateStr = formatIsoDate(_vm.discountRateDate);
    Widget marker;
    String body;
    Color color;
    switch (_vm.discountRateStatus) {
      case SOFRDataStatus.loading:
        marker = const _Dot(color: Color(0xFF808080), size: 6);
        body = '$indexName loading…';
        color = const Color(0xFF8C8C8C);
        break;
      case SOFRDataStatus.live:
        marker = const _Dot(color: Colors.green, size: 6);
        body = '$indexName ${rate.toStringAsFixed(4)}% · $dateStr';
        color = const Color(0xFFB3B3B3);
        break;
      case SOFRDataStatus.fallback:
        marker = const Icon(Icons.warning_rounded, size: 12, color: Colors.yellow);
        body = '$indexName unavailable — using ${rate.toStringAsFixed(3)}% reference';
        color = Colors.yellow;
        break;
    }
    return Row(
      children: [
        const Text('Discount:', style: TextStyle(fontSize: 11, color: Color(0xFF737373))),
        const SizedBox(width: 6),
        marker,
        const SizedBox(width: 6),
        Expanded(child: Text(body, style: TextStyle(fontSize: 11, color: color))),
      ],
    );
  }

  Widget _regionRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Region'),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < _vm.contracts.length; i++) ...[
              Expanded(
                child: _SegButton(
                  text: _vm.contracts[i].region,
                  selected: _vm.regionIndex == i,
                  onTap: () => _vm.regionIndex = i,
                ),
              ),
              if (i != _vm.contracts.length - 1) const SizedBox(width: 6),
            ],
          ],
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
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 4),
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
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('Maturity'),
            const SizedBox(height: 4),
            _SegRow(
              options: FeeViewModel.tenorLabels,
              selected: _vm.maturityIndex,
              onChange: (i) => _vm.maturityIndex = i,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Coupon (bp)'),
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 4),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.orange.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.orange.withValues(alpha: 0.6)),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Text('QUOTED SPREAD · tap',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.captionText, letterSpacing: 1)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_vm.spreadBp.round()}',
                  style: const TextStyle(
                    fontSize: 28, fontFamily: 'Menlo',
                    fontWeight: FontWeight.bold, color: AppTheme.orange,
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('bp', style: TextStyle(
                    fontSize: 16, fontFamily: 'Menlo',
                    fontWeight: FontWeight.w600, color: AppTheme.orange,
                  )),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Icon(Icons.edit, size: 14, color: AppTheme.orange),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                SizedBox(height: 4),
                Text('…', style: TextStyle(fontSize: 28, fontFamily: 'Menlo', fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            )
          : Column(
              children: [
                Text(
                  _directionalLabel(r.upfrontDollars),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4D4D4D), letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatCurrency(_noNegZero(r.upfrontDollars, 0.5).abs(), _vm.currency),
                    style: const TextStyle(
                      fontSize: 28, fontFamily: 'Menlo',
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _tradeDateCell()),
            const SizedBox(width: 6),
            Expanded(child: _outputCell('Settle Date',
              r != null ? formatDdMmmYy(r.valueDate) : '—')),
          ],
        ),
        if (r != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _outputCell('Par Spread',
                '${_noNegZero(r.parSpreadBp, 0.5).round()} bp')),
              const SizedBox(width: 6),
              Expanded(child: _outputCell('Upfront',
                '${_noNegZero(r.upfrontBp, 0.05).toStringAsFixed(1)} bp')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _outputCell('Accrued',
                formatCurrency(r.accruedDollars, _vm.currency))),
              const SizedBox(width: 6),
              Expanded(child: _outputCell('Price',
                r.price.toStringAsFixed(4))),
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
      ],
    );
  }

  Widget _tradeDateCell() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.orange.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.6)),
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
                    const Text('Trade Date  ·  tap to pick',
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

  Widget _outputCell(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8C8C8C))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontFamily: 'Menlo', color: AppTheme.orange)),
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
class _SegRow extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChange;
  const _SegRow({required this.options, required this.selected, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          Expanded(
            child: _SegButton(
              text: options[i],
              selected: i == selected,
              onTap: () => onChange(i),
            ),
          ),
          if (i != options.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _SegButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _SegButton({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.orange : const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, this.size = 8});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
