## Why

The app cannot learn or restore window state until it can diagnose Accessibility permission and enumerate ordinary windows safely. This change establishes read-only window inventory before any movement behavior exists.

## What Changes

- Add Accessibility permission checking and user-facing permission state.
- Enumerate ordinary visible windows from running applications.
- Capture window identity hints, role/subrole, frame, minimized state, and movement/resizing capability.
- Filter system, hidden, special, fullscreen-like, and unsupported windows from restoration candidates.

## Capabilities

### New Capabilities
- `accessibility-window-inventory`: Covers Accessibility permission diagnostics and read-only ordinary window snapshots.

### Modified Capabilities
- None.

## Impact

Affects Window module, permission UI, menu status, and tests or fixtures for window filtering.

