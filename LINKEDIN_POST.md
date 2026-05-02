# LinkedIn Post — iCDS 3.0.1 launch

Plain-text post below, ready to copy-paste into LinkedIn. Don't include this header line when copying — start at "In 2009...".

---

In 2009, I spent 134 hours and $2,427 building my first iPhone app — a Credit Default Swap calculator (iCDS) using the official ISDA Standard Model. It's been quietly sitting in the App Store ever since.

This weekend I rebuilt it.

What changed:
• Full SwiftUI rewrite (was UIKit/Storyboard)
• iOS 16+ support; runs cleanly on iPhone 17 Pro Max and iPad Pro
• Live overnight curves from five central banks (SOFR, €STR, SONIA, TONA, AONIA)
• Six regional ISDA contracts; spread cap raised to 10,000 bp for distressed credits
• Apache 2.0 source license

Total time: a few hours.
iOS code I wrote myself: zero.

I drove the entire upgrade with Claude Code — describing what I wanted, reviewing diffs, making tradeoff decisions. Last time I touched this codebase, Swift didn't exist yet.

What surprised me: the bottleneck wasn't generating code. It was knowing what to ask for, which tradeoffs matter (App Store submission rules, disclaimer language, financial-app legal posture, even screenshot pixel dimensions), and recognizing when output looked off.

The skill that compounded was domain judgment, not syntax.

If you've been holding off on revisiting an old project because you don't have time or the relevant stack experience anymore — that calculus is different now.

iCDS 3.0.1 is live on the App Store. Source: github.com/jimzucker/iCDS

#AI #ClaudeCode #iOS #SwiftUI #BuilderMode
