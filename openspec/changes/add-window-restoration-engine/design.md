## Context

Restoration must be conservative: the app only moves windows that still exist, are eligible, and can be matched. It must never create windows or interrupt learning safeguards.

## Goals / Non-Goals

**Goals:**
- Model display change, stabilization, exact match, restoration, late monitoring entry, Learning, Unmanaged, Paused, and Permission Missing states.
- Restore exact-profile windows after display stabilization.
- Match windows using runtime ID, app identity, role/subrole, ordinal, and weak title hints.
- Continue restoring other windows when one move fails.

**Non-Goals:**
- No partial restore behavior in this change.
- No late-window recovery loop.
- No complex manual layout editor.

## Decisions

- Use explicit state transitions instead of ad hoc flags. Write guards and UI state both depend on this.
- Apply size before position, then retry position before size if needed.
- Lower title weight for Chrome-like apps because titles are not stable window identity.

## Risks / Trade-offs

- AX movement can fail per app. Mitigation: record failure and continue.
- Display stabilization can delay restore. Mitigation: use debounce and stable snapshots rather than immediate sampling.

