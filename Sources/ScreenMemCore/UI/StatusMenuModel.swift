public struct StatusMenuModel: Equatable, Sendable {
    public let statusTitle: String
    public let items: [StatusMenuItem]

    public init(statusTitle: String, items: [StatusMenuItem]) {
        self.statusTitle = statusTitle
        self.items = items
    }

    public static let `default` = StatusMenuModel.make(permissionState: .granted)

    public static func make(permissionState: AccessibilityPermissionState) -> StatusMenuModel {
        make(viewState: MenuViewState(
            profileName: nil,
            automationState: .learning,
            displayCount: 0,
            permissionState: permissionState,
            pauseState: .none,
            recentReport: RestoreReportViewModel(report: nil)
        ))
    }

    public static func make(viewState: MenuViewState) -> StatusMenuModel {
        let permissionItems: [StatusMenuItem] = switch viewState.permissionState {
        case .granted:
            []
        case .permissionMissing:
            [
                StatusMenuItem(title: "Permission Missing", isEnabled: false, command: .none),
                StatusMenuItem(title: "Open Accessibility Settings", isEnabled: true, command: .openAccessibilitySettings)
            ]
        }

        let profileTitle = "Profile: \(viewState.profileName ?? "None")"
        let stateTitle = viewState.pauseState.allPaused ? "State: Paused" : "State: \(viewState.automationState.rawValue)"
        let displayTitle = "Displays: \(viewState.displayCount)"
        let reportTitle = "Latest Restore: \(viewState.recentReport.summary)"

        return StatusMenuModel(
            statusTitle: ApplicationIdentity.statusTitle,
            items: [
                StatusMenuItem(title: ApplicationIdentity.statusTitle, isEnabled: false, command: .none),
                StatusMenuItem(title: profileTitle, isEnabled: false, command: .none),
                StatusMenuItem(title: stateTitle, isEnabled: false, command: .none),
                StatusMenuItem(title: displayTitle, isEnabled: false, command: .none),
                StatusMenuItem(title: reportTitle, isEnabled: false, command: .none),
                StatusMenuItem(title: "Restore Now", isEnabled: viewState.pauseState.allowsRestore, command: .restoreNow),
                StatusMenuItem(
                    title: "Create Profile from Current Displays",
                    isEnabled: true,
                    command: .createProfileFromCurrentDisplays
                ),
                StatusMenuItem(title: "Profiles...", isEnabled: true, command: .openProfiles),
                StatusMenuItem(title: "Permissions...", isEnabled: true, command: .openPermissions),
                StatusMenuItem(title: "Recent Restore Report...", isEnabled: true, command: .openRecentRestoreReport),
                StatusMenuItem(title: "Pause Restore", isEnabled: true, command: .togglePauseRestore),
                StatusMenuItem(title: "Pause Learning", isEnabled: true, command: .togglePauseLearning),
                StatusMenuItem(title: "Pause All", isEnabled: true, command: .togglePauseAll)
            ] + permissionItems + [
                StatusMenuItem(title: "Quit \(ApplicationIdentity.name)", isEnabled: true, command: .quit)
            ]
        )
    }
}

public struct StatusMenuItem: Equatable, Sendable {
    public let title: String
    public let isEnabled: Bool
    public let command: StatusMenuCommand

    public init(title: String, isEnabled: Bool, command: StatusMenuCommand) {
        self.title = title
        self.isEnabled = isEnabled
        self.command = command
    }
}

public enum StatusMenuCommand: Equatable, Sendable {
    case none
    case createProfileFromCurrentDisplays
    case restoreNow
    case togglePauseRestore
    case togglePauseLearning
    case togglePauseAll
    case openProfiles
    case openPermissions
    case openRecentRestoreReport
    case openAccessibilitySettings
    case quit
}
