---
title: iCDS × Claude Code — by the numbers
---

# iCDS × Claude Code — by the numbers

**Bottom line:** ~12.8k lines of shipped, test-backed code across three platforms — iPhone/iPad/Mac native + Android/Flutter — delivered with ~17 hours of hands-on steering and a shared ~$200 subscription. Because the most expensive part of a long, context-heavy coding workload is *re-reading prior context*, and that's exactly what a flat-rate plan compounds.

## Cost — the headline

- Subscriptions are flat-rate, not metered. This workload on the pay-as-you-go API at Opus rates would be **≈ $7,660** — **~$5,660 of it cache reads** (full context re-read every turn), $1,180 cache creation, $820 output, ~negligible uncached input.
- Actual spend: same shared **~$200 subscription** (Pro $20 → Max $100) that already covered the other apps → **~38× more compute on iCDS alone** than the cash cost.
- The $20 → $100 Max upgrade was correct here too; the cache-read volume on a 151 MB transcript would have rate-limited Pro repeatedly.

## Effort actually spent (~7 weeks)

- **~17 hours genuine hands-on on iCDS** (raw measure ~34.5h, reduced 50% to account for parallel work on multiple apps in the same window)
- 75 distinct working sessions (20-min idle gap = session boundary)
- 10.9 million output tokens across ~14,300 assistant turns and ~9,400 user turns

## Code shipped (Claude-assisted)

- ~12,800 lines of authored code across 3 platforms (iOS SwiftUI/UIKit-bridge, Mac Catalyst, Flutter/Android)
  - Swift ~4,800 · Dart ~6,000 · docs/config ~2,000
- Split ~6,800 app source / ~4,000 tests — ≈ 1 : 0.58 ratio. ISDA reference grids and bit-identical Swift↔Dart parity tests do a lot of the verification work outside the unit count.
- Excludes 54,475 lines of ISDA C library compiled in as a dependency (vendored, not Claude-authored).

## Scope, kept honest

- **Code volume** = the full Claude-assisted history (Swift app, Flutter/Dart port, tests, docs/config — excluding the bundled ISDA C library, which is third-party and ~54.5k LOC on its own).
- **Time & cost** = the local transcript captures, 2026-04-26 → 2026-06-14, ≈ 7 weeks. Earlier exploratory work predates the logs.
