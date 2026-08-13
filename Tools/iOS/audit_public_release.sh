#!/usr/bin/env bash
# Copyright 2026 DolphiniOS Project
# SPDX-License-Identifier: GPL-2.0-or-later

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

fail() {
  printf '[public audit] ERROR: %s\n' "$*" >&2
  exit 1
}

list_public_files() {
  {
    if git rev-parse --verify upstream/master >/dev/null 2>&1; then
      git diff --name-only --diff-filter=ACMR -z upstream/master...HEAD
    elif git rev-parse --verify HEAD^ >/dev/null 2>&1; then
      git diff --name-only --diff-filter=ACMR -z HEAD^...HEAD
    fi
    git diff --name-only --diff-filter=ACMR -z HEAD
    git ls-files --others --exclude-standard -z
  } | sort -zu
}

public_files="$(list_public_files | tr '\0' '\n')"

if grep -Eiq '(^|/)(\.build|Artifacts|build-[^/]*)/' <<<"$public_files"; then
  fail "a generated build or artifact directory contains tracked files"
fi

if grep -Eiq '\.(ipa|mobileprovision|mobiledevicepairing|p8|p12|cer|iso|gcm|rvz|wbfs|wia|gcz|raw|sav)$|(^|/)[Pp]airing[Ff]ile[^/]*\.plist$' <<<"$public_files"; then
  fail "a package, signing asset, game image, or save file is tracked"
fi

matches="$(
  list_public_files |
    xargs -0 grep -IEn \
    '(/Us[e]rs/[^ /]+/|-----BE[G]IN (RSA |EC |OPENSSH )?PRIVATE KEY|github_pat_[A-Za-z0-9_]+|ghp_[A-Za-z0-9]+|sk-[A-Za-z0-9]{20,}|00008[0-9A-F]{3}-[0-9A-F]{16}|DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*[A-Z0-9]{10})' \
    2>/dev/null || true
)"
if [[ -n "$matches" ]]; then
  printf '%s\n' "$matches" >&2
  fail "tracked text contains a local path, signing-team value, private credential, or device identifier"
fi

cmp -s AGENTS.md CLAUDE.md ||
  fail "AGENTS.md and CLAUDE.md must remain identical"

Tools/iOS/test_agent_contract.sh

for script in Tools/iOS/*.sh Source/iOS/App/Project/Scripts/BuildCore.sh; do
  bash -n "$script" || fail "shell syntax failed: $script"
done

git diff --check

printf '[public audit] PASS: no tracked packages, signing assets, pairing files, game images, saves, local paths, private-key markers, team IDs, or device IDs\n'
