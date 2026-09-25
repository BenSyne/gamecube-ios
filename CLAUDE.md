# GameCube on iOS agent instructions

## Trigger

Treat requests such as “Build GameCube,” “build console,” “get the emulator
running,” “install this on my iPhone/iPad,” or equivalent language as a request
to execute this repository’s iOS build workflow.

Use the two-phase conversation contract below. The initial trigger prepares the
user; a later “Let’s go,” “Continue,” “I’m ready,” or equivalent starts the
build. If the initial prompt explicitly says the checklist is already complete
and asks to build now, give the short readiness summary and proceed directly.

## Two-phase conversation contract

### Phase 1: readiness only

On the first trigger, run only read-only inspection, including:

```sh
Tools/iOS/readiness.sh
```

Do not install dependencies, initialize submodules, compile, sign, or change
system settings during Phase 1. The first response must clearly explain:

1. **What will happen:** this repository builds and sideloads a community
   Dolphin/DolphiniOS-based GameCube and Wii emulator. It is not an emulator
   written from scratch and it includes no commercial games.
2. **Required computer:** a local Mac with at least 20 GB free, internet access,
   Xcode, and an available iPhone or iPad simulator. Xcode 26.5 is validated;
   future Xcode releases may require build changes. Xcode must have been opened
   once and its license, first-launch setup, and iOS Simulator runtime
   installation completed. A cloud agent, Windows PC, or Linux machine cannot
   perform the Xcode/USB installation.
3. **Apple signing for device installation:** the user must sign their own
   Apple Account into `Xcode > Settings > Accounts`. A free Personal Team works
   for personal testing, but its app IDs, devices, and profiles normally expire
   after seven days. A paid account is optional for this personal build.
   Signing and provisioning must still be verified with this account and device.
   Never ask for the Apple Account password, recovery code, or session token.
4. **Physical-device preparation:** for installation, plug the target iPhone or
   iPad into the Mac, unlock it, tap Trust if asked, and enable Developer Mode
   under `Settings > Privacy & Security`. Tell the user a restart and passcode
   confirmation may be required.
5. **Codex preparation:** work in the local checkout with shell and workspace
   write access. For the smoothest Xcode and System Settings handoff, enable
   `Plugins > Computer Use`, turn on its server and skill, and grant macOS
   Screen Recording and Accessibility when prompted. Computer Use is optional
   for the shell build; without it, the agent must give precise manual UI steps.
   Chrome control is not required.
6. **Claude Code preparation:** a local shell in this checkout is sufficient.
   If graphical control is unavailable, the user will perform Xcode sign-in,
   device trust, Developer Mode, and on-device JIT taps while Claude runs the
   build commands.
7. **Full-speed requirement:** interpreter mode is only diagnostic. The
   documented StikDebug route supports iOS 17.4 or newer and requires a
   development-signed app with `get-task-allow`, a device pairing file, Wi-Fi,
   and a loopback VPN such as LocalDevVPN. The agent guides this after
   installation. Older iOS versions need another verified JIT method. Treat
   pairing files as sensitive and never open, print, copy, or commit them.
8. **Games:** no game is needed for the automated test. After installation the
   user may import only a dump or homebrew file they are legally allowed to use.

Report each detected item as ready, missing, or optional. For a physical-device
request, end Phase 1 with:

```text
When those items are ready, reply “Let’s go” or “Continue” and I’ll build and
test it, then sign, install, and launch it with your account and device. I’ll
report any step that still needs your help or verification.
```

For a simulator-only request, mark Apple signing, a physical device, Developer
Mode, and StikDebug/JIT as optional. End Phase 1 with:

```text
When the Mac and simulator are ready, reply “Let’s go” or “Continue” and I’ll
build and run the complete simulator smoke test.
```

### Phase 2: execute after confirmation

After the user confirms readiness, do not stop at a tutorial. Execute every
safe step available in the current environment. Keep the user informed during
long builds and pause only for an unavoidable sign-in, permission, device,
trust, passcode, Developer Mode, or on-device JIT interaction.

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
- Never display or persist Apple credentials, pairing-file contents, device
  UDIDs, developer-team IDs, provisioning profiles, or signing private keys.
  Local subprocesses may pass device/team identifiers directly to build or
  install tools without printing them. Do not run raw device or signing-identity
  listings into agent output or logs.
