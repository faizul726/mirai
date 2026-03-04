#!/usr/bin/env bash

set -e

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

BASE_PROFILE="${PLATFORM}_base"
NORMAL_PROFILE="${PLATFORM}"
NOCLOUDS_PROFILE="${PLATFORM}_noclouds"

SHADERC_PATH="./shaderc"
DOWNLOAD_URL="https://github.com/bambosan/bgfx-mcbe/releases/download/binaries/shaderc-win-x64.zip"
ZIP_FILE="shaderc.zip"

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
