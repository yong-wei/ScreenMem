## Why

The app is intentionally background-oriented, so users need reliable menu controls, pause states, permission visibility, profile management, and restore diagnostics to trust it.

## What Changes

- Add menu bar status for profile, display count, permission, learning, restoring, unmanaged, and paused states.
- Add pause controls for restore, learning, and all automated behavior.
- Add profile list actions for rename, delete, duplicate, and manual restore source.
- Add Recent Restore Report UI with restored and skipped window details.
- Add Restore Now command.

## Capabilities

### New Capabilities
- `menu-controls-and-restore-reports`: Covers menu bar UI, profile management controls, pause controls, Restore Now, and restore diagnostics.

### Modified Capabilities
- None.

## Impact

Affects UI, Engine command surface, ProfileStore mutation actions, and restore logging.

