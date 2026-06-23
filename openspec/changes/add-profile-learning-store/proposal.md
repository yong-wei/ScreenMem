## Why

ScreenMem's core value is passive learning of the user's own layouts. Learning must be restricted to exact user-created profiles and protected from display-change noise.

## What Changes

- Add `WindowState` and `NormalizedRect`.
- Add coordinate normalization against target display visible frames.
- Add polling-based learning with debounce.
- Add tombstone handling for recently missing windows.
- Add hard guards that prevent writes outside exact Learning state.

## Capabilities

### New Capabilities
- `profile-learning-store`: Covers learning state, normalized window persistence, debounced writes, and tombstone deletion.

### Modified Capabilities
- None.

## Impact

Affects Profile, Engine, Display, and Window modules plus JSON persistence and unit tests for state guards.

