#!/usr/bin/env bash
#
# refresh.sh — re-generate the iOS App Store screenshots (and the
# README hero JPEG) by running the icdsUITests UI test on the
# canonical iPhone 14 Plus simulator, extracting the test's
# screenshot attachments, and dropping them into place.
#
# One-shot:
#   ./icds/store_screenshots/refresh.sh
#
# Outputs:
#   icds/store_screenshots/01_calc_par.png
#   icds/store_screenshots/02_calc_distressed.png
#   icds/store_screenshots/03_spread_picker.png
#   icds/store_screenshots/04_curves.png
#   icds/store_screenshots/05_info.png
#   icds/store_screenshots/06_diag.png
#   images/JPEG_iCDSWikiScreenShoot.jpg  (re-encoded from 01_calc_par)
#

set -euo pipefail

REPO=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
SIM_NAME="iPhone 14 Plus (App Store screenshots)"
SHOTS_DIR="$REPO/icds/store_screenshots"
HERO_JPEG="$REPO/images/JPEG_iCDSWikiScreenShoot.jpg"
RESULT_BUNDLE="/tmp/icds-ui-shots.xcresult"

# Resolve simulator id by name (the literal name above is the App Store
# screenshot device that Apple/our memory file pins this workflow to).
SIM_ID=$(xcrun simctl list devices \
  | grep -F "$SIM_NAME" \
  | head -1 \
  | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')

if [ -z "$SIM_ID" ]; then
  echo "error: simulator '$SIM_NAME' not found. Create it via Xcode > Devices and Simulators." >&2
  exit 1
fi

echo "→ Boot $SIM_NAME ($SIM_ID)"
xcrun simctl boot "$SIM_ID" >/dev/null 2>&1 || true

echo "→ Pin status bar to 9:41 with full battery / signal"
xcrun simctl status_bar "$SIM_ID" override \
  --time 9:41 \
  --batteryLevel 100 --batteryState charged \
  --cellularBars 4 --wifiBars 3 \
  --dataNetwork wifi --cellularMode active

echo "→ Run UI test (icdsUITests/testCaptureAppStoreScreenshots)"
rm -rf "$RESULT_BUNDLE"
xcodebuild \
  -project "$REPO/icds.xcodeproj" \
  -scheme icds \
  -destination "platform=iOS Simulator,id=$SIM_ID" \
  -only-testing:icdsUITests/icdsUITests/testCaptureAppStoreScreenshots \
  -resultBundlePath "$RESULT_BUNDLE" \
  test \
  > /tmp/icds-shots-build.log 2>&1 \
  || { tail -20 /tmp/icds-shots-build.log; exit 1; }

echo "→ Extract attachments from $RESULT_BUNDLE"
EXTRACTED=$(mktemp -d)
xcrun xcresulttool export attachments \
  --path "$RESULT_BUNDLE" \
  --output-path "$EXTRACTED" >/dev/null

# Map UUID-named PNGs back to the NN_name.png convention via the manifest.
python3 - "$EXTRACTED" "$SHOTS_DIR" <<'PY'
import json, shutil, os, re, sys
extracted, target = sys.argv[1], sys.argv[2]
os.makedirs(target, exist_ok=True)
manifest = json.load(open(os.path.join(extracted, 'manifest.json')))
for entry in manifest:
    for att in entry.get('attachments', []):
        # suggestedHumanReadableName looks like "01_calc_par_0_<uuid>.png"
        m = re.match(r'^(\d+_[a-z_]+)_\d+_', att['suggestedHumanReadableName'])
        if not m:
            continue
        src = os.path.join(extracted, att['exportedFileName'])
        dst = os.path.join(target, m.group(1) + '.png')
        shutil.copyfile(src, dst)
        print(f"  PNG: {dst}")
PY

echo "→ Re-encode 01_calc_par.png → hero JPEG (README site/wiki)"
sips -s format jpeg -s formatOptions 90 \
  "$SHOTS_DIR/01_calc_par.png" \
  --out "$HERO_JPEG" >/dev/null
echo "  JPG: $HERO_JPEG"

echo ""
echo "✓ Refreshed iOS App Store screenshots and the README hero."
echo "  Inspect with: open $SHOTS_DIR  &&  open $HERO_JPEG"
echo "  Commit:       git add icds/store_screenshots images/JPEG_iCDSWikiScreenShoot.jpg"
