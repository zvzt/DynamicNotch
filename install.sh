#!/bin/bash
set -euo pipefail

BASE_URL="https://zxt.lol/dynamicnotch"
LOGO_URL="https://i.postimg.cc/jjjWppSR/image.png"
APP_DIR="/Applications/DynamicNotch.app"
TMP="$(mktemp -d)"
BUILD_APP="$TMP/DynamicNotch.app"
CONTENTS="$BUILD_APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
REPAIR=false

if [ "${1:-}" = "--repair" ]; then
    REPAIR=true
fi

cleanup() {
    rm -rf "$TMP"
}
trap cleanup EXIT

printf '\nDynamicNotch Installer\n======================\n\n'
if $REPAIR; then
    echo "Repair / backup install mode"
    echo
fi

if [ "$(uname -s)" != "Darwin" ]; then
    echo "DynamicNotch only supports macOS."
    exit 1
fi

for cmd in curl swiftc codesign sips iconutil ditto; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        if [ "$cmd" = "swiftc" ]; then
            echo "Apple Command Line Tools are required."
            echo "Install them with: xcode-select --install"
        else
            echo "$cmd is required."
        fi
        exit 1
    fi
done

download() {
    curl -fsSL --retry 3 "$1" -o "$2"
}

echo "Downloading source..."
download "$BASE_URL/DynamicNotch.swift" "$TMP/DynamicNotch.swift"
download "$BASE_URL/Info.plist" "$TMP/Info.plist"

echo "Downloading app icon..."
download "$LOGO_URL" "$TMP/AppIcon.png"

mkdir -p "$MACOS" "$RESOURCES"
cp "$TMP/Info.plist" "$CONTENTS/Info.plist"
cp "$TMP/AppIcon.png" "$RESOURCES/AppIcon.png"

echo "Building native Swift app..."
swiftc -O \
    -framework Cocoa \
    -framework SwiftUI \
    -framework ServiceManagement \
    -o "$MACOS/DynamicNotch" \
    "$TMP/DynamicNotch.swift"
chmod 755 "$MACOS/DynamicNotch"

echo "Creating macOS app icon..."
ICONSET="$TMP/AppIcon.iconset"
mkdir -p "$ICONSET"
sips -z 16 16     "$TMP/AppIcon.png" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32     "$TMP/AppIcon.png" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$TMP/AppIcon.png" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64     "$TMP/AppIcon.png" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$TMP/AppIcon.png" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256   "$TMP/AppIcon.png" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$TMP/AppIcon.png" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512   "$TMP/AppIcon.png" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$TMP/AppIcon.png" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$TMP/AppIcon.png" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"

BREW=""
for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then
        BREW="$candidate"
        break
    fi
done

run_user() {
    if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
        sudo -u "$SUDO_USER" "$@"
    else
        "$@"
    fi
}

if [ -n "$BREW" ]; then
    echo "Preparing system media helper..."
    if ! run_user "$BREW" list media-control >/dev/null 2>&1; then
        run_user "$BREW" install media-control
    fi
    HELPER_PREFIX="$(run_user "$BREW" --prefix media-control)"
    HELPER_REAL="$(cd "$HELPER_PREFIX" && pwd -P)"
    mkdir -p "$RESOURCES/media-control"
    ditto "$HELPER_REAL" "$RESOURCES/media-control"
else
    echo "Homebrew was not found."
    echo "DynamicNotch will still install, but full browser/system Now Playing support works best with Homebrew + media-control."
fi

xattr -cr "$BUILD_APP" 2>/dev/null || true
codesign --force --deep --sign - "$BUILD_APP"

pkill -x DynamicNotch >/dev/null 2>&1 || true

echo "Installing to /Applications..."
if [ "$(id -u)" -eq 0 ]; then
    rm -rf "$APP_DIR"
    ditto "$BUILD_APP" "$APP_DIR"
elif [ -w /Applications ]; then
    rm -rf "$APP_DIR"
    ditto "$BUILD_APP" "$APP_DIR"
else
    sudo rm -rf "$APP_DIR"
    sudo ditto "$BUILD_APP" "$APP_DIR"
fi

if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    sudo -u "$SUDO_USER" open "$APP_DIR" >/dev/null 2>&1 || true
else
    open "$APP_DIR"
fi

echo
echo "DynamicNotch installed successfully."
echo "App: $APP_DIR"
echo "On first launch it creates:"
echo "  ~/Library/Application Support/DynamicNotch"
echo
echo "Website: https://zxt.lol"
echo "Discord: 1531412914005606513"
echo "Email: contact@zxt.lol"
