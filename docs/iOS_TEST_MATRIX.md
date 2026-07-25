# iPhone and iPad release test matrix

Record the iPhone/iPad model, chip, RAM, iOS version, build commit, IPA SHA-256, signing method, controller firmware, display mode, and whether Low Power Mode is enabled. Use legal dumps only; record each dump's hash so results can be reproduced.

## Recorded device baseline

| Device | OS | Verified |
| --- | --- | --- |
| iPhone 17 Pro | iOS 26 | Signed sideload, Files import, StikDebug JIT, Metal output, audio, touch input, pause/resume, clean stop, portrait, landscape left/right, and live rotation |
| iPad Pro 13-inch (M5) | iPadOS 26.5.2 | Signed sideload, LocalDevVPN/StikDebug pairing, JIT attachment, RVZ import, GameCube boot, Metal, fastmem, DSP thread, shader cache, landscape, and memory-card creation |

See [iOS_VALIDATION.md](iOS_VALIDATION.md) for the evidence boundary and
remaining limitations.

## Automated gates

| Gate | Expected result |
| --- | --- |
| Signed simulator Debug build | `BUILD SUCCEEDED`; app signature validates locally |
| Generic iOS arm64 build | `BUILD SUCCEEDED`; Mach-O reports arm64 |
| Unsigned IPA packaging | Payload contains the optimized arm64 app, no stale signature/profile, and has a recorded SHA-256 |
| Unit tests | All `DolphiniOSTests` pass on an iOS simulator |
| Library empty state | Import CTA, legal note, and pull-to-refresh work in portrait and landscape |
| Document import | Registered file URL presents Copy/Move/Cancel; Copy is byte-identical and refreshes the Library |
| Open-source homebrew smoke | Pinned Wii-donut DOL appears in Library, launches, renders through Metal, and shows the touch overlay |
| Pause lifecycle | Two screenshots taken two seconds apart while paused decode to identical pixels |
| Save-state lifecycle | Slot 1 is created with a nonzero size and SHA-256, loads without exit, and survives the return to Library |
| Stop lifecycle | Confirmed stop ends the core session, keeps the app alive, and restores the Library tab |
| JIT-gate UI | Debug-only simulator hook presents current StikDebug guidance, exposes all actions to accessibility, and `Back to Library` cancels cleanly |
| Performance preflight | Debug-only simulator hook presents the Low Power/thermal warning, exposes both actions to accessibility, and `Back to Library` cancels cleanly |
| Clean launch log | No app crash, assertion, or uncaught exception during the smoke run |
| Compact iPhone layout | iPhone 17 Pro Library and emulation views fit portrait and both landscape directions without clipping or safe-area overlap |
| Live rotation | Active Metal rendering and touch controls survive portrait → landscape → portrait and the opposite landscape direction |
| Landscape controls | Emulation menu opens in both landscape directions and pause produces pixel-identical frames |

## Physical iPhone/iPad gates

Mark each row Pass, Fail, or Not Tested and attach notes/screenshots.

| Area | Procedure | Acceptance |
| --- | --- | --- |
| Install/update | Install signed IPA, then install a newer build over it | App opens; library, settings, and saves remain |
| JIT | Launch a game, enable with StikDebug, repeat after force-quit | JIT is detected every time; no TXM crash |
| Import | Import one RVZ and one ISO from Files; relaunch and pull to refresh | Both persist once, with correct metadata |
| Touch | Play 15 minutes in portrait and landscape; test multi-touch and IR | No stuck inputs; layout stays inside safe areas |
| Controller | Pair controller; test every GC button, both sticks, analog triggers, rumble, disconnect/reconnect | Correct mapping, no stuck state, reconnect works |
| In-game save | Create a memory-card save, quit cleanly, relaunch | Save loads and checksum remains valid |
| Save state | Save/load all exposed slots, then test after cold launch | Same-build states restore; failures are surfaced safely |
| Audio | Test speakers, headphones, mute, volume, interruption, and route change | No crash; audio resumes without persistent distortion |
| Lifecycle | Lock/unlock, background/foreground, Control Center, incoming audio interruption | Emulation pauses/resumes predictably; no lost save |
| External display | Connect HDMI/USB-C display, start and stop a game, disconnect while running | Correct target display and recovery to the device |
| Performance | 30 minutes each in three representative games | Full-speed target is sustained without runaway frame-time spikes |
| Power/thermal preflight | Enable Low Power Mode, then repeat while the device reports serious thermal pressure | Warning appears before core startup; both Continue and Back actions work |
| Thermals/battery | Run a demanding game for 60 minutes unplugged | Record average FPS, 1% low, temperature state, and battery delta; no thermal shutdown |
| Accessibility | VoiceOver Library/import/settings; largest text size; Reduce Motion | Controls have useful names and remain operable |
| Storage | Fill device near capacity, import a large image, create a save state | Clear error, no corrupt partial library/save entry |
| Backup/restore | Copy DolphiniOS folder out via Files, reinstall, copy it back | Library and in-game saves restore |

## Compatibility sample

Use at least three personally dumped retail titles that cover different engines and workloads. A useful sample includes a lightweight 60 fps title, a shader-heavy title, and a title with demanding audio/CPU behavior. Do not publish or commit the images.

For every failure, capture the exact settings, reproduction steps, app log, screenshot/video, and whether the same dump works in desktop Dolphin. Never treat one successful homebrew launch as proof of broad GameCube compatibility.
