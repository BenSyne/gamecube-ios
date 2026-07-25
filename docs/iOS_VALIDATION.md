# Universal iPhone and iPad validation record

Validated July 13–25, 2026 against upstream base `7cac54161659` with Xcode
26.5. This record distinguishes automated simulator coverage from observed
physical-device behavior; it is not a universal game compatibility claim.

## Automated gates passed

- Signed Debug builds on iPad Pro 13-inch (M5) and iPhone 17 Pro iOS 26.5
  simulators.
- Generic arm64 Debug and optimized Release device builds.
- `DOLAppVersionTests`: 22 passed, 0 failed.
- Clean-install smoke test: document-URL import, byte-identical library copy,
  Library refresh, open-source homebrew launch, Metal output, touch overlay,
  pixel-identical paused frames, save-state creation/load, confirmed stop, JIT
  gate/cancel, and Low Power/thermal preflight/cancel.
- iPhone compact layout in portrait, landscape left, and landscape right.
- Live rotation with active Metal output and touch controls.
- Release privacy inspection: no Firebase, Crashlytics, Google service
  configuration, analytics upload hook, provisioning profile, or game image.
- Project/plist lint, shell syntax, `git diff --check`, archive integrity, and
  recursive submodule cleanliness.

The automated test downloads a pinned open-source Wii-donut DOL fixture and
checks its SHA-256 before use. It does not download or require a commercial
game.

## Physical devices passed

### iPhone 17 Pro

- Signed sideload installation and clean launch.
- Files import and persistent Library entry.
- StikDebug JIT attachment followed by performant GameCube execution.
- Metal output, audio, touch input, pause/resume, and clean stop.
- Portrait plus both landscape directions, including rotation during
  emulation.
- Safe-area-correct emulation menu and touch overlay.

### iPad Pro 13-inch (M5), iPadOS 26.5.2

- Signed sideload installation and clean launch.
- LocalDevVPN/StikDebug pairing and successful JIT attachment.
- Legal RVZ import, Library indexing, and GameCube boot.
- Metal, fastmem/arena allocation, DSP thread, and shader cache paths observed
  in the running device log.
- Landscape presentation and persistent in-game memory-card directory.

The tested retail scenes ran smoothly after JIT attachment. That establishes
the device/JIT/rendering path for those tests only; performance and
compatibility still vary by game, settings, device temperature, and iOS
version.

## Simulator-only retail diagnostic

An authorized GameCube dump booted through its publisher and studio branding
in the optimized Release simulator build. The simulator initially sustained
approximately 60 VPS before a transition collapsed to approximately 0.3 VPS.
Release optimization, JIT, dual core, Metal/Vulkan, asynchronous/hybrid
ubershaders, EFB access, disc speed, and idle-loop settings did not remove that
simulator-specific stall.

Simulator Metal capability detection now avoids unsupported dual-source
blending and framebuffer fetch. The real-device Metal path retains those
features. Physical-device JIT testing—not simulator retail performance—is the
meaningful performance gate.

## Packaging

`Tools/iOS/package_unsigned_ipa.sh` produces an arm64, iPhone-and-iPad IPA with
portrait and both iPhone landscape orientations. It removes stale signatures
and provisioning profiles and rejects bundled game images.

`Tools/iOS/package_ipa.sh` performs the same structural checks after Xcode
automatic signing. Build artifacts and their hashes are intentionally not
committed; every public build should publish its own SHA-256.

## Remaining compatibility gates

Complete the physical matrix in [iOS_TEST_MATRIX.md](iOS_TEST_MATRIX.md) for
each intended device/game/controller combination. In particular:

- Long-duration thermal and battery behavior.
- Bluetooth latency, analog-trigger mapping, rumble, and reconnect.
- Speakers, headphones, Bluetooth audio, and interruption handling.
- External-display timing and disconnect recovery.
- Broader GameCube and Wii compatibility.
- Backup/restore and update testing across future core revisions.

The compiler emits upstream/Xcode maintenance warnings for run-script phases
without declared outputs, skipped AppIntents extraction, and a Swift test
target that imports an executable module with an Objective-C bridging header.
No warning observed in this validation represented a Release runtime failure.
