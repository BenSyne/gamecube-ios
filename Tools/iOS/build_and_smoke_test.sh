#!/usr/bin/env bash
# Copyright 2026 DolphiniOS Project
# SPDX-License-Identifier: GPL-2.0-or-later

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="$ROOT/Source/iOS/App/DolphiniOS.xcodeproj"
DERIVED_DATA="$ROOT/.build/DerivedData-Simulator"
PACKAGES="$ROOT/.build/SourcePackages"
ARTIFACTS="$ROOT/Artifacts/SmokeTest"
BUNDLE_FALLBACK="use.your.own.organization.identifier.DolphiniOS-njb-debug"
FIXTURE_URL="https://github.com/AndrewPiroli/Wii-donut.c/releases/download/r9/Wii-donut.c-gc.dol"
FIXTURE_SHA256="ae825bce18050093a61972111f9b03220ff03b30e5fb0e03398c11441b04ad35"
FIXTURE="$ROOT/.build/TestFixtures/Wii-donut.c-gc.dol"

log() { printf '[iOS smoke] %s\n' "$*"; }
fail() { printf '[iOS smoke] ERROR: %s\n' "$*" >&2; exit 1; }

for tool in xcodebuild xcrun curl shasum sips plutil; do
  command -v "$tool" >/dev/null || fail "$tool is required"
done

UDID="${SMOKE_UDID:-}"
if [[ -z "$UDID" ]]; then
  DEVICE_LINE="$(xcrun simctl list devices available | awk '/(iPhone|iPad)/ && /\(Booted\)/ { print; exit }')"
  if [[ -z "$DEVICE_LINE" ]]; then
    DEVICE_LINE="$(xcrun simctl list devices available | awk '/(iPhone|iPad)/ && /\(Shutdown\)/ { print; exit }')"
  fi
  UDID="$(printf '%s' "$DEVICE_LINE" | grep -Eo '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' || true)"
fi
[[ -n "$UDID" ]] || fail "No available iPhone or iPad simulator. Create one in Xcode or set SMOKE_UDID."

mkdir -p "$ARTIFACTS" "$(dirname "$FIXTURE")" "$PACKAGES"
log "Using iOS simulator $UDID"
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b

if [[ "${SMOKE_SKIP_BUILD:-0}" != "1" ]]; then
  log "Building signed simulator app"
  xcodebuild \
    -project "$PROJECT" \
    -scheme 'DiOS (NJB)' \
    -configuration 'Debug (Non-Jailbroken)' \
    -destination "platform=iOS Simulator,id=$UDID" \
    -derivedDataPath "$DERIVED_DATA" \
    -clonedSourcePackagesDirPath "$PACKAGES" \
    DEVELOPMENT_TEAM= \
    CODE_SIGNING_ALLOWED=YES \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY=- \
    build | tee "$ARTIFACTS/build.log"
fi

APP="$DERIVED_DATA/Build/Products/Debug (Non-Jailbroken)-iphonesimulator/DolphiniOS.app"
[[ -d "$APP" ]] || fail "Simulator app not found at $APP"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist" 2>/dev/null || printf '%s' "$BUNDLE_FALLBACK")"

if [[ ! -f "$FIXTURE" ]]; then
  log "Downloading pinned open-source GameCube homebrew fixture"
  curl -L --fail --retry 3 --output "$FIXTURE" "$FIXTURE_URL"
fi
printf '%s  %s\n' "$FIXTURE_SHA256" "$FIXTURE" | shasum -a 256 -c -

log "Installing app and importing test fixture"
if [[ "${SMOKE_PRESERVE_DATA:-0}" != "1" ]]; then
  xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
fi
xcrun simctl install "$UDID" "$APP"
DATA_CONTAINER="$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)"
mkdir -p "$DATA_CONTAINER/Documents/Inbox" "$DATA_CONTAINER/Documents/Software"
INCOMING_FILE="$DATA_CONTAINER/Documents/Inbox/GameCube-Donut.dol"
IMPORTED_FILE="$DATA_CONTAINER/Documents/Software/GameCube-Donut.dol"
cp "$FIXTURE" "$INCOMING_FILE"
rm -f "$IMPORTED_FILE"
rm -f "$DATA_CONTAINER/Documents/StateSaves/ID-GameCube-Donut.s01"
xcrun simctl spawn "$UDID" defaults delete "$BUNDLE_ID" launch_times >/dev/null 2>&1 || true
xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
SIMCTL_CHILD_DOL_SUPPRESS_BOOT_NOTICE=1 \
  xcrun simctl launch "$UDID" "$BUNDLE_ID" | tee "$ARTIFACTS/launch.txt"
