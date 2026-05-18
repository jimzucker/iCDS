#!/usr/bin/env bash
#
# refresh.sh — re-capture the 6 Play Store screenshots from a connected
# Android device and regenerate the Play Store feature graphics from the
# new 01_calc_par.png. Single command for the whole Android-side
# screenshot workflow.
#
# Prerequisites:
#   - An Android device (or emulator) attached via adb with USB debugging
#     enabled. Tested against a Pixel 9 at 720×1600 portrait. Tap
#     coordinates below are tuned to that geometry; if you run on a
#     different display size the taps will likely miss.
#   - A built release APK at:
#       flutter/example/build/app/outputs/flutter-apk/app-release.apk
#     If missing, run `flutter build apk --release` from flutter/example.
#   - python3 with Pillow (used to compose the feature graphics).
#
# Outputs:
#   flutter/example/store_screenshots/01_calc_par.png
#   flutter/example/store_screenshots/02_calc_distressed.png
#   flutter/example/store_screenshots/03_spread_picker.png
#   flutter/example/store_screenshots/04_curves.png
#   flutter/example/store_screenshots/05_info.png
#   flutter/example/store_screenshots/06_diag.png
#   images/feature_graphic_source.png   (Maturity + cards composite)
#   images/play_feature_graphic.png     (1024×500 Play Store hero)
#

set -euo pipefail

REPO=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
PKG="com.jimzucker.iCDS"
APK="$REPO/flutter/example/build/app/outputs/flutter-apk/app-release.apk"
SHOTS="$REPO/flutter/example/store_screenshots"

if [ ! -x "$ADB" ]; then
  echo "error: adb not found at $ADB (install Android SDK platform-tools)" >&2
  exit 1
fi
if [ ! -f "$APK" ]; then
  echo "error: APK not found at $APK" >&2
  echo "  build it: (cd $REPO/flutter/example && flutter build apk --release)" >&2
  exit 1
fi

# Pick the first attached device.
DEV=$("$ADB" devices | awk '/\tdevice$/{print $1; exit}')
if [ -z "$DEV" ]; then
  echo "error: no adb device connected" >&2
  exit 1
fi
echo "→ Using adb device: $DEV"

# Tap coordinates for the test device (Pixel 9, 720×1600). Targets below the
# system nav bar.
TAP_5Y="453 357"
TAP_SPREAD_CARD="187 565"
TAP_COUPON_PLUS_1000="587 850"
TAP_DONE="640 183"
TAP_CURVES_TAB="270 1440"
TAP_INFO_TAB="450 1440"
TAP_DIAG_TAB="630 1440"
TAP_USD_BTN="83 153"

tap() {
  "$ADB" -s "$DEV" shell input tap "$1"
  sleep 0.8
}

capture() {
  local name="$1"
  "$ADB" -s "$DEV" shell screencap -p "/sdcard/$name.png" >/dev/null
  "$ADB" -s "$DEV" pull "/sdcard/$name.png" "$SHOTS/$name.png" >/dev/null
  echo "  PNG: $SHOTS/$name.png"
}

# Pin status bar to a clean 9:41 demo-mode state so screenshots are
# reproducible. Best-effort — fails silently on devices without the
# sysui demo permission, which doesn't affect the captures.
demo() {
  "$ADB" -s "$DEV" shell am broadcast -a com.android.systemui.demo \
    -e command "$1" "${@:2}" >/dev/null 2>&1 || true
}
echo "→ Pin status bar to 9:41 (demo mode)"
"$ADB" -s "$DEV" shell settings put global sysui_demo_allowed 1 >/dev/null 2>&1 || true
demo enter
demo clock -e hhmm 0941
demo battery -e level 100 -e plugged false
demo network -e wifi show -e level 4
demo notifications -e visible false

echo "→ Clear app data, reinstall APK, launch"
"$ADB" -s "$DEV" shell pm clear "$PKG" >/dev/null
"$ADB" -s "$DEV" install -r "$APK" >/dev/null
"$ADB" -s "$DEV" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 4   # let cold-start fetches kick off

echo "→ Calc tab: select 5Y maturity, capture par"
tap "$TAP_5Y"
capture "01_calc_par"

echo "→ Spread picker open at 1,100 bp (Coupon + 1,000), capture"
tap "$TAP_SPREAD_CARD"
sleep 1
tap "$TAP_COUPON_PLUS_1000"
capture "03_spread_picker"

echo "→ Done, capture distressed"
tap "$TAP_DONE"
capture "02_calc_distressed"

echo "→ Curves tab (wait for live fetches), select USD, capture"
tap "$TAP_CURVES_TAB"
sleep 4   # cronet_http should resolve JPY within a few seconds
tap "$TAP_USD_BTN"
capture "04_curves"

echo "→ Info tab"
tap "$TAP_INFO_TAB"
capture "05_info"

echo "→ Diag tab"
tap "$TAP_DIAG_TAB"
sleep 2
capture "06_diag"

# Restore the real status bar.
demo exit

echo "→ Regenerate Play Store feature graphics from 01_calc_par.png"
python3 "$REPO/images/regenerate_feature_graphic.py" \
  "$SHOTS/01_calc_par.png" \
  "$REPO/images/feature_graphic_source.png" \
  "$REPO/images/play_feature_graphic.png"

echo ""
echo "✓ Refreshed Android Play Store screenshots and feature graphics."
echo "  Open: open $SHOTS  open $REPO/images/play_feature_graphic.png"
echo "  Commit:"
echo "    git add flutter/example/store_screenshots images/feature_graphic_source.png images/play_feature_graphic.png"
