#!/bin/bash
# Build the on-device Metal self-test (24 tests, PASS/FAIL per feature) for iOS 16 arm64.
#   userspace/metaltest/build.sh [OUT_DIR]        default OUT_DIR: userspace/out/metaltest
# Outputs: metaltest (ad-hoc signed) and default.metallib (needs Xcode's Metal toolchain;
# without it tests 07-11 and 14 FAIL/SKIP). Device-independent: it only uses the public
# Metal API, so it runs unchanged on any Metal device (SweetNativeMetal or RedwoodMetal).
# Origin: branch gpu (limonetexd/ios-sweet), userland/metaltest, built there by tools/metal-build.sh test.
set -eu
src=$(cd "$(dirname "$0")" && pwd)
out=${1:-$src/../out/metaltest}
mkdir -p "$out"
sdk=$(xcrun --sdk iphoneos --show-sdk-path)
xcrun --sdk iphoneos clang -target arm64-apple-ios16.0 -isysroot "$sdk" -O1 -fobjc-arc -Wall -Wextra \
	-framework Foundation -framework Metal -framework IOSurface \
	-o "$out/metaltest" "$src/metaltest.m"
codesign -f -s - "$out/metaltest"
rm -f "$out/default.metallib"
if xcrun -sdk iphoneos metal -c -mios-version-min=16.0 -o "$out/metaltest.air" "$src/shaders.metal" &&
	xcrun -sdk iphoneos metallib -o "$out/default.metallib" "$out/metaltest.air"; then
	rm -f "$out/metaltest.air"
else
	rm -f "$out/default.metallib" "$out/metaltest.air"
	echo "no default.metallib (Metal toolchain missing?): tests 07-11 and 14 will FAIL/SKIP" >&2
fi
shasum -a 256 "$out/metaltest" "$out"/default.metallib 2>/dev/null || true
