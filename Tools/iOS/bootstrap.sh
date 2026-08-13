#!/usr/bin/env bash
# Copyright 2026 DolphiniOS Project
# SPDX-License-Identifier: GPL-2.0-or-later

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODE="check"
INSTALL=0
SKIP_SUBMODULES=0

usage() {
  cat <<'USAGE'
Usage: Tools/iOS/bootstrap.sh [options]

  Readiness:          Tools/iOS/readiness.sh
  --mode check       Validate the Mac and initialize submodules (default)
  --mode simulator   Run the complete simulator build and smoke test
  --mode unsigned    Build an unsigned IPA for a sideloading tool to re-sign
  --mode signed      Build an Apple-signed IPA; requires TEAM_ID and ORG_ID
  --install          Install missing Homebrew and idb dependencies
  --skip-submodules  Do not initialize/update Git submodules
  -h, --help         Show this help
USAGE
}

fail() {
  printf '[bootstrap] ERROR: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '[bootstrap] %s\n' "$*"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      [[ $# -ge 2 ]] || fail "--mode requires a value"
      MODE="$2"
      shift 2
      ;;
    --install)
      INSTALL=1
      shift
      ;;
    --skip-submodules)
      SKIP_SUBMODULES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

case "$MODE" in
  check|simulator|unsigned|signed) ;;
  *) fail "unsupported mode: $MODE" ;;
esac

[[ "$(uname -s)" == "Darwin" ]] || fail "iOS builds require macOS"
command -v git >/dev/null || fail "git is required"
command -v xcodebuild >/dev/null || fail "Xcode is required"
command -v xcrun >/dev/null || fail "Xcode command-line tools are required"

if ! xcodebuild -version >/dev/null 2>&1; then
  fail "Xcode is not configured. Open Xcode once and select its command-line tools."
fi

if [[ "$INSTALL" == 1 ]]; then
  command -v brew >/dev/null || fail "Homebrew is required for --install: https://brew.sh"
  packages=()
  command -v cmake >/dev/null || packages+=(cmake)
  command -v ninja >/dev/null || packages+=(ninja)
  command -v bartycrouch >/dev/null || packages+=(bartycrouch)
  if [[ "$MODE" == "simulator" ]] && ! command -v idb_companion >/dev/null; then
    packages+=(facebook/fb/idb-companion)
  fi
  if [[ ${#packages[@]} -gt 0 ]]; then
    log "Installing missing Homebrew packages: ${packages[*]}"
    brew install "${packages[@]}"
  fi
fi

for tool in cmake ninja bartycrouch; do
  command -v "$tool" >/dev/null ||
    fail "$tool is missing. Re-run with --install or install it manually."
done

if [[ "$SKIP_SUBMODULES" != 1 ]]; then
  log "Initializing pinned Git submodules"
  git -C "$ROOT" submodule update --init --recursive
fi

if [[ "$MODE" == "simulator" ]]; then
  command -v python3 >/dev/null || fail "python3 is required for simulator UI testing"
  command -v idb_companion >/dev/null ||
    fail "idb_companion is missing. Re-run with --install."

  IDB_VENV="$ROOT/.build/idb-venv"
  if [[ ! -x "$IDB_VENV/bin/idb" ]]; then
    log "Creating the local idb client environment"
    python3 -m venv "$IDB_VENV"
    "$IDB_VENV/bin/pip" install --disable-pip-version-check fb-idb
  fi

  log "Running the complete simulator smoke test"
  exec "$ROOT/Tools/iOS/build_and_smoke_test.sh"
fi

if [[ "$MODE" == "unsigned" ]]; then
  log "Building a re-signable unsigned IPA"
  exec "$ROOT/Tools/iOS/package_unsigned_ipa.sh"
fi

if [[ "$MODE" == "signed" ]]; then
  [[ -n "${TEAM_ID:-}" ]] || fail "TEAM_ID is required for signed mode"
  [[ -n "${ORG_ID:-}" ]] || fail "ORG_ID is required for signed mode"
  log "Building an Apple-signed IPA"
  exec "$ROOT/Tools/iOS/package_ipa.sh"
fi

log "Environment ready"
xcodebuild -version
log "Next: run --mode simulator, --mode unsigned, or --mode signed"
