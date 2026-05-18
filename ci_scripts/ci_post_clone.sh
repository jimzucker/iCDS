#!/bin/sh
# Xcode Cloud post-clone hook. Xcode Cloud automatically runs
# ci_scripts/ci_post_clone.sh after cloning the repo, before resolving
# dependencies and before xcodebuild.
#
# The iOS app (icds.xcodeproj) needs NO extra setup here: the ISDA C
# library is compiled directly via project.pbxproj and there are no
# CocoaPods / SPM / Carthage dependencies. So for the normal iOS build &
# test workflow this script is a deliberate no-op.
#
# OPTIONAL: to also run the Flutter iOS-integration tests on Xcode Cloud,
# set the workflow environment variable INSTALL_FLUTTER=1. This clones
# the Flutter SDK and resolves the Dart packages (adds several minutes /
# compute-hours per run) — leave it unset for the iOS-only workflow.
set -e

echo "ci_post_clone: $(xcodebuild -version 2>/dev/null | head -1 || echo 'xcodebuild ?')"
REPO="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
echo "ci_post_clone: repo root = $REPO"

if [ "${INSTALL_FLUTTER:-0}" != "1" ]; then
  echo "ci_post_clone: INSTALL_FLUTTER != 1 — iOS-only build, nothing to do."
  exit 0
fi

FLUTTER_DIR="$HOME/flutter"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
git config --global --add safe.directory "$FLUTTER_DIR" 2>/dev/null || true

flutter --version
( cd "$REPO/flutter" && flutter pub get )
( cd "$REPO/flutter/example" && flutter pub get )

# NOTE: Xcode Cloud does not carry shell env (PATH) between ci_scripts.
# To actually invoke `flutter test integration_test` on the Xcode Cloud
# simulator, add a ci_post_xcodebuild.sh that re-exports
# PATH="$HOME/flutter/bin:$PATH" and runs it against the booted device.
echo "ci_post_clone: Flutter ready ($($FLUTTER_DIR/bin/flutter --version | head -1))."
