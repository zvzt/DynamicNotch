#!/bin/bash
set -euo pipefail

pkill -x DynamicNotch >/dev/null 2>&1 || true

if [ -d /Applications/DynamicNotch.app ]; then
    if [ -w /Applications ]; then
        rm -rf /Applications/DynamicNotch.app
    else
        sudo rm -rf /Applications/DynamicNotch.app
    fi
fi

rm -rf "$HOME/Applications/DynamicNotch.app"
rm -rf "$HOME/Library/Application Support/DynamicNotch"
rm -f "$HOME/Library/Application Support/Mozilla/NativeMessagingHosts/lol.zxt.dynamicnotch.json"
rm -f /tmp/dynamicnotch_firefox_state.json /tmp/dynamicnotch_firefox_cmd.json
defaults delete lol.zxt.dynamicnotch >/dev/null 2>&1 || true

echo "DynamicNotch removed."