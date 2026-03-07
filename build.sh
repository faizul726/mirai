#!/usr/bin/env bash

set -e

SHADERC_PATH=./shaderc
DOWNLOAD_URL="https://github.com/bambosan/bgfx-mcbe/releases/download/binaries/shaderc-linux-x64.zip"
ZIP_FILE="shaderc.zip"

SUBPACKS_PATH=./pack/subpacks
VC_SUBPACK_PATH=$SUBPACKS_PATH/vc
NOVC_SUBPACK_PATH=$SUBPACKS_PATH/novc
VC_SUBPACK_RENDERER_PATH=$VC_SUBPACK_PATH/renderer
VC_SUBPACK_MATERIALS_PATH=$VC_SUBPACK_RENDERER_PATH/materials
NOVC_SUBPACK_RENDERER_PATH=$NOVC_SUBPACK_PATH/renderer
NOVC_SUBPACK_MATERIALS_PATH=$NOVC_SUBPACK_RENDERER_PATH/materials
BASE_MATERIALS_PATH=./pack/renderer/materials

# check parameter
if [ -z "$1" ]; then
    echo "Usage: $0 <platform>"
    echo "Allowed: android | ios"
    exit 1
fi

PLATFORM="$1"

# paramter/plaform validation
if [[ "$PLATFORM" != "android" && "$PLATFORM" != "ios" ]]; then
    echo "Invalid platform: $PLATFORM"
    echo "Allowed platforms: android, ios"
    exit 1
fi

BASE_PROFILE="${PLATFORM}"
NORMAL_PROFILE="${PLATFORM} features vclouds"
NOCLOUDS_PROFILE="${PLATFORM} features"

# checking lazurite
if ! command -v lazurite >/dev/null 2>&1; then
    echo "ERROR: lazurite not found."
    echo "Please install first:"
    echo "pip install lazurite"
    exit 1
fi

echo ""

# checking shaderc
if [ -x "$SHADERC_PATH" ]; then
    echo "shaderc found."
else
    echo "shaderc not found. Downloading..."

    curl -L "$DOWNLOAD_URL" -o "$ZIP_FILE"
    unzip -o "$ZIP_FILE"

    FOUND_SHADERC=$(find . -type f -name "shadercRelease" | head -n 1)

    if [ -z "$FOUND_SHADERC" ]; then
        echo "shaderc binary not found after extraction!"
        exit 1
    fi

    mv "$FOUND_SHADERC" "$SHADERC_PATH"
    chmod +x "$SHADERC_PATH"
    rm -f "$ZIP_FILE"

    echo "shaderc downloaded."
fi

echo ""

mkdir -p "$SUBPACKS_PATH"
mkdir -p "$NOVC_SUBPACK_PATH"
mkdir -p "$VC_SUBPACK_PATH"
mkdir -p "$NOVC_SUBPACK_RENDERER_PATH"
mkdir -p "$VC_SUBPACK_RENDERER_PATH"
mkdir -p "$NOVC_SUBPACK_MATERIALS_PATH"
mkdir -p "$VC_SUBPACK_MATERIALS_PATH"
mkdir -p "$BASE_MATERIALS_PATH"

# do build
echo "Running build: $BASE_PROFILE"
lazurite build ./src -p "$BASE_PROFILE" \
    -o ./pack/renderer/materials --skip-validation

echo ""

echo "Running build: $NORMAL_PROFILE"
lazurite build ./src -p "$NORMAL_PROFILE" \
    -o ./pack/subpacks/vc/renderer/materials --skip-validation

echo ""

echo "Running build: $NOCLOUDS_PROFILE"
lazurite build ./src -p "$NOCLOUDS_PROFILE" \
    -o ./pack/subpacks/novc/renderer/materials --skip-validation

echo "Build completed successfully!"
