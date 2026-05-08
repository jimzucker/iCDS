/// ISDA RFR test grid · 2021-04-26 snapshot — the per-currency reference
/// swap curves displayed by the Curves tab. Direct port of the static
/// arrays in `iCDS/icds/LiborView.swift`.

import 'sofr_fetcher.dart';

class CurvePoint {
  final String tenor;
  final double rate;
  const CurvePoint(this.tenor, this.rate);
}

class ReferenceCurves {
  static const _usd = <CurvePoint>[
    CurvePoint('1M', 0.000162),  CurvePoint('2M', 0.00025),
    CurvePoint('3M', 0.00029),   CurvePoint('6M', 0.00037),
    CurvePoint('1Y', 0.000475),  CurvePoint('2Y', 0.001101),
    CurvePoint('3Y', 0.002731),  CurvePoint('4Y', 0.004851),
    CurvePoint('5Y', 0.006832),  CurvePoint('6Y', 0.008592),
    CurvePoint('7Y', 0.010081),  CurvePoint('8Y', 0.011242),
    CurvePoint('9Y', 0.012202),  CurvePoint('10Y', 0.013032),
    CurvePoint('12Y', 0.014311), CurvePoint('15Y', 0.01554),
    CurvePoint('20Y', 0.016521), CurvePoint('25Y', 0.016871),
    CurvePoint('30Y', 0.016979),
  ];

  static const _eur = <CurvePoint>[
    CurvePoint('1M', -0.005683),  CurvePoint('3M', -0.005699),
    CurvePoint('6M', -0.005727),  CurvePoint('1Y', -0.00576),
    CurvePoint('2Y', -0.00572),   CurvePoint('3Y', -0.005399),
    CurvePoint('4Y', -0.00489),   CurvePoint('5Y', -0.00429),
    CurvePoint('6Y', -0.00361),   CurvePoint('7Y', -0.00289),
    CurvePoint('8Y', -0.00217),   CurvePoint('9Y', -0.00145),
    CurvePoint('10Y', -0.00078),  CurvePoint('12Y', 0.000431),
    CurvePoint('15Y', 0.00189),   CurvePoint('20Y', 0.00313),
    CurvePoint('30Y', 0.00336),
  ];

  static const _gbp = <CurvePoint>[
    CurvePoint('1M', 0.000494),  CurvePoint('2M', 0.000494),
    CurvePoint('3M', 0.000494),  CurvePoint('6M', 0.000496),
    CurvePoint('1Y', 0.000541),  CurvePoint('2Y', 0.001096),
    CurvePoint('3Y', 0.002129),  CurvePoint('4Y', 0.003182),
    CurvePoint('5Y', 0.004173),  CurvePoint('6Y', 0.004981),
    CurvePoint('7Y', 0.005687),  CurvePoint('8Y', 0.006298),
    CurvePoint('9Y', 0.00684),   CurvePoint('10Y', 0.007314),
    CurvePoint('12Y', 0.008028), CurvePoint('15Y', 0.008676),
    CurvePoint('20Y', 0.009064), CurvePoint('25Y', 0.009052),
    CurvePoint('30Y', 0.008867),
  ];

  static const _jpy = <CurvePoint>[
    CurvePoint('1M', -0.000188),  CurvePoint('2M', -0.0002),
    CurvePoint('3M', -0.000225),  CurvePoint('6M', -0.000263),
    CurvePoint('1Y', -0.000388),  CurvePoint('2Y', -0.000581),
    CurvePoint('3Y', -0.000638),  CurvePoint('4Y', -0.0006),
    CurvePoint('5Y', -0.000488),  CurvePoint('6Y', -0.00035),
    CurvePoint('7Y', -0.000163),  CurvePoint('8Y', 6.3e-5),
    CurvePoint('9Y', 0.0003),     CurvePoint('10Y', 0.000576),
    CurvePoint('12Y', 0.001138),  CurvePoint('15Y', 0.002001),
    CurvePoint('20Y', 0.003188),  CurvePoint('30Y', 0.004563),
  ];

  static const _aud = <CurvePoint>[
    CurvePoint('1M', 0.000315),   CurvePoint('2M', 0.000305),
    CurvePoint('3M', 0.000315),   CurvePoint('6M', 0.00035),
    CurvePoint('1Y', 0.000495),   CurvePoint('2Y', 0.001121),
    CurvePoint('3Y', 0.002559),   CurvePoint('4Y', 0.004592),
    CurvePoint('5Y', 0.006868),   CurvePoint('6Y', 0.008915),
    CurvePoint('7Y', 0.010933),   CurvePoint('8Y', 0.012285),
    CurvePoint('9Y', 0.013666),   CurvePoint('10Y', 0.015018),
    CurvePoint('12Y', 0.016713),  CurvePoint('15Y', 0.01828),
    CurvePoint('20Y', 0.019156),  CurvePoint('25Y', 0.019176),
    CurvePoint('30Y', 0.018727),
  ];

  static List<CurvePoint> forCurrency(RFRCurrency ccy) {
    switch (ccy) {
      case RFRCurrency.usd: return _usd;
      case RFRCurrency.eur: return _eur;
      case RFRCurrency.gbp: return _gbp;
      case RFRCurrency.jpy: return _jpy;
      case RFRCurrency.aud: return _aud;
    }
  }
}
