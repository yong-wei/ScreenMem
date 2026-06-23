## Context

ScreenMem must distinguish home, office, and Sidecar display combinations. The built-in display needs special treatment, while external and Sidecar displays can have incomplete identifiers.

## Goals / Non-Goals

**Goals:**
- Produce `DisplayIdentity` and `DisplaySnapshot` values from current screens.
- Generate a stable `displaySetFingerprint` from sorted display identities.
- Persist user-created profiles to JSON.
- Expose current displays and profile creation to the app shell.

**Non-Goals:**
- No window enumeration.
- No automatic learning.
- No partial matching beyond identifying exact profile matches.

## Decisions

- Store profiles in JSON for MVP because data volume is small and direct inspection is useful.
- Use a composite display identity: built-in flag, UUID/vendor/model/serial when available, and name/resolution/scale fallback.
- Store normalized display-independent profile metadata separately from runtime screen order.

## Risks / Trade-offs

- Sidecar identity can drift. Mitigation: include name, resolution, and scale in fallback matching data.
- JSON writes can corrupt state if interrupted. Mitigation: introduce atomic writes in the profile store before learning writes arrive.

