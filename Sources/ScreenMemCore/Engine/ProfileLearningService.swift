import Foundation

public enum LearningMode: Equatable, Sendable {
    case stopped
    case learning
}

public struct ProfileLearningConfiguration: Equatable, Sendable {
    public let debounceInterval: TimeInterval
    public let tombstoneGracePeriod: TimeInterval

    public init(debounceInterval: TimeInterval = 1.0, tombstoneGracePeriod: TimeInterval = 10.0) {
        self.debounceInterval = debounceInterval
        self.tombstoneGracePeriod = tombstoneGracePeriod
    }
}

public struct ProfileLearningService: Sendable {
    private let configuration: ProfileLearningConfiguration

    public init(configuration: ProfileLearningConfiguration = ProfileLearningConfiguration()) {
        self.configuration = configuration
    }

    public func poll(
        mode: LearningMode,
        profile: Profile?,
        displaySnapshots: [DisplaySnapshot],
        windowSnapshots: [WindowSnapshot],
        priorSample: LearningSample?,
        now: Date,
        pauseState: AutomationPauseState = .none
    ) -> LearningPollResult {
        guard mode == .learning,
              pauseState.allowsLearning,
              let profile,
              profile.displayFingerprint == DisplaySetFingerprint.exact(for: displaySnapshots) else {
            return LearningPollResult(profileToSave: nil, sample: nil)
        }

        let baselineStates = priorSample?.windowStates ?? profile.windowStates
        let learnedStates = makeLearnedStates(
            profile: profile,
            displaySnapshots: displaySnapshots,
            windowSnapshots: windowSnapshots,
            baselineStates: baselineStates,
            now: now
        )
        let sample = LearningSample(windowStates: learnedStates, sampledAt: now)

        guard let priorSample,
              priorSample.windowStates == sample.windowStates,
              now.timeIntervalSince(priorSample.sampledAt) >= configuration.debounceInterval else {
            return LearningPollResult(profileToSave: nil, sample: sample)
        }

        let savedProfile = Profile(
            id: profile.id,
            name: profile.name,
            createdAt: profile.createdAt,
            displayFingerprint: profile.displayFingerprint,
            displays: profile.displays,
            windowStates: expireTombstones(priorSample.windowStates, now: now)
        )
        return LearningPollResult(profileToSave: savedProfile, sample: sample)
    }

    private func makeLearnedStates(
        profile: Profile,
        displaySnapshots: [DisplaySnapshot],
        windowSnapshots: [WindowSnapshot],
        baselineStates: [WindowState],
        now: Date
    ) -> [WindowState] {
        guard !displaySnapshots.isEmpty else {
            return []
        }

        let baselineByIdentity = Dictionary(uniqueKeysWithValues: baselineStates.map { ($0.identity, $0) })
        let activeStates = windowSnapshots.compactMap { snapshot -> WindowState? in
            guard let targetDisplay = bestDisplay(for: snapshot.frame, from: displaySnapshots) else {
                return nil
            }

            let identity = LearnedWindowIdentity(snapshot: snapshot)
            let normalizedFrame = WindowGeometryNormalizer.normalize(snapshot.frame, in: targetDisplay.visibleFrame)
            let previousState = baselineByIdentity[identity]
            let learnedAt = previousState?.normalizedFrame == normalizedFrame && previousState?.tombstone == nil
                ? previousState?.learnedAt ?? now
                : now

            return WindowState(
                identity: identity,
                normalizedFrame: normalizedFrame,
                displayStableID: targetDisplay.identity.stableID,
                learnedAt: learnedAt,
                tombstone: nil
            )
        }
        let activeIdentities = Set(activeStates.map(\.identity))
        let tombstones = baselineStates.compactMap { state -> WindowState? in
            guard !activeIdentities.contains(state.identity) else {
                return nil
            }
            return WindowState(
                identity: state.identity,
                normalizedFrame: state.normalizedFrame,
                displayStableID: state.displayStableID,
                learnedAt: state.learnedAt,
                tombstone: state.tombstone ?? WindowTombstone(missingSince: now)
            )
        }

        return (activeStates + tombstones).sorted { left, right in
            sortKey(left.identity) < sortKey(right.identity)
        }
    }

    private func expireTombstones(_ states: [WindowState], now: Date) -> [WindowState] {
        states.filter { state in
            guard let tombstone = state.tombstone else {
                return true
            }
            return now.timeIntervalSince(tombstone.missingSince) < configuration.tombstoneGracePeriod
        }
    }

    private func bestDisplay(for windowFrame: WindowRect, from displays: [DisplaySnapshot]) -> DisplaySnapshot? {
        displays.max { left, right in
            intersectionArea(windowFrame, left.visibleFrame) < intersectionArea(windowFrame, right.visibleFrame)
        }
    }

    private func intersectionArea(_ windowFrame: WindowRect, _ visibleFrame: DisplayRect) -> Double {
        let left = max(windowFrame.x, visibleFrame.x)
        let right = min(windowFrame.x + windowFrame.width, visibleFrame.x + visibleFrame.width)
        let top = max(windowFrame.y, visibleFrame.y)
        let bottom = min(windowFrame.y + windowFrame.height, visibleFrame.y + visibleFrame.height)
        return max(0, right - left) * max(0, bottom - top)
    }

    private func sortKey(_ identity: LearnedWindowIdentity) -> String {
        [
            identity.bundleIdentifier ?? "",
            String(identity.processIdentifier),
            String(identity.appLocalOrdinal),
            identity.titleHint ?? ""
        ].joined(separator: "|")
    }
}

public struct LearningSample: Equatable, Sendable {
    public let windowStates: [WindowState]
    public let sampledAt: Date

    public init(windowStates: [WindowState], sampledAt: Date) {
        self.windowStates = windowStates
        self.sampledAt = sampledAt
    }
}

public struct LearningPollResult: Equatable, Sendable {
    public let profileToSave: Profile?
    public let sample: LearningSample?

    public init(profileToSave: Profile?, sample: LearningSample?) {
        self.profileToSave = profileToSave
        self.sample = sample
    }
}
