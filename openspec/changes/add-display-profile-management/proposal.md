## Why

Automatic restoration depends on stable display identity and user-created profiles. Without this contract, the app could accidentally learn or restore under the wrong display set.

## What Changes

- Add display enumeration and identity generation.
- Add exact display-set fingerprinting that ignores display order.
- Add JSON-backed profile creation from the current display set.
- Prevent automatic profile creation for unknown display combinations.

## Capabilities

### New Capabilities
- `display-profile-management`: Covers display snapshots, stable display identity, exact profile matching, and user-created profile persistence.

### Modified Capabilities
- None.

## Impact

Affects Display and Profile modules, JSON storage schema, profile UI entry points, and tests for fingerprint stability.

