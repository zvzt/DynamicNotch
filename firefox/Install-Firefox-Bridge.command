#!/bin/bash
set -euo pipefail

QUIET=false
[ "${1:-}" = "--quiet" ] && QUIET=true

APP="/Applications/DynamicNotch.app"
[ -d "$APP" ] || APP="$HOME/Applications/DynamicNotch.app"

if [ ! -d "$APP" ]; then
    echo "DynamicNotch.app is not installed."
    exit 1
fi

SRC="$APP/Contents/Resources/firefox-extension"
HOST="$APP/Contents/Resources/firefox_host.pl"
DEST="$HOME/Library/Application Support/DynamicNotch/FirefoxExtension"
HOST_DIR="$HOME/Library/Application Support/Mozilla/NativeMessagingHosts"

if [ ! -d "$SRC" ] || [ ! -x "$HOST" ]; then
    echo "Firefox bridge files are missing from DynamicNotch.app."
    exit 1
fi

mkdir -p "$DEST" "$HOST_DIR"
rm -rf "$DEST"
mkdir -p "$DEST"
ditto "$SRC" "$DEST"

cat > "$HOST_DIR/lol.zxt.dynamicnotch.json" <<JSON
{
  "name": "lol.zxt.dynamicnotch",
  "description": "DynamicNotch Firefox media bridge",
  "path": "$HOST",
  "type": "stdio",
  "allowed_extensions": ["dynamicnotch@zxt.local"]
}
JSON

if [ "$QUIET" = false ]; then
    echo "Firefox bridge installed."
    echo
    echo "To enable the enhanced Firefox bridge:"
    echo "1. In Firefox, type this manually in the address bar:"
    echo "   about:debugging#/runtime/this-firefox"
    echo "2. Click Load Temporary Add-on."
    echo "3. Select:"
    echo "   $DEST/manifest.json"
    echo
    echo "Firefox requires temporary local add-ons to be loaded again after a restart."
fi