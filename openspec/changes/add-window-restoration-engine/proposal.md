## Why

Once profiles can be learned, the app needs a controlled restoration engine that reacts to display changes without corrupting learning state or failing the whole restore because one window rejects movement.

## What Changes

- Add the restoration state machine.
- Add display-change stabilization and protection windows.
- Match current windows to learned window states.
- Restore matched windows for exact profiles.
- Record restore results and skipped reasons.

## Capabilities

### New Capabilities
- `window-restoration-engine`: Covers display-change flow, exact-profile restoration, window matching, movement order, and restore reports.

### Modified Capabilities
- None.

## Impact

Affects Engine, Display, Window, Profile, and Logging modules plus state machine tests.

