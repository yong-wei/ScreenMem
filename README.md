# ScreenMem

ScreenMem is a macOS menu bar app plan for restoring existing window positions across user-created display profiles.

The MVP target is narrow:

- Learn window positions only inside a display profile the user explicitly created.
- Restore only currently existing ordinary windows after a display set changes and stabilizes.
- Support exact profile restoration and best-effort partial restoration for known displays.
- Provide pause controls, permission diagnostics, and recent restore reports.

It does not replace Magnet, Moom, or Rectangle. It does not launch missing apps, create closed windows, restore browser tabs, manage true fullscreen windows, move windows across Spaces, or sync data through the cloud.

The current product plan is in `docs/macOS App 开发计划：Profile-aware Window State Restorer.md`. Implementation work should start from the OpenSpec changes under `openspec/changes/`.

