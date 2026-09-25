#!/bin/bash
set -euo pipefail

APP_DIR="$HOME/Applications/DynamicNotch.app"

printf '\nDynamicNotch Uninstaller\n========================\n\n'

pkill -x DynamicNotch >/dev/null 2>&1 || true
rm -rf "$APP_DIR"

defaults delete lol.zxt.dynamicnotch >/dev/null 2>&1 || true
rm -f /tmp/dyn_art_*.jpg >/dev/null 2>&1 || true

echo "DynamicNotch removed."
