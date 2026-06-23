## ADDED Requirements

### Requirement: Menu status is visible
The system SHALL show current profile, state, display count, and recent restore summary in the menu bar UI.

#### Scenario: Exact profile is learning
- **WHEN** the app is learning an exact profile
- **THEN** the menu shows the profile name and Learning state

### Requirement: User can pause automation
The system SHALL provide controls to pause restore, pause learning, or pause all automated behavior.

#### Scenario: Pause all is active
- **WHEN** the user enables Pause All
- **THEN** the system does not restore or learn until pause is cleared

### Requirement: Restore report explains outcomes
The system SHALL show restored, skipped, and failed windows with reasons for the most recent restore.

#### Scenario: Window is skipped
- **WHEN** a window is skipped because it is minimized, fullscreen-like, or unmatched
- **THEN** Recent Restore Report includes that window and reason

