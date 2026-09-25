# DolphiniOS iPhone and iPad consumption guide

This branch is a sideloadable iPhone and iPad build of DolphiniOS. It does not contain games, Nintendo system software, encryption keys, or copyrighted cover art. Use only disc images and firmware that you are legally permitted to use.

Codex reads `AGENTS.md` and Claude Code reads `CLAUDE.md`. In either agent, the
prompt `Build me a GameCube` starts a read-only readiness check. The agent first
explains the Mac, Xcode, Apple signing, device, Computer Use, and JIT
requirements. Reply `Let's go` or `Continue` to authorize dependency setup,
builds, tests, signing, and installation. The commands below provide the same
manual path. For a simulator-only proof, Apple signing, a physical device,
Developer Mode, and JIT can be deferred.

## What is ready

- Native, adaptive iPhone/iPad library with compact and regular card layouts, pull-to-refresh, empty-state onboarding, Files import, and VoiceOver labels.
- Metal rendering, touchscreen GameCube/Wii profiles, Apple Game Controller support, external-display scenes, memory cards, Wii NAND saves, and save states inherited from DolphiniOS/Dolphin.
- First-run defaults tuned for current iPhone and iPad hardware: Metal, shader cache, and asynchronous specialized-shader compilation to reduce first-use stalls without depending on unsupported Metal ubershader paths. Fastmem is enabled only when the runtime reports it is available.
- Portrait and both landscape orientations, including live rotation during emulation, with a minimum 44-point emulation-menu target and safe-area-aware touch controls.
- A launch preflight warns when Low Power Mode or serious thermal pressure is likely to cause unstable emulation, with explicit options to continue or return to the Library.
- A current JIT gate that detects attachment and links to the official StikDebug setup guide.
- No Firebase analytics, crash reporting, service configuration, or upload hook in the personal build.
- Repeatable ad hoc-signed simulator and unsigned-device builds, plus an end-to-end open-source homebrew smoke test.

## Requirements

- A local Mac with at least 20 GB free, Xcode (26.5 is validated), and an installed
  iOS simulator runtime. Open Xcode once and complete first-launch setup.
- Homebrew packages: `cmake`, `ninja`, and `bartycrouch`.
- For installation on an iPhone or iPad: an Apple Account signed into Xcode and
  a unique reverse-DNS organization identifier, or a sideloading tool that
  re-signs the unsigned IPA. A free Personal Team works for personal testing
  but normally requires reinstalling after seven days; a paid membership is
  optional.
- The app's deployment target starts at iOS 14 on A9 hardware; a device with at
  least 4 GB RAM is strongly recommended. The full-speed StikDebug procedure
  documented here supports iOS 17.4 or newer. Older iOS versions need a
  separately verified JIT method before playable performance can be promised.

Inspect readiness without changing the Mac:

```sh
Tools/iOS/readiness.sh
```

For graphical Xcode/System Settings steps in Codex Desktop, Computer Use is
optional but convenient. Enable its plugin, server, and skill, then grant macOS
Screen Recording and Accessibility. A shell-only agent can still build and
package everything while the user performs required Apple UI confirmations.

Initialize dependencies after cloning:

```sh
Tools/iOS/bootstrap.sh --mode check --install
```

## Test on the simulator

The smoke script builds the app and performs a clean install. It opens the pinned Wii-donut binary through the registered iOS document URL flow, verifies the accessible Copy/Move/Cancel prompt, confirms a byte-identical library copy, and launches it. It then proves that pause freezes rendered output pixel-for-pixel, creates and loads save-state slot 1, stops emulation, verifies the Library returns, exercises the JIT gate and Low Power/thermal preflight through Debug-only simulator hooks, verifies both cancel paths, and saves screenshots, hashes, and logs under `Artifacts/SmokeTest`.

The tap stage uses Facebook's `idb` because `simctl` does not provide touch injection:

```sh
Tools/iOS/bootstrap.sh --mode simulator --install
```

Set `SMOKE_UDID=<simulator-uuid>` to select a particular iPhone or iPad simulator. Set `SMOKE_SKIP_BUILD=1` to reuse an existing build.

For determinism, the default run uninstalls the Debug simulator bundle and therefore resets that bundle's simulator-only data. Set `SMOKE_PRESERVE_DATA=1` to preserve unrelated data; the named smoke fixture and its slot-1 state are still replaced.

## Build a signed IPA

Sign into your Apple ID in Xcode first, then run:

```sh
TEAM_ID=ABCDEFGHIJ \
ORG_ID=com.yourname \
Tools/iOS/package_ipa.sh
```

The output is `Artifacts/Release/DolphiniOS.ipa`. The script requests automatic
signing, checks the signature and its effective `get-task-allow` entitlement,
and prints a SHA-256 digest. StikDebug needs an Apple development signing
profile; the script rejects a signature without that entitlement. Signing
depends on the Apple account, provisioning profile, and connected device. The
September 2026 public-source refresh validated the simulator and unsigned
package; it did not re-run signed packaging on a fresh Personal Team. Verify installation and
launch on your device, then confirm StikDebug attaches before relying on JIT.
A free developer account generally requires re-signing or reinstalling every
seven days; paid-account profiles normally last longer. Apple can change these
policies.

