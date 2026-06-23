## Why

Some apps create or reveal windows after display restoration starts. A short late-window monitor improves restoration without permanently fighting the user.

## What Changes

- Add a 60-second late-window monitoring period after profile restoration.
- Restore newly appearing windows once if they match unrecovered learned state.
- Stop restoring late windows after the monitoring period.
- Avoid moving windows the user has already manually adjusted.

## Capabilities

### New Capabilities
- `late-window-monitor`: Covers delayed window detection and one-time restoration after profile switch.

### Modified Capabilities
- None.

## Impact

Affects Engine, Window matching, learning coordination, and restore reports.

