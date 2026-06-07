# Stewardie

Stewardie is a lightweight macOS menu bar manager. It lets you **truly hide**
menu bar icons — the icon disappears, the space closes up, and neighboring icons
shift over — then bring them all back with a single click. Think of it as a
small "archive" (보관함) for the icons you only need once in a while.

## How it works

Stewardie places a thin **divider** in your menu bar. Anything you ⌘-drag to the
**left** of that divider belongs to the hidden section. Clicking the Stewardie
icon expands the divider so those icons slide off-screen; clicking again brings
them back.

This relies entirely on **public AppKit API** (`NSStatusItem.length`), the same
length-expansion technique used by tools like Ice. No private APIs are used to
move other apps' icons, so there's nothing fragile or unsupported in the core
hide/show path — it works with every menu bar app.

## Features

- **One-click hide / show** of everything to the left of the divider.
- **Archive (보관함)** window that lists which items are currently hidden
  (read-only, via the Accessibility API — purely informational).
- **Settings** window: launch at login (`SMAppService`), version info, and
  Accessibility permission management.
- Right-click (or ⌥/⌃-click) the menu bar icon for the menu.

## Requirements

- macOS 13 or later
- Swift toolchain (Swift 6 / Xcode 16+)

## Build & Run

```bash
./script/build_and_run.sh          # build, bundle as Stewardie.app, launch
```

Other modes:

```bash
./script/build_and_run.sh --verify     # build + launch + confirm it's running
./script/build_and_run.sh --logs       # stream os_log output
./script/build_and_run.sh --telemetry  # stream subsystem telemetry
```

Or plain SwiftPM:

```bash
swift build
open .build/debug/Stewardie
```

## Permissions

The core hide/show feature needs no special permission. The Archive window's
"currently hidden" list uses the **Accessibility** permission to read the
on-screen positions of menu bar items. Grant it under
System Settings → Privacy & Security → Accessibility, or from Stewardie's
Settings window.

## Project layout

- `Services/StewardieDivider.swift` — the divider status item; expands/contracts
  its length to hide/show the section. Heart of the feature.
- `Services/MenuBarIconService.swift` — Accessibility-based discovery used by the
  archive's read-only "what's hidden" list.
- `Services/LaunchAtLoginService.swift` — login-item toggle via `SMAppService`.
- `Stores/MenuBarItemStore.swift` — permission state + hidden-section item list.
- `Views/StewardieArchiveView.swift` — the 보관함 window.
- `Views/StewardieSettingsView.swift` — the settings window.
- `App/AppDelegate.swift` — status item, click handling, windows.

## Distribution note

Because Stewardie is a menu bar accessory, distribute it with Developer ID
signing and notarization rather than the App Store.
