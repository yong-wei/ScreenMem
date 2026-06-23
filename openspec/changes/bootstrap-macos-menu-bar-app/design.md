## Context

The repository starts from a product plan and local tooling only. The first implementation change should establish a minimal native macOS shell without prematurely implementing display matching or window movement.

## Goals / Non-Goals

**Goals:**
- Provide a buildable Swift + SwiftUI + AppKit macOS menu bar app.
- Keep system API access behind future module boundaries.
- Show a basic status menu and support Quit.
- Keep README aligned with the explicit MVP non-goals.

**Non-Goals:**
- No Accessibility access.
- No display profile creation.
- No window movement or learning.

## Decisions

- Use a native macOS app target rather than Electron or a cross-platform shell. Accessibility and display APIs are first-class in AppKit/CoreGraphics.
- Keep the first menu static. Dynamic state can arrive after the engine and permission services exist.
- Add placeholder directories only where they make module ownership clear; avoid empty abstractions beyond the planned boundary.

## Risks / Trade-offs

- Project scaffolding can create noisy generated files. Mitigation: commit only stable project files and ignore user-local Xcode state.
- A script-only runner can drift from Xcode settings. Mitigation: make the script call the canonical build tool selected by the scaffold.

