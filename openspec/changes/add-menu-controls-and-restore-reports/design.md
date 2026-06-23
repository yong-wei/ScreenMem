## Context

Because ScreenMem moves other apps' windows, silent behavior is unacceptable. The UI should be compact but operationally clear.

## Goals / Non-Goals

**Goals:**
- Show current state, current profile, display count, and latest restore summary.
- Provide pause controls and Restore Now.
- Provide profile list management.
- Provide a recent restore report with per-window skipped reasons.

**Non-Goals:**
- No complex layout editor.
- No cloud sync settings.
- No advanced automation rules.

## Decisions

- Keep the primary surface in the menu bar and use lightweight secondary windows for profiles, permissions, and reports.
- Model pause as engine state so learning and restoration guards remain centralized.
- Store only the recent restore report for MVP unless logs are added by a later change.

## Risks / Trade-offs

- Too much menu text can become cluttered. Mitigation: keep status concise and put details in secondary windows.
- Profile deletion can be destructive. Mitigation: require confirmation before deleting profile data.

