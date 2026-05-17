# LinkedIn Post — iCDS 3.2.0 launch

Plain-text post below, ready to copy-paste into LinkedIn. Don't include this header line when copying — start at "In 2009...".

---

In 2009, I spent 134 hours and $2,427 building my first iPhone app — a Credit Default Swap calculator (iCDS) using the official ISDA Standard Model. It's been quietly sitting in the App Store ever since.

A few weeks ago I rebuilt it. Today I shipped 3.2.0 — and it now runs on Android too.

What changed in 3.2.0:
• Cross-platform: Flutter / Dart-FFI port of the same ISDA C engine, bit-identical numerics on iOS and Android (263 tests passing across both)
• v12 layout: 7 SNAC tenors (1Y–10Y) in a unified segmented pill, default-risk-by-maturity chart, first-order risk row (CS01 / IR DV01 / Rec01)
• Diag tab: in-app deterministic self-tests so you can verify the C library, IMM helpers, regional holiday calendars, and live RFR fetcher on any device
• Modernized SNAC conventions: EM moved to T+1 settlement; subordinated recoveries lowered (EM 25→15, Japan 35→15) so SUB is always strictly lower than SEN
• DIRTY UPFRONT card: total cash to settle (upfront + accrued), labeled in trader-floor vocabulary

Total time: a few weekends across iOS + Android + 263 cross-platform regression tests.
iOS or Android code I wrote myself: zero.

I drove the entire build with Claude Code — describing what I wanted, reviewing diffs, making tradeoff decisions. The 2009 codebase was UIKit/Storyboard; today's is SwiftUI + Flutter + Dart FFI binding the same C library on both platforms.

What surprised me again: the bottleneck wasn't generating code. It was knowing what to ask for — which conventions are ISDA-mandated vs. market-soft, where the bounds matter (10,000 bp spread cap), how to label a cell so it reads naturally to a trader. Domain judgment is what compounds.

If you've been holding off on revisiting an old project because you don't have time or the relevant stack experience anymore — that calculus is different now.

iCDS 3.2.0 — Android on Google Play (Internal testing), iOS update prepared. Source: github.com/jimzucker/iCDS

#AI #ClaudeCode #iOS #Android #Flutter #BuilderMode
