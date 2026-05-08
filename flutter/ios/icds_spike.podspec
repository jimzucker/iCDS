#
# Run `pod lib lint icds_spike.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'icds_spike'
  s.version          = '0.0.1'
  s.summary          = 'iCDS FFI spike — ISDA CDS Standard Model bridged to Flutter via Dart FFI.'
  s.description      = <<-DESC
1-day spike validating that the ISDA CDS Standard Model C library can be
called from Flutter / Dart via FFI on both iOS and Android. The plugin's
src/ directory holds the entire ISDA library plus a thin C wrapper; iOS
compiles them via the forwarder files in Classes/ that #include the
relative paths into ../src/isdamodel/.
                       DESC
  s.homepage         = 'https://github.com/jimzucker/iCDS'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Jim Zucker' => 'jimzucker@example.com' }

  # Forwarder C files in Classes/ relatively #include the actual sources
  # under ../src/, including the entire ISDA library. CocoaPods does not
  # allow source_files to reach above the podspec directory, hence the
  # forwarder pattern.
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'

  # ISDA header search paths (mirror the Xcode project's HEADER_SEARCH_PATHS
  # for the iCDS Swift app) so #include "dateconv.h" inside icds_spike.c
  # resolves. -w suppresses the C library's many legacy warnings, matching
  # OTHER_CFLAGS=-w in the iCDS Xcode project.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE'                          => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]'    => 'i386',
    'HEADER_SEARCH_PATHS'                     => '"${PODS_TARGET_SRCROOT}/../src/isdamodel/include/isda" "${PODS_TARGET_SRCROOT}/../src/isdamodel/include" "${PODS_TARGET_SRCROOT}/../src/isdamodel/src"',
    'OTHER_CFLAGS'                            => '$(inherited) -w',
    'OTHER_CPLUSPLUSFLAGS'                    => '$(inherited) -w',
  }
  s.swift_version    = '5.0'
end
