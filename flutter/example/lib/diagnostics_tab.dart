import 'package:flutter/material.dart';
import 'package:icds_spike/icds_spike.dart' as icds_spike;
import 'package:icds_spike/cds_calculator.dart';
import 'package:icds_spike/sofr_fetcher.dart';

import 'theme.dart';

/// Self-tests: JpmcdsDate sanity, CdsCalculator par/wide/tight, IMM
/// helpers, regional holiday calendar, and live RFR fetcher status.
/// Same content that used to be in main.dart before we built the real
/// tabbed UI — kept here as an in-app smoke test.
class DiagnosticsTab extends StatefulWidget {
  const DiagnosticsTab({super.key});

  @override
  State<DiagnosticsTab> createState() => _DiagnosticsTabState();
}

class _DiagnosticsTabState extends State<DiagnosticsTab> {
  // === Test 1: JpmcdsDate sanity ===
  late final int tdEpoch = icds_spike.jpmcdsDate(1601, 1, 1);
  late final int td2010 = icds_spike.jpmcdsDate(2010, 1, 4);
  late final int tdInvalid = icds_spike.jpmcdsDate(2024, 13, 99);
  late final int oneDay = icds_spike.jpmcdsDate(2026, 5, 5) -
      icds_spike.jpmcdsDate(2026, 5, 4);

  bool get _datesOk =>
      tdEpoch != -1 && td2010 != -1 && tdInvalid == -1 && oneDay == 1;

  // === Test 2: CdsCalculator pricing ===
  static final _tradeDate = DateTime(2026, 5, 4);

  late final CdsResult? par = CdsCalculator.calculate(
    tradeDate: _tradeDate, tenorYears: 5,
    parSpreadBp: 100, couponBp: 100, recoveryRate: 0.40,
    notional: 10_000_000, isBuy: true,
  );
  late final CdsResult? wide = CdsCalculator.calculate(
    tradeDate: _tradeDate, tenorYears: 5,
    parSpreadBp: 250, couponBp: 100, recoveryRate: 0.40,
    notional: 10_000_000, isBuy: true,
  );
  late final CdsResult? tight = CdsCalculator.calculate(
    tradeDate: _tradeDate, tenorYears: 5,
    parSpreadBp: 50, couponBp: 100, recoveryRate: 0.40,
    notional: 10_000_000, isBuy: true,
  );

  // === Test 3: IMM helpers ===
  late final DateTime nextIMMA  = CdsCalculator.nextIMMDate(DateTime(2026, 4, 1));
  late final DateTime nextIMMB  = CdsCalculator.nextIMMDate(DateTime(2026, 3, 20));
  late final DateTime prevIMMA  = CdsCalculator.prevIMMDate(DateTime(2026, 4, 1));

  // === Test 4: holiday calendar ===
  late final DateTime july4NY = CdsCalculator.addBusinessDays(1, DateTime(2026, 7, 2), region: CdsRegion.nyFed);
  late final DateTime july4EU = CdsCalculator.addBusinessDays(1, DateTime(2026, 7, 2), region: CdsRegion.target);
  late final DateTime may1NY  = CdsCalculator.addBusinessDays(1, DateTime(2026, 4, 30), region: CdsRegion.nyFed);
  late final DateTime may1EU  = CdsCalculator.addBusinessDays(1, DateTime(2026, 4, 30), region: CdsRegion.target);
  late final DateTime gwNY    = CdsCalculator.addBusinessDays(3, DateTime(2026, 4, 28), region: CdsRegion.nyFed);
  late final DateTime gwTok   = CdsCalculator.addBusinessDays(3, DateTime(2026, 4, 28), region: CdsRegion.tokyo);

  bool get _immOk =>
      nextIMMA == DateTime(2026, 6, 20) &&
      nextIMMB == DateTime(2026, 6, 20) &&
      prevIMMA == DateTime(2026, 3, 20);

  bool get _calOk =>
      july4NY == DateTime(2026, 7, 6)  &&
      july4EU == DateTime(2026, 7, 3)  &&
      may1NY  == DateTime(2026, 5, 1)  &&
      may1EU  == DateTime(2026, 5, 4)  &&
      gwNY    == DateTime(2026, 5, 1)  &&
      gwTok   == DateTime(2026, 5, 6);

