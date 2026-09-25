#!/bin/bash
set -euo pipefail

BASE_URL="https://zxt.lol/dynamicnotch"
APP_DIR="$HOME/Applications/DynamicNotch.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
TMP="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP"
}
trap cleanup EXIT

printf '\nDynamicNotch Installer\n======================\n\n'

if [ "$(uname -s)" != "Darwin" ]; then
    echo "DynamicNotch only supports macOS."
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required."
    exit 1
fi

if ! command -v swiftc >/dev/null 2>&1; then
    echo "Apple's Swift compiler is required."
    echo "Install Xcode Command Line Tools with:"
    echo "  xcode-select --install"
    exit 1
fi

mkdir -p "$HOME/Applications"

echo "Downloading DynamicNotch..."
curl -fsSL "$BASE_URL/DynamicNotch.swift" -o "$TMP/DynamicNotch.swift"
curl -fsSL "$BASE_URL/Info.plist" -o "$TMP/Info.plist"

echo "Compiling..."
swiftc -O -framework Cocoa -framework SwiftUI     -o "$TMP/DynamicNotch" "$TMP/DynamicNotch.swift"

pkill -x DynamicNotch >/dev/null 2>&1 || true

rm -rf "$APP_DIR"
mkdir -p "$MACOS"
cp "$TMP/DynamicNotch" "$MACOS/DynamicNotch"
cp "$TMP/Info.plist" "$CONTENTS/Info.plist"
chmod 755 "$MACOS/DynamicNotch"

if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true
fi

echo "Installed to:"
echo "  $APP_DIR"
echo
echo "Launching DynamicNotch..."
open "$APP_DIR"

echo
echo "DynamicNotch installed."
echo "Created by ZXT."
