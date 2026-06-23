## ADDED Requirements

### Requirement: Display identities are captured
The system SHALL capture display identities with built-in status, name, available hardware identifiers, nominal pixel size, and backing scale factor.

#### Scenario: Current displays are listed
- **WHEN** the app samples current displays
- **THEN** each display snapshot includes an identity, frame, visible frame, main-display flag, and order index

### Requirement: Exact profile fingerprint is stable
The system SHALL generate exact display-set fingerprints independent of display array order.

#### Scenario: Same displays arrive in different order
- **WHEN** the same display identities are sampled in a different array order
- **THEN** the generated fingerprint remains unchanged

### Requirement: Profiles are user-created only
The system SHALL create a profile only after the user selects Create Profile from Current Displays.

#### Scenario: Unknown display set appears
- **WHEN** the current display set does not match an existing profile
- **THEN** the system does not create a new profile automatically

