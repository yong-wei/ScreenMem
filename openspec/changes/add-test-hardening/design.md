## Context

Many ScreenMem behaviors depend on macOS APIs that are hard to exercise in automated tests. The design should isolate pure logic and use manual testing only for system integration that cannot be reliably mocked.

## Goals / Non-Goals

**Goals:**
- Make display matching, window matching, coordinate transforms, state guards, and profile store behavior testable without real displays.
- Keep mocks behind the same protocols as production services.
- Document manual validation for display and Accessibility behavior.

**Non-Goals:**
- No full macOS UI automation suite in MVP.
- No testing of third-party app internals.
- No attempt to simulate every macOS display edge case.

## Decisions

- Protocol-wrap DisplayProvider and WindowProvider so pure engine tests do not call system APIs.
- Prefer deterministic unit tests for matching and state transitions.
- Keep manual test matrix in docs until the app has enough stable UI for automation.

## Risks / Trade-offs

- Manual tests can drift. Mitigation: tie them to MVP acceptance and keep scenarios concrete.
- Mocked tests can miss AX quirks. Mitigation: restore reports and permission diagnostics remain part of acceptance.

