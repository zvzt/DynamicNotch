# Changelog

## 3.6.2

- Removed the outer island shadow that caused faint corner wedges around the rounded UI
- Forced the SwiftUI hosting layer and panel backing to remain fully transparent
- Apple Music now takes priority when it starts playing while Firefox still reports an active YouTube session
- Paused Apple Music still yields to active Firefox/YouTube media

## 3.6.1

- Removed faint corner/triangle artifacts around the notch
- Switched the island from rectangular clipping to a true continuous rounded mask
- Applied the shadow after masking so pixels outside the rounded island remain fully transparent

## 3.6.0

- Switched the public distribution to the recommended one-line curl installer
- Removed DMG and downloadable `.command` installation from the current distribution
- Added the ZXT project image as both the app icon and menu-bar icon
- Added automatic `~/Library/Application Support/DynamicNotch` creation on launch
- DynamicNotch now keeps bundled runtime support files in its own Application Support directory
- Added a sudo repair / backup installation path
- Updated uninstall cleanup for the new Application Support directory
- Added recommended Mac setup and lightweight-native-app notes to the README

## 3.5.0

- Current native notch-style Now Playing build
- Apple Music direct metadata, playback, seek, volume, and artwork handling
- Spotify support
- Browser/system Now Playing integration
- Launch at Login
- Updated notch UI, progress controls, and settings

## 1.0.0

- Initial public DynamicNotch release
