#!/bin/bash
set -euo pipefail

DMG_URL="https://zxt.lol/dynamicnotch/DynamicNotch.dmg"
DMG_FALLBACK_URL="https://github.com/zvzt/DynamicNotch/releases/latest/download/DynamicNotch.dmg"
APP_DIR="/Applications/DynamicNotch.app"
TMP="$(mktemp -d)"
MOUNT="$TMP/mount"
DMG="$TMP/DynamicNotch.dmg"

cleanup() {
    hdiutil detach "$MOUNT" -quiet >/dev/null 2>&1 || true
    rm -rf "$TMP"
}
trap cleanup EXIT

printf '\nDynamicNotch Installer\n======================\n\n'

if [ "$(uname -s)" != "Darwin" ]; then
    echo "DynamicNotch only supports macOS."
    exit 1
fi

for cmd in curl hdiutil; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd is required."
        exit 1
    fi
done

echo "Downloading DynamicNotch..."
if ! curl -fL --retry 2 "$DMG_URL" -o "$DMG"; then
    echo "zxt.lol download failed, using GitHub release fallback..."
    curl -fL --retry 3 "$DMG_FALLBACK_URL" -o "$DMG"
fi
mkdir -p "$MOUNT"
hdiutil attach "$DMG" -nobrowse -quiet -mountpoint "$MOUNT"

if [ ! -d "$MOUNT/DynamicNotch.app" ]; then
    echo "The downloaded DMG does not contain DynamicNotch.app."
    exit 1
fi

pkill -x DynamicNotch >/dev/null 2>&1 || true

install_app() {
    rm -rf "$APP_DIR"
    ditto "$MOUNT/DynamicNotch.app" "$APP_DIR"
}

if [ -w /Applications ]; then
    install_app
else
    echo "Administrator permission is required to install to /Applications."
    sudo bash -c 'rm -rf /Applications/DynamicNotch.app'
    sudo ditto "$MOUNT/DynamicNotch.app" "$APP_DIR"
fi

if [ -x "$APP_DIR/Contents/Resources/Install-Firefox-Bridge.command" ]; then
    bash "$APP_DIR/Contents/Resources/Install-Firefox-Bridge.command" --quiet || true
fi

open "$APP_DIR"

echo
echo "DynamicNotch installed to $APP_DIR"
echo "Website: https://zxt.lol"
echo "Discord: 1531412914005606513"
echo "Email: contact@zxt.lol"