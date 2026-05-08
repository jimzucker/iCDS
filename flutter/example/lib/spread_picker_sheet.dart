import 'package:flutter/material.dart';
import 'package:icds_spike/cds_calculator.dart';
import 'package:icds_spike/fee_view_model.dart';

import 'theme.dart';

/// Port of `FeeView.swift`'s spread picker sheet — pending value display,
/// live preview card, chip grid (4×3 with neg-chip hiding), and a 3×4
/// numeric keypad. Returns the picked spread (>=1 bp, <=10000 bp) when
/// the user taps Done, or null on Cancel.
class SpreadPickerSheet extends StatefulWidget {
  const SpreadPickerSheet({
    super.key,
    required this.viewModel,
    this.maxSpreadBp = 10000,
  });

  final FeeViewModel viewModel;
  final int maxSpreadBp;

  static Future<int?> show(BuildContext context, FeeViewModel vm) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SpreadPickerSheet(viewModel: vm),
    );
  }

  @override
  State<SpreadPickerSheet> createState() => _SpreadPickerSheetState();
}

class _SpreadPickerSheetState extends State<SpreadPickerSheet> {
  late String _buffer;

  int get _coupon => widget.viewModel.couponBp.round();
  int get _cap => widget.maxSpreadBp;
  int get _pending {
    final v = int.tryParse(_buffer);
    if (v == null || v <= 0) return widget.viewModel.spreadBp.round();
    return v;
  }
  bool get _isOverCap => _pending > _cap;

  @override
  void initState() {
    super.initState();
    _buffer = widget.viewModel.spreadBp.round().toString();
  }

  String _hint() {
    if (_isOverCap) return 'exceeds max $_cap bp';
    if (_pending == 0) return ' ';
    if (_pending == _coupon) return 'AT PAR';
    final diff = _pending - _coupon;
    return diff > 0 ? 'Coupon + $diff bp' : 'Coupon − ${-diff} bp';
  }

  void _appendDigit(String d) {
    if (_buffer.length >= 5) return;
    setState(() {
      _buffer = _buffer == '0' ? d : _buffer + d;
    });
  }

  void _backspace() {
    if (_buffer.isEmpty) return;
    setState(() {
      _buffer = _buffer.substring(0, _buffer.length - 1);
    });
  }

  void _clear() => setState(() => _buffer = '');

  void _setChipValue(int v) => setState(() => _buffer = v.toString());

  void _commit() {
    final v = int.tryParse(_buffer);
    if (v == null || v < 1 || v > _cap) return;
    Navigator.pop(context, v);
  }

