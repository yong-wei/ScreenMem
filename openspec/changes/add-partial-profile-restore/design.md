## Context

Partial restore is useful only if it remains conservative. Unknown display sets must not become new profiles and must not overwrite known profile state.

## Goals / Non-Goals

**Goals:**
- Select the profile with the most display overlap.
- Use recency as a deterministic tie breaker.
- Restore only windows mapped to recognized displays or fallback targets.
- End in Unmanaged state after partial restore.

**Non-Goals:**
- No automatic profile creation.
- No learning in partial state.
- No placement on displays absent from the source profile.

## Decisions

- Prefer overlap count, then last-used profile, then last successful restore to choose a source profile.
- Missing target display falls back to built-in display, or main display if built-in is unavailable.
- New displays receive no windows automatically.

## Risks / Trade-offs

- Best-match selection can be imperfect. Mitigation: report source profile and mode in restore report.
- Users may expect new displays to fill. Mitigation: require explicit profile creation for new display layouts.

