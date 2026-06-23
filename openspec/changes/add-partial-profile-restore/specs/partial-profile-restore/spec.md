## ADDED Requirements

### Requirement: Best partial profile is selected
The system SHALL choose the existing profile with the largest overlap with the current display set when no exact profile matches.

#### Scenario: Sidecar is added to a known office setup
- **WHEN** Office-B1-B2 exists and current displays are Office-B1-B2-iPad
- **THEN** Office-B1-B2 is selected as the partial restore source

### Requirement: Missing displays fall back safely
The system SHALL restore windows targeting absent displays to the built-in display, or to the current main display when no built-in display is available.

#### Scenario: Target external display is absent
- **WHEN** a learned window targets a display not currently connected
- **THEN** the window is restored to the built-in display or current main display

### Requirement: Partial matches do not learn
The system SHALL remain unmanaged after partial restoration and SHALL NOT write profile state.

#### Scenario: User moves windows after partial restore
- **WHEN** the current display set only partially matches a profile
- **THEN** subsequent window changes do not update any profile

