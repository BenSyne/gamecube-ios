#!/usr/bin/env bash
# Copyright 2026 DolphiniOS Project
# SPDX-License-Identifier: GPL-2.0-or-later

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIN_FREE_GB="${MIN_FREE_GB:-20}"
blockers=0
warnings=0

ok() {
  printf '[ready] PASS: %s\n' "$*"
}

info() {
  printf '[ready] INFO: %s\n' "$*"
}

warn() {
  warnings=$((warnings + 1))
  printf '[ready] WARN: %s\n' "$*"
}

block() {
  blockers=$((blockers + 1))
  printf '[ready] BLOCKED: %s\n' "$*"
}

printf 'GameCube on iOS readiness check\n'
printf '================================\n'

if [[ "$(uname -s)" == "Darwin" ]]; then
  ok "macOS detected"
else
  block "a local Mac is required for Xcode and physical-device installation"
fi

if command -v xcodebuild >/dev/null 2>&1; then
  xcode_version="$(xcodebuild -version 2>/dev/null | tr '\n' ' ')"
  ok "${xcode_version% }"
  if xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
    ok "Xcode first-launch tasks and license are complete"
  else
    block "open Xcode once, accept its license, and finish first-launch setup"
  fi
else
  block "Xcode is not installed or its command-line tools are not selected"
fi

if command -v git >/dev/null 2>&1; then
  ok "Git is available"
else
  block "Git is required"
fi

missing_build_tools=()
for tool in cmake ninja bartycrouch; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    missing_build_tools+=("$tool")
  fi
done

if [[ ${#missing_build_tools[@]} -eq 0 ]]; then
  ok "CMake, Ninja, and BartyCrouch are installed"
elif command -v brew >/dev/null 2>&1; then
  warn "the agent will install missing Homebrew tools after Continue: ${missing_build_tools[*]}"
else
  block "install Homebrew so the agent can add: ${missing_build_tools[*]}"
fi

if command -v idb_companion >/dev/null 2>&1; then
  ok "the simulator UI-test companion is installed"
elif command -v brew >/dev/null 2>&1; then
  warn "the agent will install idb-companion for the simulator smoke test"
else
  block "Homebrew is needed to install idb-companion"
fi

free_kb="$(df -Pk "$ROOT" | awk 'NR == 2 {print $4}')"
if [[ "$free_kb" =~ ^[0-9]+$ ]]; then
  free_gb=$((free_kb / 1024 / 1024))
  if (( free_gb >= MIN_FREE_GB )); then
    ok "${free_gb} GB free; ${MIN_FREE_GB} GB is the recommended minimum"
  else
    block "only ${free_gb} GB is free; make at least ${MIN_FREE_GB} GB available"
  fi
else
  warn "free disk space could not be measured"
fi

if git -C "$ROOT" submodule status --recursive 2>/dev/null | grep -q '^-'; then
  warn "Git submodules are not initialized; the agent will initialize them after Continue"
else
  ok "pinned Git submodules are initialized"
fi

identity_count=0
if command -v security >/dev/null 2>&1; then
  identity_count="$(security find-identity -v -p codesigning 2>/dev/null | awk '/valid identities found/ {print $1}')"
  identity_count="${identity_count:-0}"
fi
if [[ "$identity_count" =~ ^[1-9][0-9]*$ ]]; then
  ok "an Apple code-signing identity is available (details intentionally hidden)"
else
  warn "no Apple signing identity was found; sign in under Xcode > Settings > Accounts"
fi

if command -v xcrun >/dev/null 2>&1 && xcrun devicectl list devices --help >/dev/null 2>&1; then
  device_table="$(xcrun devicectl list devices --hide-default-columns --columns Name State Model 2>/dev/null || true)"
  connected_ios="$(awk 'NR > 2 && ($0 ~ /iPhone/ || $0 ~ /iPad/) && $0 !~ /unavailable/ {count++} END {print count + 0}' <<<"$device_table")"
  if (( connected_ios > 0 )); then
    ok "${connected_ios} connected iPhone/iPad device(s) detected; identifiers intentionally hidden"
  else
    warn "no available iPhone or iPad is connected; plug it in, unlock it, and trust this Mac"
  fi
else
  warn "physical-device discovery is unavailable until Xcode setup is complete"
fi

info "a free Apple Account Personal Team works for personal testing but normally expires after 7 days"
info "full-speed play requires current StikDebug setup, a pairing file, Wi-Fi, and LocalDevVPN"
info "Codex Computer Use is optional for shell builds and recommended for Xcode/System Settings UI steps"
info "commercial games are never downloaded; import only a dump you legally own after installation"

printf '\nReadiness summary: %d blocker(s), %d warning(s)\n' "$blockers" "$warnings"
if (( blockers == 0 )); then
  printf 'READINESS: READY TO CONTINUE\n'
  exit 0
fi

printf 'READINESS: NEEDS ATTENTION\n'
exit 2
