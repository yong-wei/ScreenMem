import Foundation

public enum RestorationState: Equatable, Sendable {
    case idle
    case learning
    case protectingDisplayChange(changedAt: Date)
    case waitingForStableDisplays(stableSince: Date)
    case restoring
}

public enum RestorationStateMachine {
    public static func displayChangeDetected(currentState: RestorationState, now: Date) -> RestorationState {
        switch currentState {
        case .idle, .learning, .waitingForStableDisplays, .restoring:
            return .protectingDisplayChange(changedAt: now)
        case .protectingDisplayChange:
            return .protectingDisplayChange(changedAt: now)
        }
    }

    public static func displaysSampledStable(
        currentState: RestorationState,
        now: Date,
        stabilizationInterval: TimeInterval
    ) -> RestorationState {
        switch currentState {
        case .protectingDisplayChange:
            return .waitingForStableDisplays(stableSince: now)
        case .waitingForStableDisplays(let stableSince)
            where now.timeIntervalSince(stableSince) >= stabilizationInterval:
            return .restoring
        default:
            return currentState
        }
    }

    public static func restorationCompleted(currentState: RestorationState) -> RestorationState {
        currentState == .restoring ? .learning : currentState
    }

    public static func allowsLearningWrites(_ state: RestorationState) -> Bool {
        state == .learning
    }
}
