# Contributing to DynamicNotch

DynamicNotch is an open-source project created and maintained by **ZXT**.

## Contact

For larger changes or coordination:

- Discord user ID: `1531412914005606513`
- Email: `contact@zxt.lol`

## Contributions

Bug fixes, documentation improvements, compatibility fixes, and focused feature changes are welcome.

When contributing:

- Keep the existing project style
- Keep changes focused
- Explain what changed and why
- Test on macOS before submitting
- Do not include secrets, tokens, passwords, personal data, or unrelated files
- Keep the copyright and MIT license notices

## Local source build

```bash
swiftc -typecheck -framework Cocoa -framework SwiftUI -framework ServiceManagement DynamicNotch.swift
```

```bash
swiftc -O -framework Cocoa -framework SwiftUI -framework ServiceManagement -o DynamicNotch DynamicNotch.swift
```

Official downloads are published through `zxt.lol` and GitHub Releases.