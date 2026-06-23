import Foundation

public enum MenuAutomationState: String, Equatable, Sendable {
    case learning = "Learning"
    case restoring = "Restoring"
    case unmanaged = "Unmanaged"
    case paused = "Paused"
}

public struct MenuViewState: Equatable, Sendable {
    public let profileName: String?
    public let automationState: MenuAutomationState
    public let displayCount: Int
    public let permissionState: AccessibilityPermissionState
    public let pauseState: AutomationPauseState
    public let recentReport: RestoreReportViewModel

    public init(
        profileName: String?,
        automationState: MenuAutomationState,
        displayCount: Int,
        permissionState: AccessibilityPermissionState,
        pauseState: AutomationPauseState,
        recentReport: RestoreReportViewModel
    ) {
        self.profileName = profileName
        self.automationState = automationState
        self.displayCount = displayCount
        self.permissionState = permissionState
        self.pauseState = pauseState
        self.recentReport = recentReport
    }
}

public struct ProfilesViewModel: Equatable, Sendable {
    public let profiles: [Profile]
    public let manualRestoreSourceID: UUID?

    public init(profiles: [Profile], manualRestoreSourceID: UUID?) {
        self.profiles = profiles
        self.manualRestoreSourceID = manualRestoreSourceID
    }
}

public struct PermissionsViewModel: Equatable, Sendable {
    public let state: AccessibilityPermissionState
    public let settingsURL: URL

    public init(state: AccessibilityPermissionState, settingsURL: URL = AccessibilityPermissionService.settingsURL) {
        self.state = state
        self.settingsURL = settingsURL
    }
}
