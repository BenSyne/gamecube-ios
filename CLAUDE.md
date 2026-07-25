# GameCube on iOS agent instructions

## Trigger

Treat requests such as “Build GameCube,” “build console,” “get the emulator
running,” “install this on my iPhone/iPad,” or equivalent language as a request
to execute this repository’s iOS build workflow.

Do not stop after explaining commands when the user asked to build, test,
package, install, or run the app. Execute every safe step available in the
current environment and pause only for a genuinely unavoidable user action.

## Non-negotiable rules

- Never download, request, commit, upload, or distribute commercial ROMs,
  Nintendo system software, encryption keys, BIOS/IPL dumps, or copyrighted
  cover art.
- Use the pinned open-source Wii-donut fixture in the smoke script for
  automated validation. A user may separately import a dump they legally own.
- Never commit Apple certificates, private keys, provisioning profiles, device
  UDIDs, developer-team IDs, Apple IDs, local absolute paths, build products,
  save data, or user game files.
- Do not weaken code signing, iOS security controls, or device trust. Use
  Xcode automatic signing or a sideloading tool chosen by the user.
- Preserve GPL-2.0-or-later and all third-party license notices.
- Preserve unrelated work. Inspect `git status -sb` before editing or staging,
  and never reset or discard changes without explicit permission.

## Decide the requested outcome

Choose the narrowest mode that completes the user’s request:

- Environment check: `Tools/iOS/bootstrap.sh --mode check`
- Complete simulator proof: `Tools/iOS/bootstrap.sh --mode simulator`
- Re-signable IPA: `Tools/iOS/bootstrap.sh --mode unsigned`
- Apple-signed IPA: `TEAM_ID=… ORG_ID=… Tools/iOS/bootstrap.sh --mode signed`

Add `--install` only when the user asked for setup/build completion and
Homebrew dependencies are missing. Do not install unrelated software.

If the target is unclear but a physical iPhone/iPad is connected, prefer a
real-device build after the simulator proof. Otherwise complete the simulator
proof and unsigned package.

## Workflow

1. Inspect without changing state:

   ```sh
   git status -sb
   git submodule status --recursive
   xcodebuild -version
   xcrun simctl list devices available
   xcrun devicectl list devices
   security find-identity -v -p codesigning
   ```

2. Validate and initialize:

   ```sh
   Tools/iOS/bootstrap.sh --mode check --install
   ```

3. Prove the app in a simulator:

   ```sh
   Tools/iOS/bootstrap.sh --mode simulator --install
   ```

   Do not call the build healthy unless the smoke script completes its import,
   Metal render, pause, save/load, stop, JIT-gate, and performance-warning
   checks.

4. Audit the public source boundary:

   ```sh
   Tools/iOS/audit_public_release.sh
   ```

   This gate must pass before committing, pushing, or publishing a release.

5. Build the requested package:

   ```sh
   Tools/iOS/bootstrap.sh --mode unsigned
   ```

   For Xcode signing, obtain `TEAM_ID` and `ORG_ID` from the user’s existing
   local Xcode configuration or ask the user to choose them. Do not print or
   publish those values.

6. Install only when requested:

   - Prefer Xcode’s normal device flow for automatic signing.
   - The iPhone/iPad must be unlocked, trusted, and in Developer Mode.
   - A re-signable IPA must first be signed by the user’s chosen sideloading
     tool; an unsigned IPA cannot be installed directly.
   - Do not delete an existing app unless the user explicitly accepts the
     possible loss of its app-local data. Prefer an in-place update.

7. Validate the physical device:

   - Launch to the Library.
   - Import an open-source homebrew file or a user-supplied legal dump.
   - Start the title and wait at the JIT screen.
   - Ask the user to enable JIT with StikDebug when attachment requires their
     interaction.
   - Confirm Metal output, audio, touch controls, portrait, both landscape
     directions, pause/resume, clean stop, and persistence of an in-game save.
   - Test a paired controller when one is available.

8. Report exact evidence:

   - Commit/build revision.
   - Xcode version and target model, without UDID.
   - Build/test commands and pass/fail results.
   - IPA path and SHA-256 when packaged.
   - Signing/JIT method and any user action still required.
   - Known limitations. Never generalize one tested game into universal
     compatibility.

## Useful project paths

- Xcode project: `Source/iOS/App/DolphiniOS.xcodeproj`
- Scheme: `DiOS (NJB)`
- Detailed guide: `docs/iOS_CONSUMPTION.md`
- Validation evidence: `docs/iOS_VALIDATION.md`
- Physical test matrix: `docs/iOS_TEST_MATRIX.md`
- Simulator smoke: `Tools/iOS/build_and_smoke_test.sh`
- Signed packaging: `Tools/iOS/package_ipa.sh`
- Unsigned packaging: `Tools/iOS/package_unsigned_ipa.sh`

## Done criteria

A build request is complete only when the requested artifact exists and the
relevant automated gates pass. A real-device request is complete only when the
app is installed and launched on that device, unless an unavoidable signing,
trust, unlock, Developer Mode, or JIT interaction is clearly identified.

Keep the final handoff concise and separate verified results from limitations.
