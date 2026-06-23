import Foundation

public struct AutomationPauseState: Codable, Equatable, Sendable {
    public let restorePaused: Bool
    public let learningPaused: Bool
    public let allPaused: Bool

    public init(restorePaused: Bool = false, learningPaused: Bool = false, allPaused: Bool = false) {
        self.restorePaused = restorePaused
        self.learningPaused = learningPaused
        self.allPaused = allPaused
    }

    public static let none = AutomationPauseState()

    public var allowsRestore: Bool {
        !allPaused && !restorePaused
    }

    public var allowsLearning: Bool {
        !allPaused && !learningPaused
    }
}
