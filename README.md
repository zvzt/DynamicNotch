# DynamicNotch

A lightweight macOS notch-style media controller created and maintained by **ZXT**.

DynamicNotch places a compact Now Playing interface at the top of your display. It follows the active media session, expands on hover, shows track information and artwork when available, and provides playback, seek, and volume controls.

## Features

- Notch-style floating Now Playing interface
- Apple Music support with direct playback, seek, volume, and artwork handling
- Spotify support
- Browser media support through macOS Now Playing
- Optional enhanced Firefox bridge for browser metadata and artwork
- Track title, artist, artwork, playback state, and progress
- Previous/back, play/pause, and next/forward controls
- Seek scrubber
- Apple Music and Spotify in-app volume control
- Browser master-output volume control
- Configurable glass opacity and accent colors
- Launch at Login option
- Menu-bar settings
- Floating interface across Spaces

## Downloads

### DMG

Download the current DMG:

**https://zxt.lol/dynamicnotch/DynamicNotch.dmg**

Open the DMG and drag `DynamicNotch.app` to Applications. Because public builds are currently ad-hoc signed rather than Apple-notarized, macOS may require **Control-click → Open** on first launch.

### `.command` installer

Download:

**https://zxt.lol/dynamicnotch/DynamicNotch.command**

Then run it from Finder, or from Terminal:

```bash
chmod +x ~/Downloads/DynamicNotch.command
bash ~/Downloads/DynamicNotch.command
```

### One-line Terminal install

```bash
bash <(curl -fsSL https://zxt.lol/dynamicnotch/install.sh)
```

The installer places DynamicNotch in `/Applications`.

## Firefox bridge

DynamicNotch can use macOS Now Playing without a Firefox extension. An optional local bridge provides more direct Firefox/YouTube metadata and artwork.

The DMG includes `Install-Firefox-Bridge.command`. The Terminal installer also prepares the bridge automatically. To enable it in Firefox:

1. Type `about:debugging#/runtime/this-firefox` directly into the Firefox address bar.
2. Click **Load Temporary Add-on**.
3. Select `~/Library/Application Support/DynamicNotch/FirefoxExtension/manifest.json`.

Firefox requires temporary local add-ons to be loaded again after restarting Firefox.

## Uninstall

```bash
bash <(curl -fsSL https://zxt.lol/dynamicnotch/uninstall.sh)
```

## Requirements

- macOS 13 or newer
- Apple Silicon or Intel Mac
- Automation permission may be requested for Apple Music or Spotify controls

The packaged DMG includes the media helper used for system Now Playing integration. Source builds can also use a Homebrew-installed `media-control` helper.

## Source

The source is public under the MIT License.

Main project files:

- `DynamicNotch.swift` — application source
- `Info.plist` — app metadata
- `DynamicNotch.command` — downloadable installer
- `install.sh` / `uninstall.sh` — zxt.lol install endpoints
- `firefox/` — optional Firefox bridge
- `.github/workflows/release.yml` — macOS DMG/release build

## Support / issues

For bugs, installation issues, or project questions:

- Discord user ID: `1531412914005606513`
- Email: `contact@zxt.lol`
- Website: `https://zxt.lol`

GitHub issues are also welcome for non-sensitive bug reports.

## Credits

Created by **ZXT**.

## License

MIT — see [LICENSE](LICENSE).