#!/usr/bin/env bash
# Copyright 2026 DolphiniOS Project
# SPDX-License-Identifier: GPL-2.0-or-later

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT="${OUTPUT:-$ROOT/Artifacts/Release/DolphiniOS-unsigned.ipa}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/.build/DerivedData-Release-Unsigned}"
APP="$DERIVED_DATA/Build/Products/Release (Non-Jailbroken)-iphoneos/DolphiniOS.app"

fail() { printf 'Unsigned IPA packaging failed: %s\n' "$*" >&2; exit 1; }

if [[ "$OUTPUT" != /* ]]; then
  OUTPUT="$ROOT/$OUTPUT"
fi

mkdir -p "$(dirname "$OUTPUT")" "$ROOT/.build/SourcePackages"

if [[ "${UNSIGNED_SKIP_BUILD:-0}" != 1 ]]; then
  xcodebuild \
    -project "$ROOT/Source/iOS/App/DolphiniOS.xcodeproj" \
    -scheme 'DiOS (NJB)' \
    -configuration 'Release (Non-Jailbroken)' \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$DERIVED_DATA" \
    -clonedSourcePackagesDirPath "$ROOT/.build/SourcePackages" \
    CODE_SIGNING_ALLOWED=NO \
    DEVELOPMENT_TEAM= \
    build
fi

[[ -d "$APP" ]] || fail "built app not found at $APP"

EXECUTABLE_NAME="$(plutil -extract CFBundleExecutable raw -o - "$APP/Info.plist")"
EXECUTABLE="$APP/$EXECUTABLE_NAME"
[[ "$(lipo -archs "$EXECUTABLE")" == "arm64" ]] || fail "payload executable is not arm64-only"
[[ "$(plutil -extract UIDeviceFamily.0 raw -o - "$APP/Info.plist")" == "1" ]] ||
  fail "payload does not target iPhone"
[[ "$(plutil -extract UIDeviceFamily.1 raw -o - "$APP/Info.plist")" == "2" ]] ||
  fail "payload does not target iPad"

IPHONE_ORIENTATIONS="$(plutil -extract 'UISupportedInterfaceOrientations~iphone' xml1 -o - "$APP/Info.plist")"
for orientation in \
  UIInterfaceOrientationPortrait \
  UIInterfaceOrientationLandscapeLeft \
  UIInterfaceOrientationLandscapeRight; do
  grep -Fq "$orientation" <<<"$IPHONE_ORIENTATIONS" ||
    fail "payload is missing required orientation $orientation"
done

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/Payload"
ditto "$APP" "$STAGE/Payload/DolphiniOS.app"
rm -rf "$STAGE/Payload/DolphiniOS.app/_CodeSignature"
rm -f "$STAGE/Payload/DolphiniOS.app/embedded.mobileprovision" "$OUTPUT"

[[ ! -e "$STAGE/Payload/DolphiniOS.app/_CodeSignature" ]] || fail "stale code signature remains"
[[ ! -e "$STAGE/Payload/DolphiniOS.app/embedded.mobileprovision" ]] || fail "stale provisioning profile remains"
if find "$STAGE/Payload/DolphiniOS.app" -type f \( \
  -iname '*.iso' -o -iname '*.gcm' -o -iname '*.rvz' -o -iname '*.wbfs' -o \
  -iname '*.wia' -o -iname '*.gcz' \) -print -quit | grep -q .; then
  fail "game image found in payload"
fi

(cd "$STAGE" && /usr/bin/zip -qry "$OUTPUT" Payload)
/usr/bin/unzip -tq "$OUTPUT" >/dev/null || fail "created archive is invalid"

echo "Created unsigned IPA for re-signing: $OUTPUT"
shasum -a 256 "$OUTPUT"
