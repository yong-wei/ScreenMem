import Foundation

public struct WindowState: Codable, Equatable, Sendable {
    public let identity: LearnedWindowIdentity
    public let normalizedFrame: NormalizedRect
    public let displayStableID: String
    public let learnedAt: Date
    public let tombstone: WindowTombstone?

    public init(
        identity: LearnedWindowIdentity,
        normalizedFrame: NormalizedRect,
        displayStableID: String,
        learnedAt: Date,
        tombstone: WindowTombstone?
    ) {
        self.identity = identity
        self.normalizedFrame = normalizedFrame
        self.displayStableID = displayStableID
        self.learnedAt = learnedAt
        self.tombstone = tombstone
    }
}

public struct LearnedWindowIdentity: Codable, Equatable, Hashable, Sendable {
    public let bundleIdentifier: String?
    public let processIdentifier: Int32
    public let appLocalOrdinal: Int
    public let titleHint: String?

    public init(
        bundleIdentifier: String?,
        processIdentifier: Int32,
        appLocalOrdinal: Int,
        titleHint: String?
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
        self.appLocalOrdinal = appLocalOrdinal
        self.titleHint = titleHint
    }

    public init(snapshot: WindowSnapshot) {
        self.init(
            bundleIdentifier: snapshot.bundleIdentifier,
            processIdentifier: snapshot.processIdentifier,
            appLocalOrdinal: snapshot.appLocalOrdinal,
            titleHint: snapshot.titleHint
        )
    }
}

public struct WindowTombstone: Codable, Equatable, Sendable {
    public let missingSince: Date

    public init(missingSince: Date) {
        self.missingSince = missingSince
    }
}
