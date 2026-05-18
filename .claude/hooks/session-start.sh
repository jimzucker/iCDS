#!/bin/bash
# SessionStart hook: install the Flutter/Dart SDK so Claude Code on the
# web can run the pure-Dart test suite (`flutter test test/`).
#
# Pure-Dart tests at flutter/test/ (default_risk_test.dart, imm_test.dart)
# import package:flutter_test, so the full Flutter SDK is required — a
# bare Dart SDK is not enough. Integration tests under
# flutter/example/integration_test/ still need a device/emulator and are
# NOT runnable here; only the flutter/test/ suite is.
set -euo pipefail

# Only needed in Claude Code on the web. Local devs use their own SDK.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Async: the session starts immediately while this installs in the
# background. asyncTimeout is generous because a cold container clones
# Flutter + precaches the Dart SDK (multi-minute); cached runs are fast.
# Trade-off: a `flutter test` issued before this finishes will fail.
echo '{"async": true, "asyncTimeout": 900000}'

FLUTTER_DIR="${HOME:-/root}/flutter"
FLUTTER_BIN="$FLUTTER_DIR/bin"
PROJ="${CLAUDE_PROJECT_DIR:-/home/user/iCDS}"

# Install Flutter (stable) once. The container is cached after the hook
# completes, so subsequent sessions reuse this clone.
if [ ! -x "$FLUTTER_BIN/flutter" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_BIN:$PATH"

# Persist PATH for the session and all subsequent tool calls.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$FLUTTER_BIN:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

# Mark the clone as a safe git dir (root-owned clone, non-root may run).
git config --global --add safe.directory "$FLUTTER_DIR" 2>/dev/null || true

# Pre-download Dart/Flutter artifacts and resolve packages so the first
# `flutter test` in-session has nothing left to fetch.
flutter config --no-analytics >/dev/null 2>&1 || true
flutter --version

( cd "$PROJ/flutter" && flutter pub get )
( cd "$PROJ/flutter/example" && flutter pub get )

echo "Flutter ready: $(flutter --version | head -1)"