- Preserve GPL-2.0-or-later and all third-party license notices.
- Preserve unrelated work. Inspect `git status -sb` before editing or staging,
  and never reset or discard changes without explicit permission.

## Decide the requested outcome

During Phase 2, choose the narrowest mode that completes the user’s request:

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

For a simulator-only request, complete steps 1–4 and report the result; skip
device packaging, installation, and physical validation. For a physical-device
request, continue through the applicable later steps.

1. Re-run readiness and inspect without changing state:

   ```sh
   Tools/iOS/readiness.sh
   git status -sb
   git submodule status --recursive
   xcodebuild -version
   ```

   The readiness script summarizes simulator, device, and signing status without
   showing identifiers. If a simulator is missing, install an iOS Simulator
   runtime in Xcode Settings > Components and create an iPhone or iPad simulator
   in Xcode Window > Devices and Simulators before the smoke test.

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

5. Build the requested package. For a connected personal device, supply
   `TEAM_ID` and `ORG_ID` locally without printing their values and use the
   Apple-signed mode:

   ```sh
   Tools/iOS/bootstrap.sh --mode signed
   ```

   When the user chose a sideloading tool that performs its own signing, use
   unsigned mode instead:

   ```sh
   Tools/iOS/bootstrap.sh --mode unsigned
   ```

   For Xcode signing, discover the available team locally without printing it.
   If exactly one team is available, use it. If none exists, ask the user to
   sign into Xcode; if several exist, ask which team name to use without showing
   IDs. Use a unique reverse-DNS `ORG_ID` chosen or approved by the user. Never
   print or publish team identifiers. The August 2026 public refresh validated
   unsigned packaging but did not repeat the Personal Team signed path. The
   signed packaging script verifies the app signature and effective
   `get-task-allow` entitlement, failing when it is absent. This gate applies
   only to signed mode. Record signing or entitlement failure as such; do not
   weaken signing.

6. Install only when requested:

   - Prefer Xcode’s normal device flow for automatic signing.
   - The iPhone/iPad must be unlocked, trusted, and in Developer Mode.
   - A re-signable IPA must first be signed by the user’s chosen sideloading
     tool; an unsigned IPA cannot be installed directly. Re-signing may change
     entitlements. Verify the final app has `get-task-allow` when possible, or
     confirm actual StikDebug attachment before claiming JIT is ready.
   - Do not delete an existing app unless the user explicitly accepts the
     possible loss of its app-local data. Prefer an in-place update.
   - When one available iPhone/iPad is connected, install and launch the signed
     `.app` with `xcrun devicectl`. Keep its identifier in a local shell
     variable and do not print it. If several devices are available, ask the
     user to choose by model/name, not identifier.
   - If command-line signing or installation cannot complete, use Computer Use
     when available and authorized: open the Xcode project, select `DiOS (NJB)`,
     choose the user’s team and connected device, and run. Otherwise give the
     same exact clicks to the user.

7. Validate the physical device:

   - Launch to the Library.
   - Import an open-source homebrew file or a user-supplied legal dump.
   - Start the title and wait at the JIT screen.
   - Use the current [StikDebug instructions](https://github.com/StikDebug/StikDebug/blob/main/README.md)
     and [release](https://github.com/StikDebug/StikDebug/releases). StikDebug
     is no longer on the App Store. On iOS 17.4 or newer, create the pairing file
     with the device unlocked and trusted, enable LocalDevVPN on Wi-Fi, and ask
     the user to enable JIT for DolphiniOS while the waiting screen is open.
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
- Readiness diagnostic: `Tools/iOS/readiness.sh`
- Signed packaging: `Tools/iOS/package_ipa.sh`
- Unsigned packaging: `Tools/iOS/package_unsigned_ipa.sh`

## Done criteria

A build request is complete only when the requested artifact exists and the
relevant automated gates pass. A real-device request is complete only when the
app is installed and launched on that device, unless an unavoidable signing,
trust, unlock, Developer Mode, or JIT interaction is clearly identified.

Keep the final handoff concise and separate verified results from limitations.
