# DynamicNotch

A lightweight native macOS notch-style media controller created and maintained by **ZXT**.

DynamicNotch places a compact Now Playing interface at the top of your display. It follows the active media session, expands on hover, shows track information and artwork when available, and provides playback, seek, and volume controls.

## Features

- Native SwiftUI/Cocoa app — no Electron or embedded browser runtime
- Notch-style floating Now Playing interface
- Apple Music support with direct playback, seek, volume, and artwork handling
- Spotify support
- Browser/system media support through macOS Now Playing
- Track title, artist, artwork, playback state, and progress
- Previous/back, play/pause, and next/forward controls
- Seek scrubber
- Apple Music and Spotify in-app volume control
- Browser master-output volume control
- Configurable glass opacity and accent colors
- Launch at Login option
- Custom DynamicNotch app and menu-bar icon
- Floating interface across Spaces

## Recommended installation

The recommended and supported installation method is the one-line Terminal installer:

```bash
bash <(curl -fsSL https://zxt.lol/dynamicnotch/install.sh)
```

This downloads the current source from **zxt.lol**, builds DynamicNotch natively on your Mac, installs it to `/Applications`, signs the local build, and launches it.

There is no separate DMG or `.command` download in the current distribution.

### Alternative #1 — Raw GitHub installer

If the zxt.lol mirror is unavailable or stale, run the installer directly from the public GitHub source:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zvzt/DynamicNotch/main/install.sh)
```

This uses the same installer logic but downloads it straight from GitHub instead of zxt.lol.

### Alternative #2 — Sudo repair / backup install

If the normal or raw GitHub installer cannot replace an existing copy, use the repair path:

```bash
curl -fsSL https://raw.githubusercontent.com/zvzt/DynamicNotch/main/install.sh -o /tmp/dynamicnotch-install.sh && sudo -v && bash /tmp/dynamicnotch-install.sh --repair
```

This bypasses the zxt.lol mirror, rebuilds the current version as your normal user, and only uses sudo when macOS requires permission to replace the app in `/Applications`. The first Swift build may sit at the build step for roughly 10-45 seconds while system frameworks load.

## Recommended Mac setup

**Minimum**
- macOS 13 Ventura or newer
- Intel or Apple Silicon Mac
- Apple Command Line Tools / `swiftc`

Install Command Line Tools if needed:

```bash
xcode-select --install
```

**Recommended**
- Apple Silicon Mac (M1 or newer)
- macOS 14 Sonoma or newer
- 8 GB RAM or more
- Homebrew installed for the most complete browser/system Now Playing support

If Homebrew is already installed, the installer automatically prepares the small `media-control` helper used by DynamicNotch.

DynamicNotch itself is intentionally lightweight. It is a native Swift app rather than an Electron app, does not run its own web server, and does not ship an embedded browser engine. Most of the work is event/media polling and drawing the small notch interface.

## App data

On first launch, DynamicNotch creates its own support directory:

```text
~/Library/Application Support/DynamicNotch
```

Bundled support files such as the app icon and media helper are copied there so DynamicNotch keeps its own runtime files together instead of scattering them around your home directory.

The main application remains:

```text
/Applications/DynamicNotch.app
```

## App icon

DynamicNotch uses the project icon supplied by ZXT for both:
- the macOS application icon
- the menu-bar settings icon

Source image:

`https://i.postimg.cc/jjjWppSR/image.png`

## Uninstall

```bash
bash <(curl -fsSL https://zxt.lol/dynamicnotch/uninstall.sh)
```

The uninstaller removes the app, DynamicNotch preferences, temporary state, and `~/Library/Application Support/DynamicNotch`. It does not uninstall Homebrew or `media-control` because those may be used by other software.

## Notes

macOS may request Automation permission when DynamicNotch controls Apple Music or Spotify. Allow it if you want those controls to work.

The app is locally/ad-hoc signed by the installer. It is not currently distributed through the Mac App Store or Apple notarization service.

## Source

The source is public under the MIT License.

Main project files:
- `DynamicNotch.swift` — application source
- `Info.plist` — app metadata
- `install.sh` — recommended curl installer
- `uninstall.sh` — uninstaller
- `CHANGELOG.md` — release history

## Support / issues

For bugs, installation issues, or project questions:
- Discord user ID: `1531412914005606513`
- Email: `contact@zxt.lol`
- Website: `https://zxt.lol`

GitHub issues are welcome for non-sensitive bug reports.

## Credits

Created by **ZXT**.

## License

MIT — see [LICENSE](LICENSE).