You may instead edit `Source/iOS/App/Project/Config/DevelopmentTeam.xcconfig` and `BundleIdentifier.xcconfig`, open `Source/iOS/App/DolphiniOS.xcodeproj`, select the `DiOS (NJB)` scheme, and run on the connected iPhone or iPad.

If your sideloading tool performs its own signing, create a clean unsigned Release IPA instead:

```sh
Tools/iOS/bootstrap.sh --mode unsigned
```

The output is `Artifacts/Release/DolphiniOS-unsigned.ipa`. It is not directly installable: SideStore, AltStore, or another trusted signing tool must re-sign it with your Apple account and replace the placeholder bundle identifier as needed. The script prints the artifact's SHA-256 digest. Re-signing can change entitlements; see the JIT check below.

## Install and enable JIT

Install the IPA with SideStore, AltStore Classic, Xcode, or another signing tool you trust. AltStore PAL is not suitable for this build.

Full-speed emulation requires JIT on a non-jailbroken iPhone or iPad. The
documented StikDebug procedure supports iOS 17.4 or newer. Install the current
[StikDebug release](https://github.com/StikDebug/StikDebug/releases),
create a pairing file with the device unlocked and trusted, connect to Wi-Fi,
enable LocalDevVPN, start a game in DolphiniOS, and enable JIT for DolphiniOS
while the waiting screen is open. The game starts automatically when attachment
is detected. StikDebug is no longer distributed through the App Store. Current
steps live in the [StikDebug README](https://github.com/StikDebug/StikDebug/blob/main/README.md).
StikDebug requires `get-task-allow` on the final installed app. The signed
packaging script checks its own artifact without displaying signing identifiers;
a sideloading tool's re-signing must be checked on the final app, or proven by
successful StikDebug attachment before claiming JIT is ready.

The pairing file is device-specific authorization material. Do not upload it,
send it to an agent, paste its contents into chat, or commit it.

“Continue Without JIT” is a troubleshooting path, not a playable-performance mode. On iOS 26 devices that use TXM, use StikDebug specifically; a generic debugger attachment can still crash when the core starts.

## Add games

Tap `+` or the empty-state `Import a Game` button and choose a legal dump in Files. You can also place files in `On My iPhone/iPad → DolphiniOS → Software` and pull to refresh.

RVZ is recommended for normal use because it reduces storage without the compatibility compromises of NKit. ISO/GCM, GCZ, WIA, RVZ, DOL, and ELF are supported by the importer. Homebrew DOL/ELF files may not provide cover metadata.

## Controls and saves

- Touch controls are configured on first launch. Adjust opacity, scale, IR mode, and mappings under `Settings → Controllers`.
- Pair an Xbox, PlayStation, Switch-compatible, or MFi controller in iOS Bluetooth settings before opening the app. Then select it and map ports under `Settings → Controllers`.
- In-game memory-card and Wii NAND saves live in the app's `User` directory. Save states live under `User/StateSaves` and are not guaranteed to survive core-version changes.
- Back up the entire DolphiniOS folder from Files before updating. Prefer an in-game save before moving between builds.

## Performance baseline

Start with the defaults. If a game cannot sustain full speed:

1. Keep Metal selected and internal resolution at 1x.
2. Turn off enhancements such as anti-aliasing and high anisotropy.
3. Verify Low Power Mode is off and the device is not thermally throttled.
4. If audio crackles or frame time spikes on this core, test `Settings → Config → General → Enable Dual Core` both on and off; compatibility is game/device specific.
5. Change one setting at a time and use the same gameplay scene for comparison.

If the launch preflight appears, turning off Low Power Mode and allowing a hot device to cool is the reliable choice. `Continue Anyway` is available for intentional testing, but does not bypass iOS power or thermal limits.

## Licensing and redistribution

Dolphin/DolphiniOS is GPL-2.0-or-later. This repository contains the corresponding source and license notices for the build. If you distribute an IPA, distribute the exact corresponding source (including these modifications and submodule revisions), preserve copyright/license notices, and comply with third-party licenses under `Externals` and `LICENSES`. Do not bundle commercial games, keys, BIOS/IPL images, or Nintendo artwork.

## Acceptance boundary

The automated simulator test proves build integrity, Library import, app
navigation, core startup, visible emulator output, touch controls, pause, save states, and
adaptive portrait/landscape layout. Physical iPhone and iPad testing has also
proved sideload installation, StikDebug JIT attachment, legal game import, and
performant execution on the devices recorded in
[iOS_VALIDATION.md](iOS_VALIDATION.md).

Neither result proves universal compatibility. Bluetooth latency, physical
audio routes, external displays, thermals, battery drain, and each
device/game/settings combination still require the applicable rows in
[iOS_TEST_MATRIX.md](iOS_TEST_MATRIX.md).
