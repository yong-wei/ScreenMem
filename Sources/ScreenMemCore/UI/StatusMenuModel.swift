public struct StatusMenuModel: Equatable, Sendable {
    public let statusTitle: String
    public let items: [StatusMenuItem]

    public init(statusTitle: String, items: [StatusMenuItem]) {
        self.statusTitle = statusTitle
        self.items = items
    }

    public static let `default` = StatusMenuModel.make(permissionState: .granted)

    public static func make(permissionState: AccessibilityPermissionState) -> StatusMenuModel {
        let permissionItems: [StatusMenuItem] = switch permissionState {
        case .granted:
            []
        case .permissionMissing:
            [
                StatusMenuItem(title: "Permission Missing", isEnabled: false, command: .none),
                StatusMenuItem(title: "Open Accessibility Settings", isEnabled: true, command: .openAccessibilitySettings)
            ]
        }

        return StatusMenuModel(
            statusTitle: ApplicationIdentity.statusTitle,
            items: [
                StatusMenuItem(title: ApplicationIdentity.statusTitle, isEnabled: false, command: .none),
                StatusMenuItem(
                    title: "Create Profile from Current Displays",
                    isEnabled: true,
                    command: .createProfileFromCurrentDisplays
                )
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
    case openAccessibilitySettings
    case quit
}
