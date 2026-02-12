# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is ZenBar

ZenBar is a macOS menu bar declutter utility. Users drag unwanted status bar icons onto the ZenBar anchor to hide them, and access hidden apps via a floating SwiftUI panel. It uses the **separator expansion technique** (an invisible 10,000pt `NSStatusItem` pushes hidden items off-screen) combined with **CGEvent synthetic Cmd+drag** to programmatically reorder menu bar items. The Accessibility API is used for item enumeration and pressing. Runs as an LSUIElement (no dock icon).

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
  ├── ZenBarStatusItem        — NSStatusItem toggle, created FIRST (rightmost)
  ├── SeparatorItem           — invisible 10,000pt NSStatusItem, created SECOND (to left of toggle)
  ├── ZenBarPanelController   — floating NSPanel with SwiftUI content
  ├── HiddenItemsModel        — ObservableObject, central state
  │     └── HiddenItemsStore  — JSON persistence to ~/Library/Application Support/ZenBar/
  ├── MenuBarCoordinator      — orchestrates mover + separator + model for hide/unhide/press
  │     ├── MenuBarItemMover  — CGEvent synthetic Cmd+drag to move items across separator
  │     └── SeparatorItem     — expand/collapse to hide/reveal items
  ├── AXMenuBarInspector      — Accessibility API: enumerate items, press, resolve windowIDs
  │     └── MenuBarWindowInfo — CGWindowListCopyWindowInfo utility for windowID lookups
  └── DragMonitor             — global mouse event monitor for drag-to-hide UX
```

**Hiding mechanism:** `SeparatorItem` is an invisible `NSStatusItem` that expands to 10,000pt width, pushing all items to its left off-screen. `MenuBarItemMover` uses `CGEvent` to post synthetic Cmd+drag events that reorder items across the separator boundary. Creation order matters: toggle is created first (rightmost), separator second (to its left). Both use `autosaveName` for persistent ordering.

**Inspector:** `MenuBarInspector` protocol with single implementation `AXMenuBarInspector`. Used for item enumeration (via AX), pressing (via `AXUIElementPerformAction`), and matching items to `CGWindowID`s (via `MenuBarWindowInfo`).

**Persistence:** `HiddenItemsStore` saves/loads `[HiddenItem]` as JSON in `~/Library/Application Support/ZenBar/hidden_items.json`.

## Source Layout

All source files are in `Sources/ZenBarApp/`. Tests are in `Tests/ZenBarTests/`. App bundle resources (Info.plist, icon) are at the repo root and `assets/`.

## Release

Tagging `vX.Y.Z` and pushing triggers the GitHub Actions release workflow (`.github/workflows/release.yml`), which builds a signed DMG and creates a GitHub release. The Homebrew cask (`younggglcy/tap`) is auto-updated.
