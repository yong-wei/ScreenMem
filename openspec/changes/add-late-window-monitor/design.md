## Context

Window creation timing varies by application and macOS state restoration. The app needs a bounded recovery window, not a permanent rule that reclaims user movement.

## Goals / Non-Goals

**Goals:**
- Monitor for late windows for 60 seconds after exact or partial restoration.
- Restore only windows matching previously unrecovered states.
- Respect manual movement after a window appears.
- Report late-window restorations.

**Non-Goals:**
- No app launching.
- No indefinite monitoring mode.
- No restoration after the late-window period expires.

## Decisions

- Use the same polling inventory mechanism as learning.
- Track unrecovered state IDs from the initial restoration report.
- Treat user movement before late restore as opt-out for that window.

## Risks / Trade-offs

- Manual-movement detection can be approximate. Mitigation: compare current frame to first observed late frame before moving.
- A fixed 60-second window may not catch slow launches. Mitigation: MVP favors bounded behavior over surprising movement.

