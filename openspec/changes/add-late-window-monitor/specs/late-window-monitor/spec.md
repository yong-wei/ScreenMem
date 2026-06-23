## ADDED Requirements

### Requirement: Late windows restore within monitoring period
The system SHALL monitor for newly appearing windows for 60 seconds after profile restoration and restore matching unrecovered windows once.

#### Scenario: VSCode appears after restore
- **WHEN** a VSCode window appears within 60 seconds and matches an unrecovered learned state
- **THEN** the system restores that window once

### Requirement: Late monitoring expires
The system SHALL stop late-window restoration after the monitoring period expires.

#### Scenario: Window appears after monitor expires
- **WHEN** a matching window appears after the 60-second monitoring period
- **THEN** the system does not move it as a late window

### Requirement: Manual movement is respected
The system SHALL NOT late-restore a window that the user has already manually moved after it appeared.

#### Scenario: User moves late window
- **WHEN** a late window appears and the user changes its frame before restore
- **THEN** the system leaves that window at the user-selected frame

