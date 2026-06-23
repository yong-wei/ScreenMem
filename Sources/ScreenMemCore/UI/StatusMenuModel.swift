public struct StatusMenuModel: Equatable, Sendable {
    public let statusTitle: String
    public let items: [StatusMenuItem]

    public init(statusTitle: String, items: [StatusMenuItem]) {
        self.statusTitle = statusTitle
        self.items = items
    }

    public static let `default` = StatusMenuModel(
        statusTitle: ApplicationIdentity.statusTitle,
        items: [
            StatusMenuItem(title: ApplicationIdentity.statusTitle, isEnabled: false, command: .none),
            StatusMenuItem(title: "Quit \(ApplicationIdentity.name)", isEnabled: true, command: .quit)
        ]
    )
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
    case quit
}
