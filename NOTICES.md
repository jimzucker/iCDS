# Third-party notices

iCDS itself is licensed under the Apache License, Version 2.0 — see
[`LICENSE`](LICENSE).

This document enumerates third-party components that are bundled with or
depended on by iCDS, for anyone redistributing the source tree. The end-user
acknowledgements page is at
<https://jimzucker.github.io/iCDS/licenses>.

## Bundled native code

| Component | Version | Location | License |
| --- | --- | --- | --- |
| ISDA CDS Standard Model | 1.8.3 | `icds/isdamodel/`, `flutter/src/isdamodel/` | ISDA CDS Standard Model Public Licence 1.0 |

The full ISDA licence text lives at
[`Licenses/ISDA_CDS_Standard_Model_Public_Licence_1.0.txt`](Licenses/ISDA_CDS_Standard_Model_Public_Licence_1.0.txt)
and is copied alongside each bundled source tree at
[`icds/isdamodel/LICENSE`](icds/isdamodel/LICENSE) and
[`flutter/src/isdamodel/LICENSE`](flutter/src/isdamodel/LICENSE).

Per ISDA Public Licence §4(b), the application displays:

> "This application is based on the ISDA CDS Standard Model (version 1.8.3),
> developed and supported in collaboration with Markit Group Ltd."

## Flutter / Dart pub dependencies

Declared in [`flutter/pubspec.yaml`](flutter/pubspec.yaml) and
[`flutter/example/pubspec.yaml`](flutter/example/pubspec.yaml). Source for these
packages is **not** committed to this repository — they are fetched from
<https://pub.dev> at build time. Their licenses are bundled into the shipped app
binary via Flutter's `LicenseRegistry`.

| Package | Version | License | Shipped in |
| --- | --- | --- | --- |
| `http` | 1.6.0 | BSD-3-Clause | iOS + Android |
| `intl` | 0.19.0 | BSD-3-Clause | iOS + Android |
| `ffi` | 2.2.0 | BSD-3-Clause | iOS + Android |
| `shared_preferences` | 2.5.5 | BSD-3-Clause | iOS + Android |
| `plugin_platform_interface` | 2.1.8 | BSD-3-Clause | iOS + Android |
| `url_launcher` | 6.3.2 | BSD-3-Clause | iOS + Android |
| `cronet_http` | 1.8.0 | BSD-3-Clause | Android only |
| `in_app_review` | 2.0.11 | MIT | iOS + Android |
| `cupertino_icons` | 1.0.9 | MIT | iOS + Android |

Full notice texts for each package are reproduced verbatim at
<https://jimzucker.github.io/iCDS/licenses>.

Dev-only tooling (`ffigen`, `flutter_lints`, `flutter_launcher_icons`,
`flutter_native_splash`) is not shipped and is omitted here.

## iOS native dependencies

The iOS Swift app at the repository root uses **no** third-party Swift or
Objective-C dependencies. No CocoaPods, Swift Package Manager, or Carthage
manifest is present. The only third-party native code in the iOS build is the
bundled ISDA C library noted above.

## Reference-rate data sources

The app fetches public overnight reference rates from the Federal Reserve Bank
of New York (SOFR), the European Central Bank (€STR), the Bank of England
(SONIA), FRED at the Federal Reserve Bank of St. Louis (JPY proxy), and the
Reserve Bank of Australia (AONIA). These are data feeds, not bundled software,
and are subject to each provider's terms of use.
