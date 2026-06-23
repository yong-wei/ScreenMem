import Foundation

public struct WindowMatch: Equatable, Sendable {
    public let snapshot: WindowSnapshot
    public let state: WindowState

    public init(snapshot: WindowSnapshot, state: WindowState) {
        self.snapshot = snapshot
        self.state = state
    }
}

public enum WindowMatcher {
    public static func match(currentWindows: [WindowSnapshot], learnedStates: [WindowState]) -> [WindowMatch] {
        let activeStates = learnedStates.filter { $0.tombstone == nil }
        var windowsByIdentity: [LearnedWindowIdentity: WindowSnapshot] = [:]
        for window in currentWindows {
            windowsByIdentity[LearnedWindowIdentity(snapshot: window)] = window
        }

        return activeStates.compactMap { state in
            guard let window = windowsByIdentity[state.identity] else {
                return nil
            }
            return WindowMatch(snapshot: window, state: state)
        }
    }
}
