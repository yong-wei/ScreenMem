## ADDED Requirements

### Requirement: Pure logic has automated tests
The system SHALL include automated tests for display matching, window matching, coordinate transforms, state transitions, tombstone expiry, and profile store atomic writes.

#### Scenario: Protected state is tested
- **WHEN** the state machine is in DisplayChanging, DisplayStabilizing, or Restoring
- **THEN** tests prove profile writes are rejected

### Requirement: System integrations use mockable providers
The system SHALL define provider protocols for display and window services so engine behavior can be tested without live macOS state.

#### Scenario: Test injects fake displays
- **WHEN** a test injects mock display snapshots
- **THEN** profile matching can be verified without real external displays

### Requirement: Manual MVP matrix is documented
The system SHALL document manual acceptance tests for MacBook-only, dual external displays, Sidecar without profile, Sidecar with profile, closed windows, Chrome multi-window, minimized windows, and fullscreen windows.

#### Scenario: MVP release candidate is checked
- **WHEN** the MVP is ready for release
- **THEN** the manual matrix can be followed to verify system-level behavior

