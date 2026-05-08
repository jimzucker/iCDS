# 1-day FFI spike: compile the ISDA CDS Standard Model C library
# (48 .c + 1 .cpp file from icds/isdamodel/src) into a single shared
# library that Dart can load on iOS and Android.
cmake_minimum_required(VERSION 3.10)

project(icds_spike_library VERSION 0.0.1 LANGUAGES C CXX)

# All ISDA sources. Glob is fine for a spike; for production we would
# list them explicitly so CMake reconfigures on file changes.
file(GLOB ISDA_C_SOURCES   "isdamodel/src/*.c")
file(GLOB ISDA_CXX_SOURCES "isdamodel/src/*.cpp")

add_library(icds_spike SHARED
  icds_spike.c
  ${ISDA_C_SOURCES}
  ${ISDA_CXX_SOURCES}
)

# Match the iOS Xcode project's HEADER_SEARCH_PATHS.
target_include_directories(icds_spike PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}/isdamodel/include/isda"
  "${CMAKE_CURRENT_SOURCE_DIR}/isdamodel/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/isdamodel/src"
)

# Suppress the C library's many legacy warnings (matches OTHER_CFLAGS=-w on iOS).
# Newer clang (Android NDK) promotes some -Wincompatible-pointer-types and
# -Wint-conversion cases to hard errors by default. The iCDS Xcode build
# doesn't hit these because Apple's clang is more lenient. Demote them so
# the legacy ISDA sources still build on Android.
target_compile_options(icds_spike PRIVATE
  -w
  -Wno-error=incompatible-pointer-types
  -Wno-error=int-conversion
  -Wno-error=implicit-function-declaration
)

set_target_properties(icds_spike PROPERTIES
  PUBLIC_HEADER icds_spike.h
  OUTPUT_NAME "icds_spike"
)

target_compile_definitions(icds_spike PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Android 15 16k page size requirement.
  target_link_options(icds_spike PRIVATE "-Wl,-z,max-page-size=16384")
  # The ISDA library uses `#if defined(LINUX) || defined(__APPLE__)` to pick
  # POSIX strcasecmp over Windows stricmp. NDK clang defines __ANDROID__ and
  # __linux__ but not the bare LINUX macro the library expects. Defining it
  # here is the smallest change that lets the library build on Android
  # without touching the upstream sources.
  target_compile_definitions(icds_spike PRIVATE LINUX)
endif()
