#!/usr/bin/env bash
# Copyright 2026 DolphiniOS Project
# SPDX-License-Identifier: GPL-2.0-or-later

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

fail() {
  printf '[agent contract] ERROR: %s\n' "$*" >&2
  exit 1
}

cmp -s AGENTS.md CLAUDE.md || fail "AGENTS.md and CLAUDE.md differ"
[[ -x Tools/iOS/readiness.sh ]] || fail "readiness.sh is not executable"

required_instruction_text=(
  "Build GameCube"
  "Phase 1: readiness only"
  "Phase 2: execute after confirmation"
  "Tools/iOS/readiness.sh"
  "Let’s go"
  "Computer Use"
  "Chrome control is not required"
  "StikDebug"
  "LocalDevVPN"
  "never open, print, copy, or commit"
)

for text in "${required_instruction_text[@]}"; do
  grep -Fq "$text" AGENTS.md || fail "missing instruction: $text"
done

grep -Fq "Build me a GameCube." Readme.md || fail "README is missing the public trigger"
grep -Fq "READINESS: READY TO CONTINUE" Tools/iOS/readiness.sh ||
  fail "readiness script is missing its success contract"
grep -Fq "Do not install dependencies" AGENTS.md ||
  fail "Phase 1 mutation guard is missing"

printf '[agent contract] PASS: Codex/Claude onboarding and execution contract is complete\n'
