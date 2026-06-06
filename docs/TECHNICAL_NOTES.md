# Technical Notes

## Facts From The Brief

- Stewardie targets macOS.
- The app is expected to use Swift with AppKit and optional SwiftUI surfaces.
- The app is planned for self-distribution outside the App Store.
- The brief names private APIs such as `CGSPrivate` and `CGSConnection`.
- The recommended minimum target is macOS 13 Ventura.

## Current Assumptions

- The first implementation should be a buildable menu bar app before private API work begins.
- A SwiftPM package is acceptable for the initial scaffold because it can be opened from Xcode and built from Codex.
- Real menu bar item discovery, hiding, reordering, and removal need a separate validation pass because they depend on private API behavior.

## Known Risks

- Private API usage can break across macOS releases.
- Accessibility permission handling must be designed before manipulating other apps or system UI.
- Self-distribution requires signing and notarization work before public release.
