#!/bin/bash
set -euo pipefail
clear
printf 'DynamicNotch Installer\n======================\n\n'
bash <(curl -fsSL https://zxt.lol/dynamicnotch/install.sh)
printf '\nPress Return to close...'
read -r _