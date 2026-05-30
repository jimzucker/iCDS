//
//  license_consistency_test.dart
//  icds
//
//  Copyright © 2016-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//
//  Locks in Apache 2.0 as the canonical iCDS source license on the Flutter side
//  and enforces the ISDA CDS Standard Model Public Licence §4(b) attribution
//  wording in-app. Mirrors icdsTests/LicenseConsistencyTests.swift on iOS.
//  Pure-Dart — runs under `flutter test test/`.
//

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// ISDA §4(b) attribution sentence — must match exactly. Bumping the bundled
// model version means bumping this string in both apps.
const _isdaAttribution =
    'This application is based on the ISDA CDS Standard Model (version 1.8.3), '
    'developed and supported in collaboration with Markit Group Ltd.';

const _apacheHeaderLine =
    'Licensed under the Apache License, Version 2.0 — see LICENSE in project root.';

const _licensesPageURL = 'https://jimzucker.github.io/iCDS/licenses';

/// Repo root resolved from the test file's own location. The test file lives
/// at `flutter/test/license_consistency_test.dart`, so the repo root is two
/// directories up — this works regardless of the cwd from which the suite
/// is invoked.
Directory get _repoRoot {
  final here = File.fromUri(Platform.script).parent;
  // here is typically …/flutter/test or …/flutter (when invoked via
  // `flutter test`). Walk up until we find a directory containing the
  // canonical LICENSE file.
  Directory dir = here;
  for (int i = 0; i < 6; i++) {
    if (File('${dir.path}/LICENSE').existsSync() &&
        Directory('${dir.path}/icds').existsSync()) {
      return dir;
    }
    dir = dir.parent;
  }
  throw StateError('Could not locate repo root from ${here.path}');
}

String _read(String relative) =>
    File('${_repoRoot.path}/$relative').readAsStringSync();

void main() {
  group('LICENSE files', () {
    test('Root LICENSE is Apache 2.0', () {
      final body = _read('LICENSE');
      expect(body, contains('Apache License'));
      expect(body, contains('Version 2.0'));
      expect(body, contains('www.apache.org/licenses'));
    });

    test('Subtree LICENSE files exist (flutter side)', () {
      expect(File('${_repoRoot.path}/flutter/LICENSE').existsSync(), isTrue,
          reason: 'flutter/LICENSE must exist as a subtree license pointer');
      expect(File('${_repoRoot.path}/flutter/src/isdamodel/LICENSE').existsSync(),
          isTrue,
          reason:
              'flutter/src/isdamodel/LICENSE must carry the full ISDA licence '
              'alongside the bundled C source');
      expect(File('${_repoRoot.path}/Licenses/'
                  'ISDA_CDS_Standard_Model_Public_Licence_1.0.txt')
              .existsSync(),
          isTrue);
    });

    test('flutter/LICENSE is no longer the Flutter template placeholder', () {
      final body = _read('flutter/LICENSE');
      expect(body, isNot(contains('TODO: Add your license here')),
          reason: 'flutter/LICENSE must not be the Flutter pubspec template');
      expect(body, contains('Apache License'));
    });

    test('ISDA subtree LICENSE matches the canonical text', () {
      final canonical =
          _read('Licenses/ISDA_CDS_Standard_Model_Public_Licence_1.0.txt');
      final inSubtree = _read('flutter/src/isdamodel/LICENSE');
      expect(inSubtree, equals(canonical),
          reason:
              'flutter/src/isdamodel/LICENSE drifted from the canonical ISDA '
              'licence text in Licenses/');
    });
  });

  group('Dart source headers', () {
    test('Every Dart source file carries the Apache 2.0 header', () {
      final dirs = [
        'flutter/lib',
        'flutter/example/lib',
        'flutter/example/integration_test',
        'flutter/example/test',
        'flutter/test',
      ];
      final missing = <String>[];
      int checked = 0;
      for (final dir in dirs) {
        final root = Directory('${_repoRoot.path}/$dir');
        if (!root.existsSync()) continue;
        for (final entity in root.listSync(recursive: true)) {
          if (entity is! File) continue;
          if (!entity.path.endsWith('.dart')) continue;
          // Skip the build/tooling-generated registrant files.
          if (entity.path.contains('.dart_tool')) continue;
          checked += 1;
          final firstLines = entity
              .readAsLinesSync()
              .take(12)
              .join('\n');
          if (!firstLines.contains(_apacheHeaderLine)) {
            missing.add(entity.path.replaceFirst(_repoRoot.path, ''));
          }
        }
      }
      expect(checked, greaterThan(10),
          reason: 'Sanity: expected more than 10 .dart files');
      expect(missing, isEmpty,
          reason: 'Dart files missing Apache 2.0 header: '
              '${missing.join(', ')}');
    });
  });

  group('In-app Info tab disclosure', () {
    test('info_tab.dart includes the ISDA §4(b) attribution sentence', () {
      final body = _read('flutter/example/lib/info_tab.dart');
      expect(body, contains(_isdaAttribution));
      expect(body, contains('ISDA CDS Standard Model Public Licence 1.0'));
      expect(body, contains('© 2009 JPMorgan Chase Bank, N.A.'));
    });

    test('info_tab.dart links to the consolidated /licenses page', () {
      final body = _read('flutter/example/lib/info_tab.dart');
      expect(body, contains(_licensesPageURL));
      expect(body, contains('Licenses & Acknowledgements'));
    });

    test('info_tab.dart wires the native showLicensePage entry', () {
      // The offline open-source-licenses screen is Flutter's robust fallback
      // for full dependency disclosure. Keep it wired.
      final body = _read('flutter/example/lib/info_tab.dart');
      expect(body, contains('showLicensePage'));
      expect(body, contains('Open-source licenses (offline)'));
    });
  });

  group('Consolidated /licenses page + NOTICES', () {
    test('licenses.md exists and covers app + ISDA', () {
      expect(File('${_repoRoot.path}/licenses.md').existsSync(), isTrue);
      final body = _read('licenses.md');
      expect(body, contains('Apache License, Version 2.0'));
      expect(body, contains('ISDA CDS Standard Model Public Licence 1.0'));
      expect(body, contains(_isdaAttribution));
    });

    test('licenses.md reproduces notices for every shipped pub dep', () {
      final body = _read('licenses.md');
      for (final pkg in [
        'http 1.6.0',
        'intl 0.19.0',
        'ffi 2.2.0',
        'cronet_http 1.8.0',
        'shared_preferences 2.5.5',
        'plugin_platform_interface 2.1.8',
        'url_launcher 6.3.2',
        'in_app_review 2.0.11',
        'cupertino_icons 1.0.9',
      ]) {
        expect(body, contains(pkg),
            reason: 'licenses.md missing notice for $pkg');
      }
    });

    test('NOTICES.md exists and enumerates bundled components', () {
      expect(File('${_repoRoot.path}/NOTICES.md').existsSync(), isTrue);
      final body = _read('NOTICES.md');
      expect(body, contains('ISDA CDS Standard Model'));
      for (final pkg in [
        'http',
        'intl',
        'ffi',
        'shared_preferences',
        'plugin_platform_interface',
        'url_launcher',
        'in_app_review',
        'cupertino_icons',
        'cronet_http',
      ]) {
        expect(body, contains(pkg),
            reason: 'NOTICES.md missing pub package: $pkg');
      }
    });
  });
}
