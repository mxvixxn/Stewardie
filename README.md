# Stewardie

Stewardie is a macOS menu bar utility for managing menu bar items. The first scaffold is intentionally small: it creates a working status item, a control panel window, persistence for item states, and a placeholder service for the private menu bar APIs.

## Current Status

- Platform: macOS 13 or later
- Language: Swift
- Project type: SwiftPM executable staged as a macOS `.app` bundle by `script/build_and_run.sh`
- UI: AppKit app lifecycle with a SwiftUI control panel
- Private API integration: not implemented yet

## Run

```bash
./script/build_and_run.sh
```

Useful modes:

```bash
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
```

## Project Notes

- `MenuBarIconService` is the integration boundary for private API work.
- `MenuBarItemStore` owns persistence through `UserDefaults`.
- `StewardieControlPanel` is sample-backed until real menu bar item discovery is implemented.
- Private APIs make App Store distribution unavailable. Plan for Developer ID signing and notarization for distribution.
