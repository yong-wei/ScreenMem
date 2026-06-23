## ADDED Requirements

### Requirement: Menu bar app launches
The system SHALL provide a buildable macOS menu bar application that starts without opening an unnecessary main window.

#### Scenario: App starts from local runner
- **WHEN** the developer runs `./script/build_and_run.sh`
- **THEN** the app builds and launches as a menu bar app

### Requirement: Basic status menu exists
The system SHALL show a menu bar item with current status text and a Quit command.

#### Scenario: User quits from menu
- **WHEN** the user selects Quit from the menu bar menu
- **THEN** the application terminates cleanly

### Requirement: Scope is documented
The repository README SHALL document that ScreenMem restores only existing ordinary windows and does not launch apps, create windows, restore browser tabs, manage full screen windows, move across Spaces, or provide cloud sync.

#### Scenario: Reader checks project scope
- **WHEN** a reader opens the README
- **THEN** the MVP scope and excluded features are visible

