#!/usr/bin/env bash
# Copyright 2026 DolphiniOS Project
# SPDX-License-Identifier: GPL-2.0-or-later

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PUBLIC_BASE_REV="${PUBLIC_BASE_REV:-7cac54161659421ed95c2cd1c0b0746539a4cd38}"
cd "$ROOT"

fail() {
  printf '[public audit] ERROR: %s\n' "$*" >&2
  exit 1
}

list_current_files() {
  {
    git ls-files -z
    git ls-files --others --exclude-standard -z
  } | sort -zu | while IFS= read -r -d '' path; do
    # A deleted file is still in the index until its deletion is staged.
    if [[ -e "$path" || -L "$path" ]]; then
      printf '%s\0' "$path"
    fi
  done
}

list_changed_files() {
  {
    if git cat-file -e "$PUBLIC_BASE_REV^{commit}" 2>/dev/null; then
      git diff --name-only --diff-filter=ACMR -z "$PUBLIC_BASE_REV...HEAD"
    elif git rev-parse --verify upstream/master >/dev/null 2>&1; then
      git diff --name-only --diff-filter=ACMR -z upstream/master...HEAD
    elif git rev-parse --verify HEAD^ >/dev/null 2>&1; then
      git diff --name-only --diff-filter=ACMR -z HEAD^...HEAD
    fi
    git diff --name-only --diff-filter=ACMR -z HEAD
    git ls-files --others --exclude-standard -z
  } | sort -zu
}

# Source archives are allowed, but their entries must not contain game images.
# macOS ships bsdtar, which can list ZIP, 7z, RAR, and tar archives without
# extracting their contents.
check_archive() {
  local archive="$1" listing
  [[ -f "$archive" ]] || return 0

  listing="$(bsdtar -tf "$archive" 2>/dev/null)" ||
    fail "a changed archive could not be inspected"
  if grep -Eiq '\.(iso|gcm|ciso|rvz|wbfs|wad|wia|gcz|nkit|dol|sav|raw)$' <<<"$listing"; then
    fail "a changed archive contains a game image or save file"
  fi
}

shopt -s nocasematch
reject_public_path() {
  local path="$1"
  case "$path" in
    .build/*|Artifacts/*|build-*/*|Build*/*|Binary*/*|obj/*)
      fail "a generated build or artifact directory contains public files" ;;
    *.ipa|*.mobileprovision|*.mobiledevicepairing|*.p8|*.p12|*.cer|*.iso|*.gcm|*.ciso|*.rvz|*.wbfs|*.wad|*.wia|*.gcz|*.dol|*.raw|*.sav|*/PairingFile*.plist|PairingFile*.plist)
      fail "a package, signing asset, pairing file, game image, or save file is public" ;;
    */GoogleService-Info.plist|GoogleService-Info.plist)
      fail "a Google service configuration is public" ;;
  esac
}

while IFS= read -r -d '' path; do
  reject_public_path "$path"
  if [[ -L "$path" ]]; then
    fail "a symlink is public"
  fi
done < <(list_current_files)

while IFS= read -r -d '' path; do
  case "$path" in
    *.zip|*.7z|*.rar|*.tar|*.tgz|*.tar.gz|*.tar.xz|*.tar.zst)
      check_archive "$path" ;;
  esac
done < <(list_changed_files)

# These four unchanged upstream source fixtures contain literal private-key
# markers for parsers and tests. Any local modification removes the exemption.
is_unchanged_upstream_fixture() {
  local path="$1"
  case "$path" in
    Externals/imgui/imgui.cpp|Externals/mbedtls/library/certs.c|Externals/mbedtls/library/pkparse.c|Externals/mbedtls/library/pkwrite.c)
      git cat-file -e "$PUBLIC_BASE_REV:$path" 2>/dev/null &&
        git show "$PUBLIC_BASE_REV:$path" 2>/dev/null | cmp -s - "$path" ;;
    *) return 1 ;;
  esac
}

secret_pattern='(/Us[e]rs/[^ /]+/|-----BE[G]IN (RSA |EC |OPENSSH )?PRIVATE KEY|github_pat_[A-Za-z0-9_]+|ghp_[A-Za-z0-9]+|sk-[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{30,}|00008[0-9A-F]{3}-[0-9A-F]{16}|DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*[A-Z0-9]{10})'
while IFS= read -r -d '' path; do
  [[ -f "$path" ]] || continue
  if is_unchanged_upstream_fixture "$path"; then
    continue
  fi
  if grep -IEq -- "$secret_pattern" "$path" 2>/dev/null; then
    fail "public text contains a local path, credential, signing-team value, or device identifier"
  else
    grep_status=$?
    [[ "$grep_status" -eq 1 ]] || fail "a public file could not be scanned"
  fi
done < <(list_current_files)

# A secret added in a fork commit remains public even if a later commit deletes
# it. Inspect additions in every reachable fork commit without echoing content.
if git cat-file -e "$PUBLIC_BASE_REV^{commit}" 2>/dev/null; then
  while IFS= read -r commit; do
    while IFS= read -r -d '' path; do
      reject_public_path "$path"
    done < <(git diff --name-only --diff-filter=ACMR -z "$commit^" "$commit")
    if git diff --no-ext-diff --unified=0 "$commit^" "$commit" |
      awk '/^\+\+\+ / { next } /^\+/ { print substr($0, 2) }' |
      grep -E "$secret_pattern" >/dev/null; then
      fail "a reachable fork commit added sensitive text"
    fi
  done < <(git rev-list --reverse "$PUBLIC_BASE_REV..HEAD")
fi

cmp -s AGENTS.md CLAUDE.md ||
  fail "AGENTS.md and CLAUDE.md must remain identical"

Tools/iOS/test_agent_contract.sh

for script in Tools/iOS/*.sh Source/iOS/App/Project/Scripts/BuildCore.sh; do
  bash -n "$script" >/dev/null 2>&1 || fail "shell syntax failed"
done

git diff --check >/dev/null 2>&1 || fail "whitespace errors are present"

printf '[public audit] PASS: current source and fork commits pass file, archive, and text checks\n'
