## ADDED Requirements

### Requirement: Permission state is explicit
The system SHALL detect missing Accessibility permission and expose Permission Missing state to the UI.

#### Scenario: Permission is absent
- **WHEN** Accessibility permission is not granted
- **THEN** the system does not enumerate or move windows and reports Permission Missing

### Requirement: Ordinary windows are enumerated
The system SHALL enumerate ordinary visible windows with app identity, process identity, role/subrole, title hint, frame, minimized flag, and movement/resizing capability.

#### Scenario: Multiple app windows exist
- **WHEN** an application has multiple ordinary windows
- **THEN** the inventory contains separate window snapshots with stable app-local ordinals

### Requirement: Unsupported windows are skipped
The system SHALL skip fullscreen-like, system special, hidden, non-movable, or non-resizable windows for restoration eligibility.

#### Scenario: Fullscreen window is present
- **WHEN** a window is detected as fullscreen-like
- **THEN** it is not returned as a restoration candidate and the skip reason is recorded

