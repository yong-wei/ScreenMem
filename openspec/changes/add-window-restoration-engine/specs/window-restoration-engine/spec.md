## ADDED Requirements

### Requirement: Display changes enter protection state
The system SHALL pause learning immediately when a display change is detected and remain protected until the display set is stable and restoration completes.

#### Scenario: Display changes during Learning
- **WHEN** a display change event occurs while Learning
- **THEN** the system stops profile writes before sampling the new display state

### Requirement: Exact profile restores matched windows
The system SHALL restore current eligible windows that match learned states for an exact profile.

#### Scenario: Exact profile is reconnected
- **WHEN** the current display set exactly matches a profile with learned windows
- **THEN** matched existing windows are moved and resized to their learned frames

### Requirement: Restore failures do not abort batch
The system SHALL record per-window restore failures and continue processing remaining windows.

#### Scenario: One app rejects movement
- **WHEN** one matched window fails to move or resize
- **THEN** the restore report records the failure and other matched windows continue restoring

