#!/usr/bin/env bash
# Copyright 2026 DolphiniOS Project
# SPDX-License-Identifier: GPL-2.0-or-later

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEAM_ID="${TEAM_ID:-}"
ORG_ID="${ORG_ID:-}"
OUTPUT="${OUTPUT:-$ROOT/Artifacts/Release/DolphiniOS.ipa}"
DERIVED_DATA="$ROOT/.build/DerivedData-Release"
APP="$DERIVED_DATA/Build/Products/Release (Non-Jailbroken)-iphoneos/DolphiniOS.app"

fail() { printf 'Signed IPA packaging failed: %s\n' "$*" >&2; exit 1; }

if [[ "$OUTPUT" != /* ]]; then
  OUTPUT="$ROOT/$OUTPUT"
fi

[[ "$TEAM_ID" =~ ^[A-Z0-9]{10}$ ]] || { echo 'Set TEAM_ID to your 10-character Apple Developer Team ID.' >&2; exit 2; }
[[ "$ORG_ID" =~ ^[A-Za-z0-9.-]+$ ]] || { echo 'Set ORG_ID to a reverse-DNS identifier such as com.example.' >&2; exit 2; }

mkdir -p "$(dirname "$OUTPUT")" "$ROOT/.build/SourcePackages"

xcodebuild \
  -project "$ROOT/Source/iOS/App/DolphiniOS.xcodeproj" \
  -scheme 'DiOS (NJB)' \
  -configuration 'Release (Non-Jailbroken)' \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED_DATA" \
  -clonedSourcePackagesDirPath "$ROOT/.build/SourcePackages" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  DOL_PBID_ORGANIZATION_IDENTIFIER="$ORG_ID" \
  CODE_SIGN_STYLE=Automatic \
  build

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

codesign --verify --deep --strict "$APP"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/Payload"
ditto "$APP" "$STAGE/Payload/DolphiniOS.app"
if find "$STAGE/Payload/DolphiniOS.app" -type f \( \
  -iname '*.iso' -o -iname '*.gcm' -o -iname '*.rvz' -o -iname '*.wbfs' -o \
  -iname '*.wia' -o -iname '*.gcz' \) -print -quit | grep -q .; then
  fail "game image found in payload"
fi
rm -f "$OUTPUT"
(cd "$STAGE" && /usr/bin/zip -qry "$OUTPUT" Payload)
/usr/bin/unzip -tq "$OUTPUT" >/dev/null || fail "created archive is invalid"

echo "Created signed IPA: $OUTPUT"
shasum -a 256 "$OUTPUT"
