## Context

macOS window access depends on Accessibility permission and differs by application. The MVP should first produce a trustworthy inventory and visible diagnostics rather than silently failing.

## Goals / Non-Goals

**Goals:**
- Detect whether Accessibility permission is granted.
- Enumerate ordinary windows using Accessibility APIs.
- Normalize data into `WindowSnapshot`.
- Filter windows that should never be moved by the app.

**Non-Goals:**
- No window movement.
- No AXObserver event subscription.
- No browser tab or semantic title matching.

## Decisions

- Use polling-friendly inventory APIs first. The learning service can consume snapshots without requiring event subscriptions.
- Treat title as a weak hint only. Bundle identifier, app name, role/subrole, and ordinal are the main identity fields.
- Record skipped reasons for diagnostics, but do not block the full scan on one inaccessible app.

## Risks / Trade-offs

- Some apps expose incomplete Accessibility attributes. Mitigation: snapshot optional fields and continue.
- Permission prompts can be confusing. Mitigation: surface Permission Missing status and provide a System Settings entry point.

