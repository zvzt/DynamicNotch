#!/bin/bash
set -euo pipefail

APP="/Applications/DynamicNotch.app"
TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"
TARGET_HOME="$(dscl . -read "/Users/$TARGET_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
if [ -z "$TARGET_HOME" ]; then
    TARGET_HOME="$HOME"
fi
SUPPORT="$TARGET_HOME/Library/Application Support/DynamicNotch"

pkill -x DynamicNotch >/dev/null 2>&1 || true

if [ -d "$APP" ]; then
    if [ "$(id -u)" -eq 0 ] || [ -w /Applications ]; then
        rm -rf "$APP"
    else
        sudo rm -rf "$APP"
    fi
fi

rm -rf "$SUPPORT"
rm -f /tmp/dynamicnotch_firefox_state.json /tmp/dynamicnotch_firefox_command.json /tmp/dynamicnotch_music_artwork
if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    sudo -u "$SUDO_USER" defaults delete lol.zxt.dynamicnotch >/dev/null 2>&1 || true
else
    defaults delete lol.zxt.dynamicnotch >/dev/null 2>&1 || true
fi

echo "DynamicNotch removed."
echo "Homebrew and media-control were left untouched because they may be used by other apps."
