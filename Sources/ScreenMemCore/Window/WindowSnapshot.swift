import Foundation

public struct WindowSnapshot: Codable, Equatable, Sendable {
    public let appName: String
    public let bundleIdentifier: String?
    public let processIdentifier: Int32
    public let appLocalOrdinal: Int
    public let role: String?
    public let subrole: String?
    public let titleHint: String?
    public let frame: WindowRect
    public let isMinimized: Bool
    public let canMove: Bool
    public let canResize: Bool

    public init(
        appName: String,
        bundleIdentifier: String?,
        processIdentifier: Int32,
        appLocalOrdinal: Int,
        role: String?,
        subrole: String?,
        titleHint: String?,
        frame: WindowRect,
        isMinimized: Bool,
        canMove: Bool,
        canResize: Bool
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
        self.appLocalOrdinal = appLocalOrdinal
        self.role = role
        self.subrole = subrole
        self.titleHint = titleHint
        self.frame = frame
        self.isMinimized = isMinimized
        self.canMove = canMove
        self.canResize = canResize
    }
}

public enum WindowSkipReason: String, Codable, Equatable, Sendable {
    case permissionMissing
    case hiddenApplication
    case systemSpecial
    case fullscreenLike
    case nonMovable
    case nonResizable
    case missingFrame
}

public struct SkippedWindowSnapshot: Codable, Equatable, Sendable {
    public let appName: String
    public let processIdentifier: Int32
    public let titleHint: String?
    public let reason: WindowSkipReason

    public init(appName: String, processIdentifier: Int32, titleHint: String?, reason: WindowSkipReason) {
        self.appName = appName
        self.processIdentifier = processIdentifier
        self.titleHint = titleHint
        self.reason = reason
    }
}

public struct WindowInventory: Codable, Equatable, Sendable {
    public let permissionState: AccessibilityPermissionState
    public let restorationCandidates: [WindowSnapshot]
    public let skippedWindows: [SkippedWindowSnapshot]

    public init(
        permissionState: AccessibilityPermissionState,
        restorationCandidates: [WindowSnapshot],
        skippedWindows: [SkippedWindowSnapshot]
    ) {
        self.permissionState = permissionState
        self.restorationCandidates = restorationCandidates
        self.skippedWindows = skippedWindows
    }
}
