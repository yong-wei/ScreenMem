## Why

ScreenMem needs a runnable macOS application shell before any display, Accessibility, or restoration work can be implemented. The shell must make the product boundary explicit so later changes do not grow into a general window manager.

## What Changes

- Create a SwiftUI macOS menu bar application skeleton.
- Add the initial module layout for AppEntry, Engine, Display, Window, Profile, UI, and Logging.
- Add a build/run script and Codex environment commands.
- Document MVP scope and excluded features.

## Capabilities

### New Capabilities
- `macos-app-shell`: Covers app startup, menu bar presence, quit behavior, module layout, and project-level documentation.

### Modified Capabilities
- None.

## Impact

Affects repository structure, Swift package or Xcode project setup, local build scripts, README, and development commands.