  CdsResult? _preview() {
    if (_pending <= 0 || _isOverCap) return null;
    return widget.viewModel.previewUpfront(_pending.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final valueColor = _isOverCap ? Colors.red : AppTheme.orange;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          color: Colors.black,
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 4),
                        // Pending value
                        Text(
                          '$_pending bp',
                          style: TextStyle(
                            fontSize: 44,
                            fontFamily: 'Menlo',
                            fontWeight: FontWeight.bold,
                            color: valueColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Coupon context + relation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Coupon $_coupon bp',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF8C8C8C))),
                            const SizedBox(width: 8),
                            const Text('·', style: TextStyle(fontSize: 11, color: Color(0xFF4D4D4D))),
                            const SizedBox(width: 8),
                            Text(
                              _hint(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isOverCap ? Colors.red : AppTheme.dimText,
                              ),
                            ),
                          ],
                        ),
                        Text('max $_cap bp',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                        const SizedBox(height: 8),
                        _previewCard(),
                        const SizedBox(height: 8),
                        _chipGrid(),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFF333333), height: 1),
                        const SizedBox(height: 12),
                        _keypad(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _topBar() {
    final canCommit = _pending > 0 && _pending <= _cap;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.orange)),
          ),
          const Spacer(),
          const Text('Quoted Spread',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton(
            onPressed: canCommit ? _commit : null,
            child: Text(
              'Done',
              style: TextStyle(
                color: canCommit ? AppTheme.orange : const Color(0xFF555555),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewCard() {
    final preview = _preview();
    if (preview == null) {
      return const SizedBox(height: 88);
    }
    final dollars = preview.upfrontDollars;
    final mag = dollars.abs();
    final amount = formatCurrency(mag, widget.viewModel.currency);
    final isBuy = widget.viewModel.buySellIndex == 0;
    final actor = isBuy ? 'BUYER' : 'SELLER';
    String action;
    if (mag < 0.5) {
      action = 'AT PAR · NO UPFRONT';
    } else {
      action = dollars > 0 ? '$actor PAYS' : '$actor RECEIVES';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2D2D2D)),
      ),
      child: Column(
        children: [
          const Text('ESTIMATED UPFRONT',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: Color(0xFF666666), letterSpacing: 1.2,
              )),
          const SizedBox(height: 2),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 22, fontFamily: 'Menlo',
              fontWeight: FontWeight.bold, color: AppTheme.orange,
            ),
          ),
          Text(
            action,
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: Color(0xFF999999), letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipGrid() {
    Widget chip(String label, int value, {bool prominent = false}) {
      final active = _pending == value;
      Color bg;
      Color border;
      if (active) {
        bg = AppTheme.orange.withValues(alpha: 0.30);
        border = AppTheme.orange.withValues(alpha: 0.7);
      } else if (prominent) {
        bg = AppTheme.orange.withValues(alpha: 0.15);
        border = AppTheme.orange.withValues(alpha: 0.4);
      } else {
        bg = const Color(0xFF262626);
        border = Colors.transparent;
      }
      return Expanded(
        child: InkWell(
          onTap: () => _setChipValue(value),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: border),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: prominent ? FontWeight.bold : FontWeight.w500,
                color: AppTheme.orange,
              ),
            ),
          ),
        ),
      );
    }

    /// A negative-offset chip becomes an invisible spacer when the result
    /// would clamp to ≤ 0 — preserves grid alignment.
    Widget negChip(String label, int offset) {
      final v = _coupon - offset;
      if (v > 0) return chip(label, v);
      return const Expanded(child: SizedBox.shrink());
    }

    Widget row(List<Widget> children) {
      final spaced = <Widget>[];
      for (var i = 0; i < children.length; i++) {
        spaced.add(children[i]);
        if (i != children.length - 1) spaced.add(const SizedBox(width: 6));
      }
      return Row(children: spaced);
    }

    return Column(
      children: [
        row([
          negChip('Coupon -200', 200),
          negChip('Coupon -100', 100),
          negChip('Coupon -50',  50),
        ]),
        const SizedBox(height: 6),
        row([
          chip('At Par',      _coupon, prominent: true),
          chip('Coupon +50',  _coupon + 50),
          chip('Coupon +100', _coupon + 100),
        ]),
        const SizedBox(height: 6),
        row([
          chip('Coupon +200',  _coupon + 200),
          chip('Coupon +500',  _coupon + 500),
          chip('Coupon +1000', _coupon + 1000),
        ]),
        const SizedBox(height: 6),
        row([
          chip('Coupon +2000', _coupon + 2000),
          chip('Coupon +5000', _coupon + 5000),
          chip('Max $_cap',    _cap),
        ]),
      ],
    );
  }

  Widget _keypad() {
    Widget digit(String d) {
      return Expanded(
        child: InkWell(
          onTap: () => _appendDigit(d),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              d,
              style: const TextStyle(
                fontSize: 26, fontFamily: 'Menlo',
                fontWeight: FontWeight.w500, color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    Widget action(IconData icon, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: const Color(0xFFB3B3B3)),
          ),
        ),
      );
    }

    Widget gap() => const SizedBox(width: 10);

    return Column(
      children: [
        Row(children: [digit('1'), gap(), digit('2'), gap(), digit('3')]),
        const SizedBox(height: 10),
        Row(children: [digit('4'), gap(), digit('5'), gap(), digit('6')]),
        const SizedBox(height: 10),
        Row(children: [digit('7'), gap(), digit('8'), gap(), digit('9')]),
        const SizedBox(height: 10),
        Row(children: [
          action(Icons.backspace_outlined, _backspace),
          gap(),
          digit('0'),
          gap(),
          action(Icons.cancel_outlined, _clear),
        ]),
      ],
    );
  }
}
