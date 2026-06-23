## Context

Learning is more dangerous than restoration because bad writes can destroy useful profile state. The state machine must make profile writes impossible during display changes, restoration, partial matches, and unknown display sets.

## Goals / Non-Goals

**Goals:**
- Persist learned window states only in exact profile Learning state.
- Normalize frames relative to display visible frames.
- Debounce window movement and resize changes before saving.
- Tombstone disappeared windows before removal.

**Non-Goals:**
- No automatic creation of profiles.
- No partial-profile learning.
- No AXObserver implementation in MVP.

## Decisions

- Use one-second polling plus two-second debounce for MVP simplicity.
- Store both normalized frames and absolute frame hints for diagnostics.
- Use tombstones with a 30-60 second grace period to avoid deleting state during transient system changes.

## Risks / Trade-offs

- Polling can miss very fast transitions. Mitigation: learning only needs stable final states.
- Tombstone duration can feel conservative. Mitigation: make the constant local and tested, not user-configurable in MVP.