sleep 4
xcrun simctl io "$UDID" screenshot "$ARTIFACTS/library.png"

IDB="$ROOT/.build/idb-venv/bin/idb"
command -v "$IDB" >/dev/null || fail "fb-idb is required for the UI tap. Install idb-companion and create .build/idb-venv with fb-idb."

COMPANION_PID=""
cleanup() {
  if [[ -n "$COMPANION_PID" ]]; then
    kill "$COMPANION_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if ! "$IDB" list-targets 2>/dev/null | grep -Fq "$UDID"; then
  command -v idb_companion >/dev/null || fail "idb_companion is required for UI automation"
  log "Starting idb companion"
  idb_companion --udid "$UDID" --grpc-port 10882 --log-file-path "$ARTIFACTS/idb-companion.log" \
    >>"$ARTIFACTS/idb-companion-stdio.log" 2>&1 &
  COMPANION_PID=$!
  sleep 3
  "$IDB" connect localhost 10882 >/dev/null
fi

accessibility_center_for_value() {
  local json="$1"
  local field="$2"
  local wanted="$3"
  local expected_role="${4:-}"
  local index value role x y width height center_x center_y

  for ((index = 0; index < 200; index++)); do
    value="$(printf '%s' "$json" | plutil -extract "$index.$field" raw -o - -- - 2>/dev/null || true)"
    if [[ "$value" == "$wanted" ]]; then
      if [[ -n "$expected_role" ]]; then
        role="$(printf '%s' "$json" | plutil -extract "$index.role" raw -o - -- - 2>/dev/null || true)"
        [[ "$role" == "$expected_role" ]] || continue
      fi
      x="$(printf '%s' "$json" | plutil -extract "$index.frame.x" raw -o - -- -)"
      y="$(printf '%s' "$json" | plutil -extract "$index.frame.y" raw -o - -- -)"
      width="$(printf '%s' "$json" | plutil -extract "$index.frame.width" raw -o - -- -)"
      height="$(printf '%s' "$json" | plutil -extract "$index.frame.height" raw -o - -- -)"
      center_x="$(awk "BEGIN { print int($x + $width / 2) }")"
      center_y="$(awk "BEGIN { print int($y + $height / 2) }")"
      printf '%s %s\n' "$center_x" "$center_y"
      return 0
    fi
  done

  return 1
}

tap_accessibility_label_if_present() {
  local json="$1"
  local wanted="$2"
  local expected_role="${3:-AXButton}"
  local coordinates center_x center_y

  coordinates="$(accessibility_center_for_value "$json" AXLabel "$wanted" "$expected_role")" || return 1
  read -r center_x center_y <<<"$coordinates"
  "$IDB" ui tap "$center_x" "$center_y" --udid "$UDID"
}

tap_accessibility_label() {
  local json="$1"
  local wanted="$2"
  local expected_role="${3:-AXButton}"

  tap_accessibility_label_if_present "$json" "$wanted" "$expected_role" ||
    fail "Could not locate accessible action: $wanted"
}

show_emulation_menu() {
  local coordinates nav_center_x

  DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
  tap_accessibility_label "$DESCRIPTION" "Show Emulation Menu"
  sleep 1
  DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
  coordinates="$(accessibility_center_for_value "$DESCRIPTION" AXUniqueId EmulationiOSView)" ||
    fail "Emulation navigation bar did not appear"
  read -r nav_center_x TOP_Y <<<"$coordinates"
}

tap_navigation_action() {
  local label="$1"
  local fallback_x="$2"

  DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
  if ! tap_accessibility_label_if_present "$DESCRIPTION" "$label"; then
    "$IDB" ui tap "$fallback_x" "$TOP_Y" --udid "$UDID"
  fi
}

library_is_visible() {
  local json="$1"

  grep -Fq '"AXLabel":"Library"' <<<"$json" ||
    { grep -Fq '"AXLabel":"GameCube-Donut.dol"' <<<"$json" &&
      grep -Fq '"AXLabel":"Tab Bar"' <<<"$json"; }
}

log "Importing through the registered Files/document URL flow"
DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
if [[ "${SMOKE_PRESERVE_DATA:-0}" != "1" ]]; then
  grep -Fq '"AXLabel":"Import a Game"' <<<"$DESCRIPTION" || fail "Clean install did not show Library onboarding"
fi
xcrun simctl openurl "$UDID" "file://$INCOMING_FILE"
sleep 2
DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
for expected in '"AXLabel":"Import"' '"AXLabel":"Copy"' '"AXLabel":"Move"' '"AXLabel":"Cancel"'; do
  grep -Fq "$expected" <<<"$DESCRIPTION" || fail "Document importer is missing expected accessible action: $expected"
done

COPY_LABEL="$(printf '%s' "$DESCRIPTION" | plutil -extract 2.AXLabel raw -o - -- -)"
[[ "$COPY_LABEL" == "Copy" ]] || fail "Could not locate the document import Copy action"
COPY_X="$(printf '%s' "$DESCRIPTION" | plutil -extract 2.frame.x raw -o - -- -)"
COPY_Y="$(printf '%s' "$DESCRIPTION" | plutil -extract 2.frame.y raw -o - -- -)"
COPY_WIDTH="$(printf '%s' "$DESCRIPTION" | plutil -extract 2.frame.width raw -o - -- -)"
COPY_HEIGHT="$(printf '%s' "$DESCRIPTION" | plutil -extract 2.frame.height raw -o - -- -)"
COPY_CENTER_X="$(awk "BEGIN { print int($COPY_X + $COPY_WIDTH / 2) }")"
COPY_CENTER_Y="$(awk "BEGIN { print int($COPY_Y + $COPY_HEIGHT / 2) }")"
"$IDB" ui tap "$COPY_CENTER_X" "$COPY_CENTER_Y" --udid "$UDID"
for _ in {1..15}; do
  [[ -s "$IMPORTED_FILE" ]] && break
  sleep 1
done
[[ -s "$IMPORTED_FILE" ]] || fail "Document importer did not create the library copy"
cmp -s "$FIXTURE" "$IMPORTED_FILE" || fail "Imported fixture differs from its source"

for _ in {1..15}; do
  DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
  grep -Fq '"AXLabel":"GameCube-Donut.dol"' <<<"$DESCRIPTION" && break
  sleep 1
done
grep -Fq '"AXLabel":"GameCube-Donut.dol"' <<<"$DESCRIPTION" || fail "Imported game did not appear in Library"
xcrun simctl io "$UDID" screenshot "$ARTIFACTS/import-complete.png" >/dev/null

log "Launching the first library item"
"$IDB" ui tap 120 250 --udid "$UDID"
sleep 8
xcrun simctl io "$UDID" screenshot "$ARTIFACTS/emulation.png"
DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
if grep -Eq '"AXLabel":"(Warning|Error)"' <<<"$DESCRIPTION"; then
  fail "Core presented a runtime warning or error after launch"
fi

LAUNCH_SERVICES="$(xcrun simctl spawn "$UDID" launchctl list)"
if ! grep -Fq "UIKitApplication:$BUNDLE_ID" <<<"$LAUNCH_SERVICES"; then
  fail "App process was not found after launching the fixture"
fi

SCREEN_JSON="$("$IDB" describe --udid "$UDID" --json)"
SCREEN_WIDTH="$(printf '%s' "$SCREEN_JSON" | plutil -extract screen_dimensions.width_points raw -o - -- -)"
PAUSE_X=$((SCREEN_WIDTH - 82))
STOP_X=$((SCREEN_WIDTH - 28))

log "Verifying pause freezes the rendered frame"
show_emulation_menu
tap_navigation_action "Pause Emulation" "$PAUSE_X"
sleep 1
xcrun simctl io "$UDID" screenshot "$ARTIFACTS/pause-a.png" >/dev/null
sleep 2
xcrun simctl io "$UDID" screenshot "$ARTIFACTS/pause-b.png" >/dev/null
sips -s format bmp "$ARTIFACTS/pause-a.png" --out "$ARTIFACTS/pause-a.bmp" >/dev/null
sips -s format bmp "$ARTIFACTS/pause-b.png" --out "$ARTIFACTS/pause-b.bmp" >/dev/null
cmp -s "$ARTIFACTS/pause-a.bmp" "$ARTIFACTS/pause-b.bmp" || fail "Rendered output changed while paused"

log "Creating and loading save state slot 1"
tap_navigation_action "Emulation Settings" 32
sleep 1
DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
tap_accessibility_label "$DESCRIPTION" "Save State"
STATE_FILE="$DATA_CONTAINER/Documents/StateSaves/ID-GameCube-Donut.s01"
for _ in {1..15}; do
  [[ -s "$STATE_FILE" ]] && break
  sleep 1
done
[[ -s "$STATE_FILE" ]] || fail "Save-state file was not created"
STATE_SHA256="$(shasum -a 256 "$STATE_FILE" | awk '{print $1}')"
log "Save state created ($(stat -f '%z' "$STATE_FILE") bytes, SHA-256 $STATE_SHA256)"

show_emulation_menu
tap_navigation_action "Emulation Settings" 32
sleep 1
DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
tap_accessibility_label "$DESCRIPTION" "Load State"
sleep 5
xcrun simctl io "$UDID" screenshot "$ARTIFACTS/state-loaded.png" >/dev/null
DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
if grep -Eq '"AXLabel":"(Warning|Error)"' <<<"$DESCRIPTION"; then
  fail "Core presented a runtime warning or error while loading a save state"
fi
LAUNCH_SERVICES="$(xcrun simctl spawn "$UDID" launchctl list)"
grep -Fq "UIKitApplication:$BUNDLE_ID" <<<"$LAUNCH_SERVICES" || fail "App exited while loading a save state"

log "Stopping emulation and returning to Library"
show_emulation_menu
tap_navigation_action "Stop Emulation" "$STOP_X"
sleep 1
DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
tap_accessibility_label "$DESCRIPTION" "Yes"
sleep 4
xcrun simctl io "$UDID" screenshot "$ARTIFACTS/library-after-stop.png" >/dev/null
DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
library_is_visible "$DESCRIPTION" || fail "Library was not restored after stopping emulation"

log "Verifying the physical-device JIT gate and cancel path"
SIMCTL_CHILD_DOL_FORCE_JIT_WAIT=1 \
  xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" >/dev/null
sleep 4
"$IDB" ui tap 120 250 --udid "$UDID"
sleep 3
xcrun simctl io "$UDID" screenshot "$ARTIFACTS/jit-gate.png" >/dev/null
DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
for expected in \
  '"AXLabel":"JIT Required for Full Speed"' \
  '"AXLabel":"Open JIT Setup Guide"' \
  '"AXLabel":"Continue Without JIT (Very Slow)"' \
  '"AXLabel":"Back to Library"'; do
  grep -Fq "$expected" <<<"$DESCRIPTION" || fail "JIT gate is missing expected accessible action: $expected"
done

tap_accessibility_label "$DESCRIPTION" "Back to Library"
sleep 3
DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
library_is_visible "$DESCRIPTION" || fail "JIT cancel did not return to Library"
xcrun simctl io "$UDID" screenshot "$ARTIFACTS/jit-cancel-library.png" >/dev/null

log "Verifying Low Power Mode/thermal performance preflight"
SIMCTL_CHILD_DOL_FORCE_PERFORMANCE_WARNING=1 \
  xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" >/dev/null
sleep 4
"$IDB" ui tap 120 250 --udid "$UDID"
sleep 3
xcrun simctl io "$UDID" screenshot "$ARTIFACTS/performance-warning.png" >/dev/null
DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
for expected in \
  '"AXLabel":"Performance Warning"' \
  '"AXLabel":"Continue Anyway"' \
  '"AXLabel":"Back to Library"'; do
  grep -Fq "$expected" <<<"$DESCRIPTION" || fail "Performance preflight is missing expected accessible action: $expected"
done
tap_accessibility_label "$DESCRIPTION" "Back to Library"
sleep 3
DESCRIPTION="$("$IDB" ui describe-all --udid "$UDID")"
library_is_visible "$DESCRIPTION" || fail "Performance warning cancel did not return to Library"

log "PASS: import, launch, Metal output, touch UI, pause, save/load state, stop, JIT gate, and performance preflight"
log "Artifacts: $ARTIFACTS"
