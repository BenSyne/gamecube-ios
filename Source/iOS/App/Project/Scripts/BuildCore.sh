#!/bin/bash

set -e

PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

REPO_ROOT_DIR="$PROJECT_DIR/../../.."
CMAKE_BUILD_DIR="$REPO_ROOT_DIR/build-$PLATFORM_NAME-$DOL_CORE_BUILD_TARGET"

MACHINE_ARCH="$(arch)"

case $PLATFORM_NAME in
    iphoneos)
        PLATFORM=OS64
        PLATFORM_DEPLOYMENT_TARGET=$IPHONEOS_DEPLOYMENT_TARGET
        ;;
    iphonesimulator)
        if [ "$MACHINE_ARCH" = "arm64" ]; then
            PLATFORM=SIMULATORARM64
        else
            PLATFORM=SIMULATOR64
        fi

        PLATFORM_DEPLOYMENT_TARGET=$IPHONEOS_DEPLOYMENT_TARGET
        ;;
    appletvos)
        PLATFORM=TVOS
        PLATFORM_DEPLOYMENT_TARGET=$TVOS_DEPLOYMENT_TARGET
        ;;
    appletvsimulator)
        PLATFORM=SIMULATOR_TVOS
        PLATFORM_DEPLOYMENT_TARGET=$TVOS_DEPLOYMENT_TARGET
        ;;
    *)
        echo "Unknown platform \"$PLATFORM_NAME\""
        exit 1
        ;;
esac

if [ ! -d "$CMAKE_BUILD_DIR" ]; then
    mkdir "$CMAKE_BUILD_DIR"
fi

cd "$CMAKE_BUILD_DIR"

# Reconfigure on every invocation. CMake is incremental, and this guarantees
# that SDK, deployment-target, and compiler flag changes are reflected instead
# of silently reusing a stale build.ninja file.
#
# fmt 10's consteval format parser is incompatible with the stricter
# constant-expression checks in AppleClang 21 (Xcode 26.4+). Keeping fmt's
# constexpr helpers enabled while disabling only the consteval entry point
# preserves compile-time-capable helpers and falls back to runtime validation.
cmake "$REPO_ROOT_DIR" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$REPO_ROOT_DIR/Externals/ios-cmake/ios.toolchain.cmake" \
  -DPLATFORM="$PLATFORM" \
  -DDEPLOYMENT_TARGET="$PLATFORM_DEPLOYMENT_TARGET" \
  -DENABLE_VISIBILITY=ON \
  -DENABLE_BITCODE=OFF \
  -DENABLE_ARC=ON \
  -DCMAKE_BUILD_TYPE="$DOL_CORE_BUILD_TARGET" \
  -DCMAKE_CXX_FLAGS="-fPIC -DFMT_CONSTEVAL=" \
  -DIOS=ON \
  -DENABLE_ANALYTICS=NO \
  -DUSE_SYSTEM_LIBS=OFF \
  -DENABLE_TESTS=OFF \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5

ninja
