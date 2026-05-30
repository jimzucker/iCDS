//
//  info_tab_links_test.dart
//  icds
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//

/// Widget test: every Info-tab link calls launchUrl with the right URI.
///
/// Why this test exists: in 3.1.0 the Android Info-tab links silently
/// no-op'd. The cause was two-fold — (a) `_open` gated on `canLaunchUrl`
/// which returns false on Android 11+ without a manifest <queries>
/// entry, and (b) we had no test exercising the launch path. This
/// covers (b). The complementary lint for the AndroidManifest itself
/// lives in `test/android_manifest_lint_test.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:icds_spike_example/info_tab.dart';

class _RecordingLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final List<String> launched = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launched.add(url);
    return true;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

void main() {
  late _RecordingLauncher launcher;

  setUp(() {
    launcher = _RecordingLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  // Pump the InfoTab inside a tall surface so every link is laid out without
  // having to scroll. InkWell needs a Material ancestor; Scaffold supplies one.
  Future<void> pumpInfo(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InfoTab())),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapLink(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.scrollUntilVisible(finder, 100,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('Documentation & Source button launches docs URL', (tester) async {
    await pumpInfo(tester);
    await tapLink(tester, 'Documentation & Source');
    expect(launcher.launched, ['https://jimzucker.github.io/iCDS/']);
  });

  testWidgets('cdsmodel.com attribution link launches ISDA URL', (tester) async {
    await pumpInfo(tester);
    await tapLink(tester, 'www.cdsmodel.com');
    expect(launcher.launched, ['https://www.cdsmodel.com']);
  });

  testWidgets('Apache license link launches license URL', (tester) async {
    await pumpInfo(tester);
    await tapLink(tester, 'apache.org/licenses/LICENSE-2.0');
    expect(launcher.launched, ['https://www.apache.org/licenses/LICENSE-2.0']);
  });

  testWidgets('Privacy Policy link launches privacy URL', (tester) async {
    await pumpInfo(tester);
    await tapLink(tester, 'Privacy Policy');
    expect(launcher.launched, ['https://jimzucker.github.io/iCDS/PRIVACY']);
  });
}
