/// Integration-test parity port of `iCDS/icdsTests/CDSReferenceTests.swift`.
/// Validates the Dart-side ISDA C wrapper against the same QuantLib /
/// ISDA RFR reference values the iOS suite anchors on. All cases use
/// the new shaped-IR-curve entry point (icds_spike_price_with_curve)
/// rather than the flat 30y curve used by the production app.

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:icds_spike/icds_spike.dart' as icds;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ===== QuantLib testIsdaEngine — May 21 2009 USD curve =====
  // Reference: QuantLib test-suite/creditdefaultswap.cpp markitValues[].
  final qlTradeDate  = DateTime(2009, 5, 21);
  final qlSettleDate = DateTime(2009, 5, 26);   // T+3 biz
  final qlStepinDate = DateTime(2009, 5, 22);   // T+1 calendar
  final qlStartDate  = DateTime(2009, 3, 20);   // previous IMM

  final qlInstruments = <icds.CurveInstrument>[
    // Deposits 1M..1Y
    icds.CurveInstrument('M', '1M', 0.003081),
    icds.CurveInstrument('M', '2M', 0.005525),
    icds.CurveInstrument('M', '3M', 0.007163),
    icds.CurveInstrument('M', '6M', 0.012413),
    icds.CurveInstrument('M', '9M', 0.014000),
    icds.CurveInstrument('M', '1Y', 0.015488),
    // Swaps 2Y..30Y
    icds.CurveInstrument('S', '2Y',  0.011907),
    icds.CurveInstrument('S', '3Y',  0.016990),
    icds.CurveInstrument('S', '4Y',  0.021198),
    icds.CurveInstrument('S', '5Y',  0.024440),
    icds.CurveInstrument('S', '6Y',  0.026937),
    icds.CurveInstrument('S', '7Y',  0.028967),
    icds.CurveInstrument('S', '8Y',  0.030504),
    icds.CurveInstrument('S', '9Y',  0.031719),
    icds.CurveInstrument('S', '10Y', 0.032790),
    icds.CurveInstrument('S', '12Y', 0.034535),
    icds.CurveInstrument('S', '15Y', 0.036217),
    icds.CurveInstrument('S', '20Y', 0.036981),
    icds.CurveInstrument('S', '25Y', 0.037246),
    icds.CurveInstrument('S', '30Y', 0.037605),
  ];

  double? upfrontQL({
    required DateTime endDate,
    required double couponBp,
    required double spreadBp,
    required double recovery,
  }) {
    final r = icds.priceWithCurve(
      instruments: qlInstruments,
      curveValueDate: qlSettleDate,  // Swift passes valueDate (settle) as curve date
      tradeDate: qlTradeDate,
      settleDate: qlSettleDate,
      stepinDate: qlStepinDate,
      startDate: qlStartDate,
      endDate: endDate,
      mmDcc: icds.IsdaDcc.act360,
      fixedSwapFreq: 2,             // semi-annual
      floatSwapFreq: 4,             // quarterly
      fixedSwapDcc: icds.IsdaDcc.b30360,
      floatSwapDcc: icds.IsdaDcc.act360,
      couponBp: couponBp,
      parSpreadBp: spreadBp,
      recoveryRate: recovery,
      isPriceClean: false,           // QL test uses dirty price (isPriceClean=0)
    );
    return r?.upfrontFraction;
  }

  group('QuantLib testIsdaEngine — May 21 2009 USD curve', () {
    test('1Y / spread 10bp / R=40%', () {
      final u = upfrontQL(endDate: DateTime(2010, 6, 20), couponBp: 100, spreadBp: 10, recovery: 0.40);
      const expected = -0.01152792582857583;
      expect(u, isNotNull);
      expect((u! - expected).abs(), lessThan(expected.abs() * 0.02));
    });
    test('1Y / spread 1000bp / R=40%', () {
      final u = upfrontQL(endDate: DateTime(2010, 6, 20), couponBp: 100, spreadBp: 1000, recovery: 0.40);
      const expected = 894985.6298 / 10_000_000.0;
      expect(u, isNotNull);
      expect((u! - expected).abs(), lessThan(expected.abs() * 0.05));
    });
    test('1Y / spread 10bp / R=20%', () {
      final u = upfrontQL(endDate: DateTime(2010, 6, 20), couponBp: 100, spreadBp: 10, recovery: 0.20);
      const expected = -0.0115301433691427;
      expect(u, isNotNull);
      expect((u! - expected).abs(), lessThan(expected.abs() * 0.02));
    });
    test('2Y / spread 10bp / R=40%', () {
      final u = upfrontQL(endDate: DateTime(2011, 6, 20), couponBp: 100, spreadBp: 10, recovery: 0.40);
      const expected = -0.020434542331881026;
      expect(u, isNotNull);
      expect((u! - expected).abs(), lessThan(expected.abs() * 0.02));
    });
    test('2Y / spread 1000bp / R=40%', () {
      final u = upfrontQL(endDate: DateTime(2011, 6, 20), couponBp: 100, spreadBp: 1000, recovery: 0.40);
      const expected = 1579803.626 / 10_000_000.0;
      expect(u, isNotNull);
      expect((u! - expected).abs(), lessThan(expected.abs() * 0.05));
    });
    test('5Y / spread 10bp / R=40%', () {
      final u = upfrontQL(endDate: DateTime(2014, 6, 20), couponBp: 100, spreadBp: 10, recovery: 0.40);
      const expected = -0.04567939940411767;
      expect(u, isNotNull);
      expect((u! - expected).abs(), lessThan(expected.abs() * 0.02));
    });
    test('5Y / spread 1000bp / R=40%', () {
      final u = upfrontQL(endDate: DateTime(2014, 6, 20), couponBp: 100, spreadBp: 1000, recovery: 0.40);
      const expected = 0.29721895179641017;
      expect(u, isNotNull);
      expect((u! - expected).abs(), lessThan(expected.abs() * 0.02));
    });
    test('10Y / spread 10bp / R=40%', () {
      final u = upfrontQL(endDate: DateTime(2019, 6, 20), couponBp: 100, spreadBp: 10, recovery: 0.40);
      const expected = -0.08134840187700342;
      expect(u, isNotNull);
      expect((u! - expected).abs(), lessThan(expected.abs() * 0.02));
    });
    test('10Y / spread 1000bp / R=40%', () {
      final u = upfrontQL(endDate: DateTime(2019, 6, 20), couponBp: 100, spreadBp: 1000, recovery: 0.40);
      const expected = 0.4025124778292111;
      expect(u, isNotNull);
      expect((u! - expected).abs(), lessThan(expected.abs() * 0.02));
    });
  });

  // ===== ISDA Official RFR Test Grids — 2021-04-26 =====
  // Source: https://www.cdsmodel.com/assets/cds-model/rfr-test-grids/
  // Each currency: 6 maturities × 4 spreads × coupon=100bp × R=40% = 24 cases.

  void runGrid({
    required String label,
    required List<icds.CurveInstrument> instruments,
    required int mmDcc,
    required List<(int matYMD, int spread, double expected)> cases,
    int tradeYMD = 20210426,
    int settleYMD = 20210429,
    int startYMD = 20210427,
  }) {
    DateTime ymd(int v) => DateTime(v ~/ 10000, (v ~/ 100) % 100, v % 100);
    final trade = ymd(tradeYMD);
    final settle = ymd(settleYMD);
    final start = ymd(startYMD);
    var maxErr = 0.0;
    for (final c in cases) {
      final end = ymd(c.$1);
      final spread = c.$2;
      final expected = c.$3;
      final out = icds.priceWithCurve(
        instruments: instruments,
        curveValueDate: start,           // ISDA grid uses start = T+1 biz
        tradeDate: trade,
        settleDate: settle,
        stepinDate: start,               // grid convention: stepin == start
        startDate: start,
        endDate: end,
        mmDcc: mmDcc,
        fixedSwapFreq: 1,                // OIS annual
        floatSwapFreq: 1,
        fixedSwapDcc: mmDcc,
        floatSwapDcc: mmDcc,
        couponBp: 100,
        parSpreadBp: spread.toDouble(),
        recoveryRate: 0.40,
        isPriceClean: true,              // grid is clean upfront
      );
      expect(out, isNotNull,
          reason: '$label mat=${c.$1} spread=${c.$2}bp returned null');
      final err = (out!.upfrontFraction - expected).abs();
      maxErr = err > maxErr ? err : maxErr;
      // 2.5e-5 = 0.25 bp on fraction = $250 on $10M
      expect(err, lessThan(2.5e-5),
          reason: '$label mat=${c.$1} spread=${c.$2}bp got=${out.upfrontFraction} expected=$expected (err=$err)');
    }
    debugPrint('$label ISDA grid max abs error: $maxErr');
  }

  group('ISDA RFR grid — USD (SOFR) 2021-04-26', () {
    test('all 24 cases (USD)', () {
      runGrid(
        label: 'USD',
        instruments: const [
          icds.CurveInstrument('M', '1M', 0.000162),
          icds.CurveInstrument('M', '2M', 0.00025),
          icds.CurveInstrument('M', '3M', 0.00029),
          icds.CurveInstrument('M', '6M', 0.00037),
          icds.CurveInstrument('S', '1Y', 0.000475),
          icds.CurveInstrument('S', '2Y', 0.001101),
          icds.CurveInstrument('S', '3Y', 0.002731),
          icds.CurveInstrument('S', '4Y', 0.004851),
          icds.CurveInstrument('S', '5Y', 0.006832),
          icds.CurveInstrument('S', '6Y', 0.008592),
          icds.CurveInstrument('S', '7Y', 0.010081),
          icds.CurveInstrument('S', '8Y', 0.011242),
          icds.CurveInstrument('S', '9Y', 0.012202),
          icds.CurveInstrument('S', '10Y', 0.013032),
          icds.CurveInstrument('S', '12Y', 0.014311),
          icds.CurveInstrument('S', '15Y', 0.01554),
          icds.CurveInstrument('S', '20Y', 0.016521),
          icds.CurveInstrument('S', '25Y', 0.016871),
          icds.CurveInstrument('S', '30Y', 0.016979),
        ],
        mmDcc: icds.IsdaDcc.act360,
        cases: const [
          (20220620, 50,   -0.00580311532381747),
          (20220620, 100,   0),
          (20220620, 500,   0.04445978768484159),
          (20220620, 1000,  0.09541117712096613),
          (20230620, 50,   -0.010792491678912823),
          (20230620, 100,   0),
          (20230620, 500,   0.07968146812200938),
          (20230620, 1000,  0.16441311787211674),
          (20240620, 50,   -0.01572809135426417),
          (20240620, 100,   0),
          (20240620, 500,   0.11197256965246417),
          (20240620, 1000,  0.22254755669137702),
          (20260620, 50,   -0.02528283662891464),
          (20260620, 100,   0),
          (20260620, 500,   0.16781989168415334),
          (20260620, 1000,  0.3113969783077487),
          (20280620, 50,   -0.03437801070756048),
          (20280620, 100,   0),
          (20280620, 500,   0.21349920402493525),
          (20280620, 1000,  0.37279122279513943),
          (20310620, 50,   -0.047067934014831246),
          (20310620, 100,   0),
          (20310620, 500,   0.26633077987260967),
          (20310620, 1000,  0.4305881029133455),
        ],
      );
    });
  });

  group('ISDA RFR grid — EUR (€STR) 2021-04-26', () {
    test('all 24 cases (EUR)', () {
      runGrid(
        label: 'EUR',
        instruments: const [
          icds.CurveInstrument('M', '1M',  -0.005683),
          icds.CurveInstrument('M', '3M',  -0.005699),
          icds.CurveInstrument('M', '6M',  -0.005727),
          icds.CurveInstrument('S', '1Y',  -0.00576),
          icds.CurveInstrument('S', '2Y',  -0.00572),
          icds.CurveInstrument('S', '3Y',  -0.005399),
          icds.CurveInstrument('S', '4Y',  -0.00489),
          icds.CurveInstrument('S', '5Y',  -0.00429),
          icds.CurveInstrument('S', '6Y',  -0.00361),
          icds.CurveInstrument('S', '7Y',  -0.00289),
          icds.CurveInstrument('S', '8Y',  -0.00217),
          icds.CurveInstrument('S', '9Y',  -0.00145),
          icds.CurveInstrument('S', '10Y', -0.00078),
          icds.CurveInstrument('S', '12Y', 0.000431),
          icds.CurveInstrument('S', '15Y', 0.00189),
          icds.CurveInstrument('S', '20Y', 0.00313),
          icds.CurveInstrument('S', '30Y', 0.00336),
        ],
        mmDcc: icds.IsdaDcc.act360,
        cases: const [
          (20220620, 50,  -0.005828869084044723), (20220620, 100, 0),
          (20220620, 500,  0.04465291502328026),  (20220620, 1000, 0.09581581874755055),
          (20230620, 50,  -0.010879720766301603), (20230620, 100, 0),
          (20230620, 500,  0.08030225637766902),  (20230620, 1000, 0.16564206833950615),
          (20240620, 50,  -0.015927127251145232), (20240620, 100, 0),
          (20240620, 500,  0.11331393795739231),  (20240620, 1000, 0.22505259798761107),
          (20260620, 50,  -0.025916163143131613), (20260620, 100, 0),
          (20260620, 500,  0.17164476829276837),  (20260620, 1000, 0.3177605123478776),
          (20280620, 50,  -0.03576348104678665),  (20280620, 100, 0),
          (20280620, 500,  0.22103592524599175),  (20280620, 1000, 0.3840517379551901),
          (20310620, 50,  -0.05009916318646137),  (20310620, 100, 0),
          (20310620, 500,  0.2805934004473929),   (20310620, 1000, 0.44906368128990115),
        ],
      );
    });
  });

  group('ISDA RFR grid — GBP (SONIA) 2021-04-26', () {
    test('all 24 cases (GBP)', () {
      runGrid(
        label: 'GBP',
        instruments: const [
          icds.CurveInstrument('M', '1M', 0.000494),
          icds.CurveInstrument('M', '2M', 0.000494),
          icds.CurveInstrument('M', '3M', 0.000494),
          icds.CurveInstrument('M', '6M', 0.000496),
          icds.CurveInstrument('S', '1Y', 0.000541),
          icds.CurveInstrument('S', '2Y', 0.001096),
          icds.CurveInstrument('S', '3Y', 0.002129),
          icds.CurveInstrument('S', '4Y', 0.003182),
          icds.CurveInstrument('S', '5Y', 0.004173),
          icds.CurveInstrument('S', '6Y', 0.004981),
          icds.CurveInstrument('S', '7Y', 0.005687),
          icds.CurveInstrument('S', '8Y', 0.006298),
          icds.CurveInstrument('S', '9Y', 0.00684),
          icds.CurveInstrument('S', '10Y', 0.007314),
          icds.CurveInstrument('S', '12Y', 0.008028),
          icds.CurveInstrument('S', '15Y', 0.008676),
          icds.CurveInstrument('S', '20Y', 0.009064),
          icds.CurveInstrument('S', '25Y', 0.009052),
          icds.CurveInstrument('S', '30Y', 0.008867),
        ],
        mmDcc: icds.IsdaDcc.act365F,
        cases: const [
          (20220620, 50,  -0.005802786650191053), (20220620, 100, 0),
          (20220620, 500,  0.04445727800280181),  (20220620, 1000, 0.09540581383750613),
          (20230620, 50,  -0.010792530296581344), (20230620, 100, 0),
          (20230620, 500,  0.07968130736252438),  (20230620, 1000, 0.16441187156226264),
          (20240620, 50,  -0.01573591623494096),  (20240620, 100, 0),
          (20240620, 500,  0.11202158887001404),  (20240620, 1000, 0.2226316013816559),
          (20260620, 50,  -0.02537775128925755),  (20260620, 100, 0),
          (20260620, 500,  0.1683596577611453),   (20260620, 1000, 0.31223200836978926),
          (20280620, 50,  -0.03470534060004428),  (20280620, 100, 0),
          (20280620, 500,  0.21517844496234534),  (20280620, 1000, 0.37512084718297156),
          (20310620, 50,  -0.04802657035310333),  (20310620, 100, 0),
          (20310620, 500,  0.2705780809456329),   (20310620, 1000, 0.4356627871781185),
        ],
      );
    });
  });

  group('ISDA RFR grid — JPY (TONA) 2021-04-26', () {
    test('all 24 cases (JPY)', () {
      runGrid(
        label: 'JPY',
        instruments: const [
          icds.CurveInstrument('M', '1M',  -0.000188),
          icds.CurveInstrument('M', '2M',  -0.0002),
          icds.CurveInstrument('M', '3M',  -0.000225),
          icds.CurveInstrument('M', '6M',  -0.000263),
          icds.CurveInstrument('S', '1Y',  -0.000388),
          icds.CurveInstrument('S', '2Y',  -0.000581),
          icds.CurveInstrument('S', '3Y',  -0.000638),
          icds.CurveInstrument('S', '4Y',  -0.0006),
          icds.CurveInstrument('S', '5Y',  -0.000488),
          icds.CurveInstrument('S', '6Y',  -0.00035),
          icds.CurveInstrument('S', '7Y',  -0.000163),
          icds.CurveInstrument('S', '8Y',   6.3e-5),
          icds.CurveInstrument('S', '9Y',   0.0003),
          icds.CurveInstrument('S', '10Y',  0.000576),
          icds.CurveInstrument('S', '12Y',  0.001138),
          icds.CurveInstrument('S', '15Y',  0.002001),
          icds.CurveInstrument('S', '20Y',  0.003188),
          icds.CurveInstrument('S', '30Y',  0.004563),
        ],
        mmDcc: icds.IsdaDcc.act365F,
        cases: const [
          (20220620, 50,  -0.005806607412302076), (20220620, 100, 0),
          (20220620, 500,  0.04448578757568605),  (20220620, 1000, 0.09546522343321537),
          (20230620, 50,  -0.01081083070027822),  (20230620, 100, 0),
          (20230620, 500,  0.07981004815156448),  (20230620, 1000, 0.16466346930485906),
          (20240620, 50,  -0.015790211908411504), (20240620, 100, 0),
          (20240620, 500,  0.1123814141218523),   (20240620, 1000, 0.22329083786224066),
          (20260620, 50,  -0.025602666268945022), (20260620, 100, 0),
          (20260620, 500,  0.1696918875153744),   (20260620, 1000, 0.3143970417543413),
          (20280620, 50,  -0.03525806552377223),  (20280620, 100, 0),
          (20280620, 500,  0.21812549715797183),  (20280620, 1000, 0.3794131919867492),
          (20310620, 50,  -0.04935953781136934),  (20310620, 100, 0),
          (20310620, 500,  0.2767055441443155),   (20310620, 1000, 0.4433594737836914),
        ],
      );
    });
  });

  group('ISDA RFR grid — CHF (SARON) 2021-04-26', () {
    test('all 24 cases (CHF)', () {
      runGrid(
        label: 'CHF',
        instruments: const [
          icds.CurveInstrument('M', '1M', -0.007251),
          icds.CurveInstrument('M', '2M', -0.0073),
          icds.CurveInstrument('M', '3M', -0.007301),
          icds.CurveInstrument('M', '6M', -0.007301),
          icds.CurveInstrument('S', '1Y', -0.007275),
          icds.CurveInstrument('S', '2Y', -0.007),
          icds.CurveInstrument('S', '3Y', -0.006375),
          icds.CurveInstrument('S', '4Y', -0.005626),
          icds.CurveInstrument('S', '5Y', -0.004752),
          icds.CurveInstrument('S', '6Y', -0.003851),
          icds.CurveInstrument('S', '7Y', -0.002952),
          icds.CurveInstrument('S', '8Y', -0.002101),
          icds.CurveInstrument('S', '9Y', -0.001326),
          icds.CurveInstrument('S', '10Y',-0.000651),
          icds.CurveInstrument('S', '12Y', 0.000424),
          icds.CurveInstrument('S', '15Y', 0.001599),
          icds.CurveInstrument('S', '20Y', 0.00245),
          icds.CurveInstrument('S', '25Y', 0.002474),
          icds.CurveInstrument('S', '30Y', 0.002023),
        ],
        mmDcc: icds.IsdaDcc.act360,
        cases: const [
          (20220620, 50,  -0.005835163013795173), (20220620, 100, 0),
          (20220620, 500,  0.04470020034790409),  (20220620, 1000, 0.09591509023241024),
          (20230620, 50,  -0.010897846347513562), (20230620, 100, 0),
          (20230620, 500,  0.08043216858365183),  (20230620, 1000, 0.16590124290549765),
          (20240620, 50,  -0.015959872257825695), (20240620, 100, 0),
          (20240620, 500,  0.11353878030447746),  (20240620, 1000, 0.22548114957382537),
          (20260620, 50,  -0.025976435978151823), (20260620, 100, 0),
          (20260620, 500,  0.17203058204459107),  (20260620, 1000, 0.31844464310924586),
          (20280620, 50,  -0.035835698384644725), (20280620, 100, 0),
          (20280620, 500,  0.22148362587808354),  (20280620, 1000, 0.3848207465208361),
          (20310620, 50,  -0.050159547010044686), (20310620, 100, 0),
          (20310620, 500,  0.28099435841484155),  (20310620, 1000, 0.44978315207516567),
        ],
      );
    });
  });

  // ===== USD post-IMM-roll grids =====
  // Friday-trade and post-IMM-roll cases exercise weekend / holiday
  // settle math. 2022-06-20 was the first Juneteenth-observed IMM —
  // makes the just-past-IMM accrual a nontrivial calendar interaction.

  group('ISDA RFR grid — USD post-IMM 2022-06-21', () {
    test('all 24 cases (USD post-IMM Tue 2022-06-21)', () {
      runGrid(
        label: 'USD post-IMM 2022-06-21',
        instruments: const [
          icds.CurveInstrument('M', '1M', 0.014901),
          icds.CurveInstrument('M', '2M', 0.018366),
          icds.CurveInstrument('M', '3M', 0.020059),
          icds.CurveInstrument('M', '6M', 0.026083),
          icds.CurveInstrument('S', '1Y', 0.031705),
          icds.CurveInstrument('S', '2Y', 0.033876),
          icds.CurveInstrument('S', '3Y', 0.033071),
          icds.CurveInstrument('S', '4Y', 0.031688),
          icds.CurveInstrument('S', '5Y', 0.03104),
          icds.CurveInstrument('S', '6Y', 0.030563),
          icds.CurveInstrument('S', '7Y', 0.030342),
          icds.CurveInstrument('S', '8Y', 0.030103),
          icds.CurveInstrument('S', '9Y', 0.029994),
          icds.CurveInstrument('S', '10Y', 0.029936),
          icds.CurveInstrument('S', '12Y', 0.029794),
          icds.CurveInstrument('S', '15Y', 0.029495),
          icds.CurveInstrument('S', '20Y', 0.029173),
          icds.CurveInstrument('S', '25Y', 0.028195),
          icds.CurveInstrument('S', '30Y', 0.026938),
        ],
        mmDcc: icds.IsdaDcc.act360,
        cases: const [
          (20230620, 50,  -0.004945712941701251), (20230620, 100, 0),
          (20230620, 500,  0.0381232238180752),   (20230620, 1000, 0.08235455892656911),
          (20240620, 50,  -0.00970223152894764),  (20240620, 100, 0),
          (20240620, 500,  0.07211521889577951),  (20240620, 1000, 0.14986040653755403),
          (20250620, 50,  -0.014252584825337918), (20250620, 100, 0),
          (20250620, 500,  0.1022568430000579),   (20250620, 1000, 0.20487699188380248),
          (20270620, 50,  -0.02286421628370117),  (20270620, 100, 0),
          (20270620, 500,  0.15324022348985966),  (20270620, 1000, 0.28715414044556326),
          (20290620, 50,  -0.03087960341979619),  (20290620, 100, 0),
          (20290620, 500,  0.1940177675218703),   (20290620, 1000, 0.3427574895331384),
          (20320620, 50,  -0.0418362405249989),   (20320620, 100, 0),
          (20320620, 500,  0.24024104926320544),  (20320620, 1000, 0.3940894209912326),
        ],
        tradeYMD: 20220621, settleYMD: 20220624, startYMD: 20220622,
      );
    });
  });

  group('ISDA RFR grid — USD post-IMM 2022-06-22', () {
    test('all 24 cases (USD post-IMM Wed 2022-06-22)', () {
      runGrid(
        label: 'USD post-IMM 2022-06-22',
        instruments: const [
          icds.CurveInstrument('M', '1M', 0.015088),
          icds.CurveInstrument('M', '2M', 0.018228),
          icds.CurveInstrument('M', '3M', 0.019729),
          icds.CurveInstrument('M', '6M', 0.02564),
          icds.CurveInstrument('S', '1Y', 0.03162),
          icds.CurveInstrument('S', '2Y', 0.033169),
          icds.CurveInstrument('S', '3Y', 0.032441),
          icds.CurveInstrument('S', '4Y', 0.031771),
          icds.CurveInstrument('S', '5Y', 0.031371),
          icds.CurveInstrument('S', '6Y', 0.031131),
          icds.CurveInstrument('S', '7Y', 0.030951),
          icds.CurveInstrument('S', '8Y', 0.030841),
          icds.CurveInstrument('S', '9Y', 0.030811),
          icds.CurveInstrument('S', '10Y', 0.030871),
          icds.CurveInstrument('S', '12Y', 0.031061),
          icds.CurveInstrument('S', '15Y', 0.031201),
          icds.CurveInstrument('S', '20Y', 0.030601),
          icds.CurveInstrument('S', '25Y', 0.029381),
          icds.CurveInstrument('S', '30Y', 0.028221),
        ],
        mmDcc: icds.IsdaDcc.act360,
        cases: const [
          (20230620, 50,  -0.004933625639328898), (20230620, 100, 0),
          (20230620, 500,  0.03803386161143216),  (20230620, 1000, 0.082170407769361),
          (20240620, 50,  -0.009695399988908214), (20240620, 100, 0),
          (20240620, 500,  0.07206976317551916),  (20240620, 1000, 0.14977751178369045),
          (20250620, 50,  -0.014254337199320422), (20250620, 100, 0),
          (20250620, 500,  0.10227403555367061),  (20250620, 1000, 0.20492021749635403),
          (20270620, 50,  -0.022864040900635565), (20270620, 100, 0),
          (20270620, 500,  0.15326048291412903),  (20270620, 1000, 0.28722771265424396),
          (20290620, 50,  -0.030852493871798514), (20290620, 100, 0),
          (20290620, 500,  0.19391264180948287),  (20290620, 1000, 0.3426769977652599),
          (20320620, 50,  -0.04173237489810769),  (20320620, 100, 0),
          (20320620, 500,  0.2398302820143435),   (20320620, 1000, 0.39369024400057534),
        ],
        tradeYMD: 20220622, settleYMD: 20220627, startYMD: 20220623,
      );
    });
  });

  group('ISDA RFR grid — AUD (AONIA) 2021-04-26', () {
    test('all 24 cases (AUD)', () {
      runGrid(
        label: 'AUD',
        instruments: const [
          icds.CurveInstrument('M', '1M', 0.000315),
          icds.CurveInstrument('M', '2M', 0.000305),
          icds.CurveInstrument('M', '3M', 0.000315),
          icds.CurveInstrument('M', '6M', 0.00035),
          icds.CurveInstrument('S', '1Y', 0.000495),
          icds.CurveInstrument('S', '2Y', 0.001121),
          icds.CurveInstrument('S', '3Y', 0.002559),
          icds.CurveInstrument('S', '4Y', 0.004592),
          icds.CurveInstrument('S', '5Y', 0.006868),
          icds.CurveInstrument('S', '6Y', 0.008915),
          icds.CurveInstrument('S', '7Y', 0.010933),
          icds.CurveInstrument('S', '8Y', 0.012285),
          icds.CurveInstrument('S', '9Y', 0.013666),
          icds.CurveInstrument('S', '10Y', 0.015018),
          icds.CurveInstrument('S', '12Y', 0.016713),
          icds.CurveInstrument('S', '15Y', 0.01828),
          icds.CurveInstrument('S', '20Y', 0.019156),
          icds.CurveInstrument('S', '25Y', 0.019176),
          icds.CurveInstrument('S', '30Y', 0.018727),
        ],
        mmDcc: icds.IsdaDcc.act365F,
        cases: const [
          (20220620, 50,  -0.005803085332165238), (20220620, 100, 0),
          (20220620, 500,  0.044459566270599354), (20220620, 1000, 0.09541072076753586),
          (20230620, 50,  -0.010792497651730517), (20230620, 100, 0),
          (20230620, 500,  0.07968143366141262),  (20230620, 1000, 0.16441289564493572),
          (20240620, 50,  -0.015730459506110878), (20240620, 100, 0),
          (20240620, 500,  0.11198752249585645),  (20240620, 1000, 0.22257344379920818),
          (20260620, 50,  -0.025292760141841338), (20260620, 100, 0),
          (20260620, 500,  0.16788006293915622),  (20260620, 1000, 0.3114963476881907),
          (20280620, 50,  -0.03436423278070999),  (20280620, 100, 0),
          (20280620, 500,  0.21344772305326293),  (20280620, 1000, 0.3727500801124175),
          (20310620, 50,  -0.04690607864563512),  (20310620, 100, 0),
          (20310620, 500,  0.2656889795786492),   (20310620, 1000, 0.4299281235222944),
        ],
      );
    });
  });
}
