# DynamicNotch

A lightweight macOS notch-style music controller for Apple Music and Spotify.

**Created and maintained by ZXT.**

DynamicNotch adds a compact floating music interface near the top of your Mac display. It can show track information and artwork, expand on hover, control playback, seek through a track, adjust volume, and switch between Apple Music and Spotify.

## Features

- Compact notch-style player that expands on hover
- Apple Music and Spotify support
- Track title, artist, artwork, playback state, and progress
- Previous, play/pause, and next controls
- Seek scrubber
- App-volume control
- Configurable glass opacity
- Multiple accent colors
- Menu-bar settings
- Floating interface across Spaces
- Artwork fallback through Apple's public iTunes Search API

## Install

Run this in Terminal:

```bash
bash <(curl -fsSL https://zxt.lol/dynamicnotch/install.sh)
```

DynamicNotch compiles locally on your Mac and installs to:

```text
~/Applications/DynamicNotch.app
```

The installer launches DynamicNotch when installation finishes.

## Uninstall

Run:

```bash
bash <(curl -fsSL https://zxt.lol/dynamicnotch/uninstall.sh)
```

## Requirements

- macOS
- Apple's Swift compiler / Xcode Command Line Tools
- Apple Music and/or Spotify for media-control features

If `swiftc` is missing, install Apple's Command Line Tools:

```bash
xcode-select --install
```

macOS may ask for Automation permission when DynamicNotch controls Apple Music or Spotify.

## Source code

The source code is public and may be used, studied, modified, and redistributed under the terms of the MIT License.

If you reuse code from DynamicNotch, keep the copyright/license notice included with the project.

Main files:

- `DynamicNotch.swift` — main application source
- `Info.plist` — app bundle metadata
- `install.sh` — installer
- `uninstall.sh` — uninstaller
- `LICENSE` — MIT License
- `CONTRIBUTING.md` — information for participating in the official project
- `SECURITY.md` — security-reporting information

Official downloads and installers are served through **zxt.lol**.

## Contributing / joining the project

If you want to actively participate in the official DynamicNotch project, contribute features, help maintain it, or work directly with ZXT, contact me first.

- Discord user ID: `1531412914005606513`
- Email: `contact@zxt.lol`

Bug reports, ideas, and suggestions are welcome.

See [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## Credits

Created by **ZXT**.

- Website: `zxt.lol`
- Discord: `1531412914005606513`
- Email: `contact@zxt.lol`

## License

MIT — see [LICENSE](LICENSE).
