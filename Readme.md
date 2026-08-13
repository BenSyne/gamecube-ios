# Build Me a GameCube — iPhone and iPad

[![License: GPL-2.0+](https://img.shields.io/badge/license-GPL--2.0%2B-5e6ad2.svg)](COPYING)
[![Platform](https://img.shields.io/badge/platform-iPhone%20%7C%20iPad-111111.svg)](docs/iOS_CONSUMPTION.md)
[![Xcode](https://img.shields.io/badge/validated-Xcode%2026.5-147efb.svg)](docs/iOS_VALIDATION.md)

Clone the repo, open it in Codex or Claude Code, and say:

```text
Build me a GameCube.
```

The agent checks your Mac, gives you one honest preparation list, waits for
`Let's go`, and then builds, tests, signs, installs, and launches a performant
GameCube/Wii emulator on your own iPhone or iPad.

Under the hood, this is a tested community performance build of the open-source
Dolphin/DolphiniOS codebase. It adds a cleaner mobile library, reliable Files
import, current-device build fixes, landscape support, JIT guidance,
privacy-first defaults, and repeatable end-to-end tests.

> This repository does not contain games, encryption keys, Nintendo system
> software, or copyrighted cover art. Use only software you own or are legally
> permitted to use.

## The one-prompt path

### 1. Clone it on a Mac

```sh
git clone --recursive https://github.com/BenSyne/gamecube-ios.git
cd gamecube-ios
```

### 2. Open this folder in your local agent

Codex automatically reads [`AGENTS.md`](AGENTS.md). Claude Code reads
[`CLAUDE.md`](CLAUDE.md). The two files contain the same guarded build
playbook.

### 3. Ask for the build

```text
Build me a GameCube.
```

The first response is deliberately a readiness check, not a surprise hour-long
build. It detects what is already ready and explains anything you still need:

- a local Mac with roughly 20 GB free and Xcode (26.5 is validated);
- an Apple Account signed into Xcode;
- an unlocked, trusted iPhone/iPad with Developer Mode enabled;
- optional Codex Computer Use access for Xcode/System Settings clicks;
- the later StikDebug + LocalDevVPN setup required for full-speed JIT.

When the checklist is green, reply:

```text
Let's go.
```

The agent then owns the build loop: dependencies, submodules, simulator proof,
privacy audit, signing, installation, launch, and device validation. It pauses
only when Apple requires you to sign in, approve trust, enter a passcode, enable
Developer Mode, or tap the on-device JIT control.

For a simulator-only proof, ask:

```text
Build GameCube and run the full simulator smoke test.
```

## What to prepare

| Item | What you need |
| --- | --- |
| Mac | Local macOS machine; USB/device installation cannot run from a cloud agent |
| Xcode | Xcode 26.5 is validated; open it once and finish first-launch setup |
| Disk | 20 GB free is recommended for source, submodules, dependencies, and derived data |
| Apple signing | A free Apple Account Personal Team works for personal testing; Apple normally expires its profiles after 7 days. A paid membership is optional |
| iPhone/iPad | Plugged in, unlocked, trusted, and in Developer Mode |
| Network | Internet for submodules and pinned build/test dependencies; Wi-Fi for the current on-device JIT flow |
| Games | None for testing. Later, use only homebrew or a dump you legally own |

Apple documents free Personal Team device testing and its seven-day limits in
[Developer Account Help](https://developer.apple.com/help/account/basics/about-your-developer-account).

### Codex Desktop setup

The shell build only needs a local checkout with shell and workspace write
access. For the smoothest graphical handoff:

1. Open `Plugins > Computer Use` in Codex.
2. Install or enable the plugin, then turn on its server and skill.
3. Grant Screen Recording and Accessibility when macOS prompts.
4. Allow Xcode or System Settings only when the task actually needs them.

Computer Use is optional. Without it, Codex still performs the build and gives
you the exact Xcode/device clicks. Chrome control is not required. See the
[official Computer Use setup](https://learn.chatgpt.com/docs/computer-use).

### Claude Code setup

Open Claude Code locally in the cloned directory with normal shell and file
access. No Codex plugin is required. If Claude cannot operate graphical apps,
you perform the small Xcode, trust, Developer Mode, and StikDebug interactions
while it performs the reproducible shell workflow.

## Manual quick start

Requirements:

- A Mac with Xcode. Xcode 26.5 is the validated configuration.
- Homebrew.
- An iPhone or iPad for real GameCube performance.
- Your own Apple signing identity, or a trusted sideloading tool.

See exactly what is ready without changing the Mac:

```sh
Tools/iOS/readiness.sh
```

Validate the toolchain and initialize dependencies:

```sh
Tools/iOS/bootstrap.sh --mode check --install
```

Run the complete open-source homebrew simulator test:

```sh
Tools/iOS/bootstrap.sh --mode simulator --install
```

Build an IPA for a sideloading tool to re-sign:

```sh
Tools/iOS/bootstrap.sh --mode unsigned
```

Or build with your Apple Developer team:

```sh
TEAM_ID=ABCDEFGHIJ ORG_ID=com.yourname \
  Tools/iOS/bootstrap.sh --mode signed
```

Outputs are written beneath `Artifacts/`, which is intentionally excluded from
Git.

Before publishing any change:

```sh
Tools/iOS/audit_public_release.sh
```

## What this build adds

- Adaptive iPhone/iPad game library, empty-state onboarding, pull-to-refresh,
  accessible labels, and direct Files import.
- Portrait plus both landscape orientations, including live rotation while a
  game is running.
- Metal capability fixes for current Xcode simulators without weakening the
  real-device Metal path.
- First-run performance defaults for shader compilation and caching.
- A clear JIT waiting screen designed around current StikDebug workflows.
- Low Power Mode and thermal-pressure warnings before expensive emulation.
- Firebase Analytics and Crashlytics removed from the personal build.
- Signed and unsigned packaging scripts plus an end-to-end import, render,
  pause, save-state, stop, JIT-gate, and thermal-warning smoke test.

Read the full [iPhone and iPad guide](docs/iOS_CONSUMPTION.md), the
[validation record](docs/iOS_VALIDATION.md), and the
[release test matrix](docs/iOS_TEST_MATRIX.md). Changes are welcome; start with
the [iOS contribution guide](docs/iOS_CONTRIBUTING.md).

## Install, JIT, and games

Full-speed emulation requires JIT. On a non-jailbroken device, install the app,
open a game, leave the JIT waiting screen visible, and enable JIT for
DolphiniOS using the current
[official StikDebug release](https://github.com/StephenDev0/StikDebug/releases),
a device pairing file, Wi-Fi, and LocalDevVPN. The game starts automatically
after attachment is detected. StikDebug is no longer distributed through the
App Store; follow its current README and the
[official DolphiniOS JIT guide](https://dolphinios.oatmealdome.me/jit-help).

Treat the pairing file like a credential: do not post it, commit it, or send it
to an agent. “Continue Without JIT” exists for diagnosis and is far too slow
for normal play.

Import your own legal `RVZ`, `ISO`, `GCM`, `GCZ`, `WIA`, `DOL`, or `ELF` file
using the `+` button or place it in
`On My iPhone/iPad → DolphiniOS → Software`.

Performance varies by device and game. Start with Metal, 1× internal
resolution, Low Power Mode off, and a cool device.

## Project lineage and license

This is a community performance build of
[OatmealDome’s DolphiniOS](https://github.com/OatmealDome/dolphin-ios), itself
based on the [Dolphin Emulator](https://github.com/dolphin-emu/dolphin).
Dolphin/DolphiniOS is licensed under GPL-2.0-or-later. Preserve the source,
copyright notices, license files, and corresponding-source obligations when
redistributing a build.

This project is not affiliated with or endorsed by Nintendo, the Dolphin
project, or the DolphiniOS project. “GameCube” is used only to describe
compatibility.

## Upstream build notes

## Building

You will need the following:

* A Mac capable of running macOS Big Sur 11.3 or later
* Xcode 13 or later
* Homebrew (or your favourite package manager)

First, install the necessary tools using Homebrew:

```
brew install cmake ninja bartycrouch
```

If you are using a different package manager, refer to its documentation.

You must change the organization identifier and team ID before you can build!

To change the organization identifier, go to `Project` -> `Config` -> `BundleIdentifier.xcconfig`, and change `use.your.own.organization.identifier` to something unique.

To change the team ID, go to `Project` -> `Config` -> `DevelopmentTeam.xcconfig`, and replace `your-team-id` with your developer account's team ID.

Once finished, you can open the Xcode project at `Source/iOS/App/DolphiniOS.xcodeproj` and build DolphiniOS.

# Dolphin - A GameCube and Wii Emulator

[Homepage](https://dolphin-emu.org/) | [Project Site](https://github.com/dolphin-emu/dolphin) | [Buildbot](https://dolphin.ci/) | [Forums](https://forums.dolphin-emu.org/) | [Wiki](https://wiki.dolphin-emu.org/) | [GitHub Wiki](https://github.com/dolphin-emu/dolphin/wiki) | [Issue Tracker](https://bugs.dolphin-emu.org/projects/emulator/issues) | [Coding Style](https://github.com/dolphin-emu/dolphin/blob/master/Contributing.md) | [Transifex Page](https://app.transifex.com/dolphinemu/dolphin-emu/dashboard/) | [Analytics](https://mon.dolphin-emu.org/)

Dolphin is an emulator for running GameCube and Wii games on Windows,
Linux, macOS, and recent Android devices. It's licensed under the terms
of the GNU General Public License, version 2 or later (GPLv2+).

Please read the [FAQ](https://dolphin-emu.org/docs/faq/) before using Dolphin.

## System Requirements

### Desktop

* OS
    * Windows (10 1903 or higher).
    * Linux.
    * macOS (11.0 Big Sur or higher).
    * Unix-like systems other than Linux are not officially supported but might work.
* Processor
    * A CPU with SSE2 support.
    * A modern CPU (3 GHz and Dual Core, not older than 2008) is highly recommended.
* Graphics
    * A reasonably modern graphics card (Direct3D 11.1 / OpenGL 3.3).
    * A graphics card that supports Direct3D 11.1 / OpenGL 4.4 is recommended.

### Android

* OS
    * Android (5.0 Lollipop or higher).
* Processor
    * A processor with support for 64-bit applications (either ARMv8 or x86-64).
* Graphics
    * A graphics processor that supports OpenGL ES 3.0 or higher. Performance varies heavily with [driver quality](https://dolphin-emu.org/blog/2013/09/26/dolphin-emulator-and-opengl-drivers-hall-fameshame/).
    * A graphics processor that supports standard desktop OpenGL features is recommended for best performance.

Dolphin can only be installed on devices that satisfy the above requirements. Attempting to install on an unsupported device will fail and display an error message.

## Building for Windows

Use the solution file `Source/dolphin-emu.sln` to build Dolphin on Windows.
Dolphin targets the latest MSVC shipped with Visual Studio or Build Tools.
Other compilers might be able to build Dolphin on Windows but have not been
tested and are not recommended to be used. Git and latest Windows SDK must be
installed when building.

Make sure to pull submodules before building:
```sh
git submodule update --init --recursive
```

The "Release" solution configuration includes performance optimizations for the best user experience but complicates debugging Dolphin.
The "Debug" solution configuration is significantly slower, more verbose and less permissive but makes debugging Dolphin easier.

## Building for Linux and macOS

Dolphin requires [CMake](https://cmake.org/) for systems other than Windows. 
You need a recent version of GCC or Clang with decent c++20 support. CMake will
inform you if your compiler is too old.
Many libraries are bundled with Dolphin and used if they're not installed on 
your system. CMake will inform you if a bundled library is used or if you need
to install any missing packages yourself. You may refer to the [wiki](https://github.com/dolphin-emu/dolphin/wiki/Building-for-Linux) for more information.

Make sure to pull submodules before building:
```sh
git submodule update --init --recursive
```

### macOS Build Steps:

A binary supporting a single architecture can be built using the following steps: 

1. `mkdir build`
2. `cd build`
3. `cmake ..`
4. `make -j $(sysctl -n hw.logicalcpu)`

An application bundle will be created in `./Binaries`.

A script is also provided to build universal binaries supporting both x64 and ARM in the same
application bundle using the following steps:

1. `mkdir build`
2. `cd build`
3. `python ../BuildMacOSUniversalBinary.py`
4. Universal binaries will be available in the `universal` folder

Doing this is more complex as it requires installation of library dependencies for both x64 and ARM (or universal library
equivalents) and may require specifying additional arguments to point to relevant library locations. 
Execute BuildMacOSUniversalBinary.py --help for more details.  

### Linux Global Build Steps:

To install to your system.

1. `mkdir build`
2. `cd build`
3. `cmake ..`
4. `make -j $(nproc)`
5. `sudo make install`

### Linux Local Build Steps:

Useful for development as root access is not required.

1. `mkdir Build`
2. `cd Build`
3. `cmake .. -DLINUX_LOCAL_DEV=true`
4. `make -j $(nproc)`
5. `ln -s ../../Data/Sys Binaries/`

### Linux Portable Build Steps:

Can be stored on external storage and used on different Linux systems.
Or useful for having multiple distinct Dolphin setups for testing/development/TAS.

1. `mkdir Build`
2. `cd Build`
3. `cmake .. -DLINUX_LOCAL_DEV=true`
4. `make -j $(nproc)`
5. `cp -r ../Data/Sys/ Binaries/`
6. `touch Binaries/portable.txt`

## Building for Android

These instructions assume familiarity with Android development. If you do not have an
Android dev environment set up, see [AndroidSetup.md](AndroidSetup.md).

Make sure to pull submodules before building:
```sh
git submodule update --init --recursive
```

If using Android Studio, import the Gradle project located in `./Source/Android`.

Android apps are compiled using a build system called Gradle. Dolphin's native component,
however, is compiled using CMake. The Gradle script will attempt to run a CMake build
automatically while building the Java code.

## Uninstalling

On Windows, simply remove the extracted directory, unless it was installed with the NSIS installer,
in which case you can uninstall Dolphin like any other Windows application.

Linux users can run `cat install_manifest.txt | xargs -d '\n' rm` as root from the build directory
to uninstall Dolphin from their system.

macOS users can simply delete Dolphin.app to uninstall it.

Additionally, you'll want to remove the global user directory if you don't plan on reinstalling Dolphin.

## Command Line Usage

```
Usage: Dolphin.exe [options]... [FILE]...

Options:
  --version             show program's version number and exit
  -h, --help            show this help message and exit
  -u USER, --user=USER  User folder path
  -m MOVIE, --movie=MOVIE
                        Play a movie file
  -e <file>, --exec=<file>
                        Load the specified file
  -n <16-character ASCII title ID>, --nand_title=<16-character ASCII title ID>
                        Launch a NAND title
  -C <System>.<Section>.<Key>=<Value>, --config=<System>.<Section>.<Key>=<Value>
                        Set a configuration option
  -s <file>, --save_state=<file>
                        Load the initial save state
  -d, --debugger        Show the debugger pane and additional View menu options
  -l, --logger          Open the logger
  -b, --batch           Run Dolphin without the user interface (Requires
                        --exec or --nand-title)
  -c, --confirm         Set Confirm on Stop
  -v VIDEO_BACKEND, --video_backend=VIDEO_BACKEND
                        Specify a video backend
  -a AUDIO_EMULATION, --audio_emulation=AUDIO_EMULATION
                        Choose audio emulation from [HLE|LLE]
```

Available DSP emulation engines are HLE (High Level Emulation) and
LLE (Low Level Emulation). HLE is faster but less accurate whereas
LLE is slower but close to perfect. Note that LLE has two submodes (Interpreter and Recompiler)
but they cannot be selected from the command line.

Available video backends are "D3D" and "D3D12" (they are only available on Windows), "OGL", and "Vulkan".
There's also "Null", which will not render anything, and
"Software Renderer", which uses the CPU for rendering and
is intended for debugging purposes only.

## DolphinTool Usage
```
usage: dolphin-tool COMMAND -h

commands supported: [convert, verify, header, extract]
```

```
Usage: convert [options]... [FILE]...

Options:
  -h, --help            show this help message and exit
  -u USER, --user=USER  User folder path, required for temporary processing
                        files.Will be automatically created if this option is
                        not set.
  -i FILE, --input=FILE
                        Path to disc image FILE.
  -o FILE, --output=FILE
                        Path to the destination FILE.
  -f FORMAT, --format=FORMAT
                        Container format to use. Default is RVZ. [iso|gcz|wia|rvz]
  -s, --scrub           Scrub junk data as part of conversion.
  -b BLOCK_SIZE, --block_size=BLOCK_SIZE
                        Block size for GCZ/WIA/RVZ formats, as an integer.
                        Suggested value for RVZ: 131072 (128 KiB)
  -c COMPRESSION, --compression=COMPRESSION
                        Compression method to use when converting to WIA/RVZ.
                        Suggested value for RVZ: zstd [none|zstd|bzip|lzma|lzma2]
  -l COMPRESSION_LEVEL, --compression_level=COMPRESSION_LEVEL
                        Level of compression for the selected method. Ignored
                        if 'none'. Suggested value for zstd: 5
```

```
Usage: verify [options]...

Options:
  -h, --help            show this help message and exit
  -u USER, --user=USER  User folder path, required for temporary processing
                        files.Will be automatically created if this option is
                        not set.
  -i FILE, --input=FILE
                        Path to disc image FILE.
  -a ALGORITHM, --algorithm=ALGORITHM
                        Optional. Compute and print the digest using the
                        selected algorithm, then exit. [crc32|md5|sha1|rchash]
```

```
Usage: header [options]...

Options:
  -h, --help            show this help message and exit
  -i FILE, --input=FILE
                        Path to disc image FILE.
  -b, --block_size      Optional. Print the block size of GCZ/WIA/RVZ formats,
then exit.
  -c, --compression     Optional. Print the compression method of GCZ/WIA/RVZ
                        formats, then exit.
  -l, --compression_level
                        Optional. Print the level of compression for WIA/RVZ
                        formats, then exit.
```

```
Usage: extract [options]...

Options:
  -h, --help            show this help message and exit
  -i FILE, --input=FILE
                        Path to disc image FILE.
  -o FOLDER, --output=FOLDER
                        Path to the destination FOLDER.
  -p PARTITION, --partition=PARTITION
                        Which specific partition you want to extract.
  -s SINGLE, --single=SINGLE
                        Which specific file/directory you want to extract.
  -l, --list            List all files in volume/partition. Will print the
                        directory/file specified with --single if defined.
  -q, --quiet           Mute all messages except for errors.
  -g, --gameonly        Only extracts the DATA partition.
```
