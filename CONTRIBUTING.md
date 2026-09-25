# Contributing to DynamicNotch

Thanks for your interest in DynamicNotch.

DynamicNotch is an open-source project created and maintained by **ZXT**. The code is available under the MIT License, so you can inspect it, learn from it, use it, and build on it while keeping the required copyright and license notice.

## Participating in the official project

If you want to become an active participant in the official DynamicNotch project, help maintain the project, work on planned features, or coordinate larger contributions, contact ZXT first.

### Contact

- Discord user ID: `1531412914005606513`
- Email: `contact@zxt.lol`

## Contributions

Before working on a larger change, contact ZXT so work can be coordinated and duplicate efforts can be avoided.

For smaller fixes, bug reports, documentation improvements, or suggestions, open an issue or pull request once the public repository is available.

When contributing code:

- Keep the existing project style
- Keep changes focused
- Explain what changed and why
- Test the project on macOS before submitting
- Do not include secrets, tokens, passwords, personal data, or unrelated files
- Keep the existing copyright and MIT license notices

## Testing

The project should continue to pass:

```bash
swiftc -typecheck -framework Cocoa -framework SwiftUI DynamicNotch.swift
```

A full local compile can be tested with:

```bash
swiftc -O -framework Cocoa -framework SwiftUI -o DynamicNotch DynamicNotch.swift
```

Official builds and install files are served through `zxt.lol`.