  bool get _pricingOk =>
      par != null && wide != null && tight != null &&
      par!.upfrontFraction.abs() < 1e-4 &&
      wide!.upfrontFraction > 0.0 &&
      tight!.upfrontFraction < 0.0;

  bool get _ok => _datesOk && _pricingOk && _immOk && _calOk;

  final _store = SOFRRateStore.shared;

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

  String _bp(CdsResult? r) => r == null ? 'null' : '${r.upfrontBp.toStringAsFixed(2)} bp';
  String _usd(CdsResult? r) => r == null ? 'null' : '\$${r.upfrontDollars.toStringAsFixed(0)}';

  String _statusMark(SOFRDataStatus s) {
    switch (s) {
      case SOFRDataStatus.live:     return '✓';
      case SOFRDataStatus.fallback: return '·';
      case SOFRDataStatus.loading:  return '…';
    }
  }

  @override
  Widget build(BuildContext context) {
    const sectionTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.orange);
    const rowStyle = TextStyle(fontSize: 12, fontFamily: 'Menlo', color: AppTheme.offWhite);
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Test 1 — JpmcdsDate', style: sectionTitle),
              Text('JpmcdsDate(1601, 1, 1) = $tdEpoch', style: rowStyle),
              Text('JpmcdsDate(2010, 1, 4) = $td2010', style: rowStyle),
              Text('JpmcdsDate(2024, 13, 99) = $tdInvalid (expect -1)', style: rowStyle),
              Text('Δ(2026-05-05, 2026-05-04) = $oneDay (expect 1)', style: rowStyle),
              const SizedBox(height: 16),
              const Text('Test 2 — CdsCalculator (\$10M, 5Y, today=2026-05-04)', style: sectionTitle),
              Text('par   (sp=100, cp=100): ${_bp(par)}  / ${_usd(par)}', style: rowStyle),
              Text('wide  (sp=250, cp=100): ${_bp(wide)} / ${_usd(wide)}', style: rowStyle),
              Text('tight (sp= 50, cp=100): ${_bp(tight)} / ${_usd(tight)}', style: rowStyle),
              const SizedBox(height: 16),
              const Text('Test 3 — IMM helpers', style: sectionTitle),
              Text('next IMM after 2026-04-01 = ${formatDdMmmYy(nextIMMA)}', style: rowStyle),
              Text('next IMM after 2026-03-20 = ${formatDdMmmYy(nextIMMB)} (strictly after)', style: rowStyle),
              Text('prev IMM before 2026-04-01 = ${formatDdMmmYy(prevIMMA)}', style: rowStyle),
              const SizedBox(height: 16),
              const Text('Test 4 — Holiday calendar by region', style: sectionTitle),
              Text('Thu 2026-07-02 + 1 BD nyFed  = ${formatDdMmmYy(july4NY)}', style: rowStyle),
              Text('Thu 2026-07-02 + 1 BD target = ${formatDdMmmYy(july4EU)}', style: rowStyle),
              Text('Thu 2026-04-30 + 1 BD nyFed  = ${formatDdMmmYy(may1NY)}', style: rowStyle),
              Text('Thu 2026-04-30 + 1 BD target = ${formatDdMmmYy(may1EU)}', style: rowStyle),
              Text('Tue 2026-04-28 + 3 BD nyFed  = ${formatDdMmmYy(gwNY)}', style: rowStyle),
              Text('Tue 2026-04-28 + 3 BD tokyo  = ${formatDdMmmYy(gwTok)}', style: rowStyle),
              const SizedBox(height: 16),
              const Text('Test 5 — RFR fetcher (live)', style: sectionTitle),
              for (final ccy in RFRCurrency.values)
                Text(
                  '${_statusMark(_store.statusFor(ccy))} ${ccy.indexName.padRight(6)} '
                  '${(_store.rateFor(ccy) * 100).toStringAsFixed(3)}% '
                  '(${_store.effectiveDateFor(ccy)})  ${ccy.sourceLabel}',
                  style: rowStyle,
                ),
              const SizedBox(height: 24),
              Text(
                _ok
                  ? '✓ All deterministic tests pass on this platform.'
                  : '✗ Something is off — see rows above.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ok ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
