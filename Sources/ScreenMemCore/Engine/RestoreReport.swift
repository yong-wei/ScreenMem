import Foundation

public enum RestoreSkipReason: String, Codable, Equatable, Sendable {
    case noExactProfile
    case displayMissing
    case displayAmbiguous
    case noCurrentWindowMatch
}

public enum RestoreFailureReason: String, Codable, Equatable, Sendable {
    case moveRejected
}

public struct RestoredWindowReport: Codable, Equatable, Sendable {
    public let identity: LearnedWindowIdentity
    public let targetFrame: WindowRect

    public init(identity: LearnedWindowIdentity, targetFrame: WindowRect) {
        self.identity = identity
        self.targetFrame = targetFrame
    }
}

public struct SkippedRestoreReport: Codable, Equatable, Sendable {
    public let identity: LearnedWindowIdentity?
    public let reason: RestoreSkipReason

    public init(identity: LearnedWindowIdentity?, reason: RestoreSkipReason) {
        self.identity = identity
        self.reason = reason
    }
}

public struct FailedRestoreReport: Codable, Equatable, Sendable {
    public let identity: LearnedWindowIdentity
    public let reason: RestoreFailureReason

    public init(identity: LearnedWindowIdentity, reason: RestoreFailureReason) {
        self.identity = identity
        self.reason = reason
    }
}

public struct RestoreReport: Codable, Equatable, Sendable {
    public let restoredWindows: [RestoredWindowReport]
    public let skippedWindows: [SkippedRestoreReport]
    public let failedWindows: [FailedRestoreReport]

    public init(
        restoredWindows: [RestoredWindowReport],
        skippedWindows: [SkippedRestoreReport],
        failedWindows: [FailedRestoreReport]
    ) {
        self.restoredWindows = restoredWindows
        self.skippedWindows = skippedWindows
        self.failedWindows = failedWindows
    }
}
