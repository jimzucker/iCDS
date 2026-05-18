#!/usr/bin/env python3
"""
Regenerate the Play Store feature graphics from a Calc-tab screenshot.

Used by `flutter/example/store_screenshots/refresh.sh` so that whenever
Android screenshots are refreshed, the Play Store assets pick up the
current UI automatically (7-tenor row, DIRTY UPFRONT card, etc.).

Outputs:
  images/feature_graphic_source.png   — the cropped Maturity-through-cards
                                        strip, ready to drop into any
                                        composition tool.
  images/play_feature_graphic.png     — 1024×500 Play Store feature graphic,
                                        composed black background + iCDS
                                        wordmark + tagline + cards crop.

Usage:
  python3 images/regenerate_feature_graphic.py \\
      flutter/example/store_screenshots/01_calc_par.png \\
      images/feature_graphic_source.png \\
      images/play_feature_graphic.png
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def find_font(preferred: list[tuple[str, int]]) -> ImageFont.ImageFont:
    """Return the first font that loads. Falls back to PIL's default."""
    for path, size in preferred:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                pass
    return ImageFont.load_default()


def crop_cards_strip(img: Image.Image) -> Image.Image:
    """
    Build a compact composite of (a) the Maturity 7-tenor row and (b) the
    QUOTED SPREAD + DIRTY UPFRONT cards, stacked with a small gap. Skips
    the Buy/Sell, Recovery, Coupon, and Notional rows in between — those
    aren't the headline-grabbing features for a Play Store hero graphic.

    Uses relative fractions so it works on both Pixel 720×1600 and iPhone
    14 Plus 1284×2778 screenshots.
    """
    w, h = img.size
    left = int(w * 0.022)
    right = w - left

    # Maturity row (label + 7 tenor buttons)
    mat_top = int(h * 0.178)
    mat_bot = int(h * 0.250)
    maturity = img.crop((left, mat_top, right, mat_bot))

    # Spread / Dirty Upfront cards row
    cards_top = int(h * 0.315)
    cards_bot = int(h * 0.392)
    cards = img.crop((left, cards_top, right, cards_bot))

    # Stack vertically with a small gap on a black background.
    gap = 16
    cw = maturity.width
    ch = maturity.height + gap + cards.height
    combined = Image.new("RGB", (cw, ch), (0, 0, 0))
    combined.paste(maturity, (0, 0))
    combined.paste(cards, (0, maturity.height + gap))
    return combined


def compose_play_graphic(cards: Image.Image, out_path: Path) -> None:
    """
    Compose the 1024×500 Play Store feature graphic: black background, iCDS
    wordmark in orange, "ISDA SNAC Pricing Calculator" tagline in grey, and
    the resized cards crop pasted along the bottom.
    """
    W, H = 1024, 500
    canvas = Image.new("RGB", (W, H), color=(0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    orange = (255, 128, 0)
    grey = (200, 200, 200)

    title_font = find_font([
        ("/System/Library/Fonts/Supplemental/Arial Black.ttf", 100),
        ("/System/Library/Fonts/Helvetica.ttc", 100),
        ("/System/Library/Fonts/HelveticaNeue.ttc", 100),
    ])
    sub_font = find_font([
        ("/System/Library/Fonts/Helvetica.ttc", 26),
        ("/System/Library/Fonts/HelveticaNeue.ttc", 26),
    ])

    # Title — pulled up so the composite below has room.
    title = "iCDS"
    tw = draw.textlength(title, font=title_font)
    draw.text(((W - tw) / 2, 12), title, fill=orange, font=title_font)

    # Tagline directly under the title.
    sub = "ISDA SNAC Pricing Calculator"
    sw = draw.textlength(sub, font=sub_font)
    draw.text(((W - sw) / 2, 128), sub, fill=grey, font=sub_font)

    # Cards composite spans the bottom half. Reserve ~170pt for title + tagline.
    reserved_top = 170
    available_h = H - reserved_top
    cw, ch = cards.size
    scale = W / cw
    target_w = W
    target_h = int(ch * scale)
    if target_h > available_h:
        # Scale by height instead and center horizontally.
        scale = available_h / ch
        target_h = available_h
        target_w = int(cw * scale)
    resized = cards.resize((target_w, target_h), Image.LANCZOS)

    x = (W - target_w) // 2
    y = H - target_h
    canvas.paste(resized, (x, y))
    canvas.save(out_path)


def main() -> int:
    if len(sys.argv) != 4:
        print(__doc__, file=sys.stderr)
        return 2
    input_path, src_out, play_out = (Path(a) for a in sys.argv[1:])
    if not input_path.exists():
        print(f"error: input screenshot not found: {input_path}", file=sys.stderr)
        return 1

    img = Image.open(input_path).convert("RGB")
    cards = crop_cards_strip(img)
    cards.save(src_out)
    print(f"  src: {src_out} ({cards.size[0]}×{cards.size[1]})")

    compose_play_graphic(cards, play_out)
    print(f"  play: {play_out} (1024×500)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
