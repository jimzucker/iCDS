# App Store Submission — iCDS 3.2.1

Each section below is the field's content as plain text, ready to copy-paste into App Store Connect.

---

## Promotional Text (170 char max)

The ISDA Standard CDS Model in your pocket — live SOFR / €STR / SONIA / TONA / AONIA curves across six regions. Free, open source, no tracking.

---

## Description

iCDS is a free Credit Default Swap upfront fee calculator built on the official ISDA CDS Standard Model — the same pricing engine used across institutional fixed-income desks.

Enter a quoted spread, coupon, recovery, notional, and tenor. iCDS computes the SNAC (Standard North American CDS) upfront charge live as you change inputs, with intermediate results alongside.

WHAT'S INSIDE
• ISDA CDS Standard Model (v1.8.3) compiled directly into the app
• Live overnight reference-rate curves from five central banks:
  – USD SOFR (Federal Reserve Bank of New York)
  – EUR €STR (European Central Bank)
  – GBP SONIA (Bank of England)
  – JPY TONA proxy (FRED / St. Louis Fed)
  – AUD AONIA (Reserve Bank of Australia)
• Six regional contracts: NA, EM, EU, Asia, Japan, AUS — modernized post-Big-Bang ISDA conventions (T+1 settlement everywhere; recovery rates per region)
• Seven SNAC tenors: 1Y / 2Y / 3Y / 4Y / 5Y / 7Y / 10Y
• Spread input via preset chips and a numeric keypad; cap raised to 10,000 bp for distressed credits
• Default-risk-by-maturity chart: cumulative default probability implied by the quoted spread, at each tenor
• First-order risk metrics: CS01, IR DV01, Rec01 (bump-and-reprice)
• ISDA RFR test-grid validation across six currencies
• Four tabs: Calc, Curves, Info, Diag (in-app deterministic self-tests)

WHO IT'S FOR
Quantitative finance students, fixed-income professionals, and developers exploring CDS pricing. Source is open under Apache 2.0.

NOT FOR
Booking, settlement, trading, or any decision with real money behind it. iCDS produces indicative pricing only — not financial, investment, or trading advice. Rates may be delayed; calculations use a flat overnight-rate discount curve, a standard simplification.

PRIVACY
No data collection. No tracking. No accounts. Reference rates are fetched live from public central-bank endpoints.

LICENSE
Source code: Apache 2.0. Pricing engine: ISDA CDS Standard Model Public License (© 2009 JPMorgan Chase Bank, N.A., developed with Markit). Not affiliated with, endorsed by, or sponsored by ISDA, Markit, JPMorgan Chase, or any rate provider.

---

## What's New in This Version (3.2.x)

• 7 SNAC tenors selectable from one segmented row (1Y / 2Y / 3Y / 4Y / 5Y / 7Y / 10Y)
• Default-risk-by-maturity chart — cumulative default probability implied by the quoted spread at each tenor; tap a bar to switch maturity
• First-order risk row — CS01, IR DV01, Rec01 via bump-and-reprice
• DIRTY UPFRONT card showing total cash to settle (upfront fee + accrued) in trader-floor vocabulary
• In-app Diagnostics tab — deterministic self-tests for the C engine, IMM helpers, regional holiday calendars, and the live rate fetchers
• Modernized SNAC conventions: EM moves to T+1 settlement; subordinated recoveries lowered (EM 25→15%, Japan 35→15%); Japan adds a 500 bp coupon
• Curves tab — CACHED status indicator for rates from persisted cache (distinct from freshly fetched LIVE values); refresh icon and offline retry banner
• Reliable JPY (TONA) fetching — retry strategy hardened so the monthly Japan rate consistently breaks through FRED's slow paths

---

## Keywords (100 char max, comma-separated)

CDS,ISDA,SNAC,SOFR,ESTR,SONIA,upfront fee,bond pricing,fixed income,quant,finance,spread

Note: do not repeat words already in the app title ("Credit", "Default", "Swap", "Calculator") — Apple already indexes those.

---

## Support URL

https://github.com/jimzucker/iCDS/issues

---

## Marketing URL (optional)

https://jimzucker.github.io/iCDS/

---

## Privacy Policy URL (required)

https://jimzucker.github.io/iCDS/PRIVACY.html
