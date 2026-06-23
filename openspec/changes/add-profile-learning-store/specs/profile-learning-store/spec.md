## ADDED Requirements

### Requirement: Learning is exact-profile only
The system SHALL write learned window states only when the current display set exactly matches a user-created profile.

#### Scenario: Unknown display set changes windows
- **WHEN** the current display set does not exactly match a profile
- **THEN** no profile window state is written

### Requirement: Stable windows are saved after debounce
The system SHALL wait for window state to remain stable before saving learned positions and sizes.

#### Scenario: User drags a window
- **WHEN** the user moves a window repeatedly within the debounce interval
- **THEN** only the final stable window state is saved

### Requirement: Missing windows use tombstones
The system SHALL tombstone disappeared windows before deleting their active state.

#### Scenario: Window disappears briefly
- **WHEN** a previously learned window disappears and returns within the tombstone grace period
- **THEN** its learned state is retained

