# iCDS Flutter spike

A working Flutter / Dart-FFI port of the [iCDS](https://github.com/jimzucker/iCDS) iOS CDS calculator's numerical core, validating that the ISDA CDS Standard Model C library can be bridged from Dart and produces bit-identical results on iOS arm64 and Android arm64.

## Status

End-to-end validated on 2026-05-06:

- ✅ ISDA C library compiles unchanged on Android NDK (clang 17 / Android API 24+) and iOS (Xcode 26 / iOS 13+).
- ✅ `JpmcdsDate` and `JpmcdsCdsoneUpfrontCharge` callable from Dart via `dart:ffi`.
- ✅ Bit-identical numerical results on **iPhone 17 Pro Simulator (iOS 26.4)** and **Pixel 9 emulator (Android API 37)** for the test cases in `example/lib/main.dart`.

| Test (5Y SNAC, today=2026-05-04, recovery=40%, discount=4.5%) | iOS | Android |
|---|---|---|
| par   (sp=cp=100 bp) | −0.00 bp | −0.00 bp |
| wide  (sp=250, cp=100) | +625.93 bp | +625.93 bp |
| tight (sp= 50, cp=100) | −226.25 bp | −226.25 bp |

## Layout

```
src/
  CMakeLists.txt          # builds the C library on Android (and iOS via the
                          # plugin_ffi convention)
  icds_spike.h, .c        # thin C wrapper exposing primitive-only entry points
                          # (icds_spike_jpmcds_date, icds_spike_upfront)
  isdamodel/
    src/                  # 48 .c + 1 .cpp files, vendored from iCDS with
                          # one Android-portability patch (see below)
    include/isda/         # ISDA public headers

ios/
  icds_spike.podspec      # CocoaPods config: ISDA header search paths,
                          # OTHER_CFLAGS=-w (matches the iCDS Xcode project)
  Classes/                # one forwarder per ISDA .c file so each compiles
                          # as its own translation unit (lprintf.c and
                          # lscanf.c each define their own `struct format`)

lib/
  icds_spike.dart                     # public API (jpmcdsDate, upfrontFraction)
  icds_spike_bindings_generated.dart  # hand-written FFI bindings

example/
  lib/main.dart           # Flutter app exercising both entry points and
                          # showing pass/fail per test
```

## Android-specific portability deltas

These are the only changes required to compile the upstream ISDA library on Android NDK:

1. `src/CMakeLists.txt`: `target_compile_definitions(icds_spike PRIVATE LINUX)` for the `__APPLE__||LINUX` `strcasecmp` shim in `buscache.c`.
2. `src/isdamodel/src/cerror.c`: `JpmcdsWriteToLog`'s last parameter changed from `va_list` to `va_list *` (5-line patch). NDK clang treats implicit `void* → va_list` as a hard error not suppressible via `-w`; Apple clang historically accepts it.

## Build & run

### iOS Simulator

```sh
cd example
flutter build ios --simulator --debug
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted com.jimzucker.icdsSpikeExample
```

### Android emulator

```sh
flutter emulators --launch Pixel_9    # or any installed Android image
cd example
flutter build apk --debug
~/Library/Android/sdk/platform-tools/adb install -r \
    build/app/outputs/flutter-apk/app-debug.apk
~/Library/Android/sdk/platform-tools/adb shell am start \
    -n com.jimzucker.icds_spike_example/.MainActivity
```

## What this is NOT

A full Flutter port of iCDS. The UI here is a one-screen test harness, not a SwiftUI rewrite. The next steps — porting `CDSCalculator.swift`'s IMM/business-day helpers to Dart, building the Fee / Curves / Info tabs, porting `SOFRFetcher.swift`'s 5 central-bank fetchers — are tracked separately.

## License

The ISDA CDS Standard Model C library (`src/isdamodel/`) is © 2009 International Swaps and Derivatives Association, Inc., licensed under the [ISDA CDS Standard Model Public License](https://github.com/jimzucker/iCDS/blob/master/Licenses/ISDA_CDS_Standard_Model_Public_Licence_1.0.txt). The spike-specific Dart, C wrapper, and Flutter scaffold code follow iCDS's [Apache 2.0](https://github.com/jimzucker/iCDS/blob/master/LICENSE) license.
