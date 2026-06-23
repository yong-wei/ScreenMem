## Why

Users can temporarily add or remove displays, such as Sidecar iPad, before creating a new profile. The app should use known displays conservatively without learning or filling unknown displays.

## What Changes

- Add best-match profile selection for unknown display sets.
- Restore windows whose target displays are present.
- Fall back missing target displays to the built-in display or current main display.
- Keep new displays empty and prevent learning during partial matches.

## Capabilities

### New Capabilities
- `partial-profile-restore`: Covers partial matching, known-display restore behavior, fallback target selection, and unmanaged learning state.

### Modified Capabilities
- None.

## Impact

Affects profile matching, restoration targeting, state machine transitions, and tests for unknown display combinations.

