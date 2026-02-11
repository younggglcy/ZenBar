# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is ZenBar

ZenBar is a macOS menu bar declutter utility. Users drag unwanted status bar icons onto the ZenBar anchor to hide them, and access hidden apps via a floating SwiftUI panel. It uses the Accessibility API (and optionally private `AXHidden`/`AXPosition` attributes) to enumerate, hide, and restore menu bar items. Runs as an LSUIElement (no dock icon).

## Build & Development

```bash
swift build                        # Debug build
swift build -c release             # Release build
swift run ZenBar                   # Run the app
swift test                         # Run tests
./scripts/package.sh <version>     # Build .app bundle + DMG
```

No external dependencies — pure Swift/AppKit/SwiftUI.

**Platform:** macOS 14.0+ (Swift 5.9, Swift Package Manager)

**Bundle ID:** `name.younggglcy.ZenBar`

## Architecture

**SwiftUI + AppKit hybrid.** Main UI is SwiftUI (`HiddenListView`) hosted inside an AppKit `NSPanel` (`ZenBarPanelController`). The status item and event monitoring are pure AppKit.

Key component flow:

```
AppDelegate
  ├── ZenBarStatusItem        — NSStatusItem, handles left/right click
  ├── ZenBarPanelController   — floating NSPanel with SwiftUI content
  ├── HiddenItemsModel        — ObservableObject, central state
  │     └── HiddenItemsStore  — JSON persistence to ~/Library/Application Support/ZenBar/
  ├── MenuBarCoordinator      — bridges model ↔ inspector for press/unhide actions
  │     └── PrivateMenuBarInspector  — wraps AXMenuBarInspector, attempts private AX attributes
  │           └── AXMenuBarInspector — Accessibility API implementation of MenuBarInspector protocol
  └── DragMonitor             — global mouse event monitor for drag-to-hide UX
```

**Protocol-oriented inspector design:** `MenuBarInspector` protocol has two implementations. `PrivateMenuBarInspector` wraps `AXMenuBarInspector` and probes private attributes at runtime; it degrades gracefully if they're unavailable, reporting capabilities via `MenuBarCapabilities`.

**Persistence:** `HiddenItemsStore` saves/loads `[HiddenItem]` as JSON in `~/Library/Application Support/ZenBar/hidden_items.json`.

## Source Layout

All source files are in `Sources/ZenBarApp/`. Tests are in `Tests/ZenBarTests/`. App bundle resources (Info.plist, icon) are at the repo root and `assets/`.

## Release

Tagging `vX.Y.Z` and pushing triggers the GitHub Actions release workflow (`.github/workflows/release.yml`), which builds a signed DMG and creates a GitHub release. The Homebrew cask (`younggglcy/tap`) is auto-updated.
