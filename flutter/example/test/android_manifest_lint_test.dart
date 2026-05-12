/// Lint: AndroidManifest.xml must declare an ACTION_VIEW <queries> entry
/// for the `https` scheme. Without it, url_launcher's canLaunchUrl returns
/// false on Android 11+ and every Info-tab link silently no-ops.
///
/// This complements `info_tab_links_test.dart`, which checks the Dart
/// side, by catching regressions in the manifest itself.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AndroidManifest declares ACTION_VIEW + https for url_launcher', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest.contains('<queries>'), isTrue,
        reason: 'AndroidManifest must have a <queries> block');

    final hasHttpsView = RegExp(
      r'<intent>\s*<action\s+android:name="android\.intent\.action\.VIEW"\s*/>\s*'
      r'<data\s+android:scheme="https"\s*/>\s*</intent>',
      dotAll: true,
    ).hasMatch(manifest);

    expect(hasHttpsView, isTrue,
        reason:
            'AndroidManifest <queries> must contain an <intent> with '
            'action.VIEW + scheme="https" or url_launcher will silently '
            'no-op on Android 11+. See info_tab.dart.');
  });
}
