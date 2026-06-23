## Why

The app's risky behavior is not the UI; it is writing profile state at the wrong time or moving windows to unsafe frames. A focused test hardening change is needed before treating the MVP as reliable.

## What Changes

- Add mock display and window providers.
- Add state machine tests.
- Add coordinate transform and clamp tests.
- Add profile exact/partial/no-match tests.
- Add window matching tests.
- Add JSON atomic write tests.
- Add a manual test matrix for MacBook, external displays, Sidecar, closed windows, multi-window apps, minimized windows, and fullscreen windows.

## Capabilities

### New Capabilities
- `test-hardening`: Covers unit, integration, and manual verification requirements for the MVP.

### Modified Capabilities
- None.

## Impact

Affects Tests, mock providers, build/test commands, and manual QA documentation.

