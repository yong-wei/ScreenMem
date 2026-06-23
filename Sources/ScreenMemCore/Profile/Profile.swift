import Foundation

public struct Profile: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let createdAt: Date
    public let displayFingerprint: String
    public let displays: [DisplayIdentity]
    public let windowStates: [WindowState]

    public init(
        id: UUID,
        name: String,
        createdAt: Date,
        displayFingerprint: String,
        displays: [DisplayIdentity],
        windowStates: [WindowState]
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.displayFingerprint = displayFingerprint
        self.displays = displays
        self.windowStates = windowStates
    }
}
