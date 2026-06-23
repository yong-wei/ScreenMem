import Foundation

public struct LateWindowMonitor: Sendable {
    public let profileID: UUID
    public let startedAt: Date
    public let duration: TimeInterval
    public let pendingStates: [WindowState]
    public let appearedFrames: [LearnedWindowIdentity: WindowRect]

    public init(
        profileID: UUID,
        startedAt: Date,
        duration: TimeInterval = 60,
        pendingStates: [WindowState],
        appearedFrames: [LearnedWindowIdentity: WindowRect] = [:]
    ) {
        self.profileID = profileID
        self.startedAt = startedAt
        self.duration = duration
        self.pendingStates = pendingStates
        self.appearedFrames = appearedFrames
    }

    public static func start(profile: Profile, restoredReport: RestoreReport, startedAt: Date) -> LateWindowMonitor {
        let unresolvedIdentities = Set(restoredReport.skippedWindows.compactMap(\.identity))
        let pendingStates = profile.windowStates.filter { state in
            state.tombstone == nil && unresolvedIdentities.contains(state.identity)
        }
        return LateWindowMonitor(profileID: profile.id, startedAt: startedAt, pendingStates: pendingStates)
    }

    public func stopIfExpired(now: Date, profileID currentProfileID: UUID) -> LateWindowMonitor? {
        guard currentProfileID == profileID,
              now.timeIntervalSince(startedAt) <= duration else {
            return nil
        }
        return self
    }

    public func restoreNewWindows(
        currentWindows: [WindowSnapshot],
        displaySnapshots: [DisplaySnapshot],
        now: Date,
        profileID currentProfileID: UUID,
        moveWindow: @Sendable (_ snapshot: WindowSnapshot, _ frame: WindowRect) -> WindowMoveResult
    ) -> LateWindowMonitorResult {
        guard let activeMonitor = stopIfExpired(now: now, profileID: currentProfileID) else {
            return LateWindowMonitorResult(
                monitor: nil,
                report: RestoreReport(
                    restoredWindows: [],
                    skippedWindows: [],
                    failedWindows: [],
                    lateSkippedWindows: pendingStates.map {
                        SkippedRestoreReport(identity: $0.identity, reason: .monitoringExpired)
                    }
                )
            )
        }

        let matches = WindowMatcher.match(currentWindows: currentWindows, learnedStates: activeMonitor.pendingStates)
        let displaysByStableID = Dictionary(grouping: displaySnapshots, by: { $0.identity.stableID })
        var remainingStates = activeMonitor.pendingStates
        var appearedFrames = activeMonitor.appearedFrames
        var lateRestored: [RestoredWindowReport] = []
        var lateSkipped: [SkippedRestoreReport] = []
        var failed: [FailedRestoreReport] = []

        for match in matches {
            guard let display = displaysByStableID[match.state.displayStableID]?.first else {
                continue
            }

            let identity = match.state.identity
            guard let firstFrame = appearedFrames[identity] else {
                appearedFrames[identity] = match.snapshot.frame
                continue
            }

            if firstFrame != match.snapshot.frame {
                lateSkipped.append(SkippedRestoreReport(identity: identity, reason: .manualMovementDetected))
                remainingStates.removeAll { $0.identity == identity }
                continue
            }

            let targetFrame = WindowGeometryNormalizer.denormalize(match.state.normalizedFrame, in: display.visibleFrame)
            switch moveWindow(match.snapshot, targetFrame) {
            case .moved:
                lateRestored.append(RestoredWindowReport(identity: identity, targetFrame: targetFrame))
                remainingStates.removeAll { $0.identity == identity }
            case .rejected:
                failed.append(FailedRestoreReport(identity: identity, reason: .moveRejected))
                remainingStates.removeAll { $0.identity == identity }
            }
        }

        let nextMonitor = LateWindowMonitor(
            profileID: activeMonitor.profileID,
            startedAt: activeMonitor.startedAt,
            duration: activeMonitor.duration,
            pendingStates: remainingStates,
            appearedFrames: appearedFrames
        )
        return LateWindowMonitorResult(
            monitor: remainingStates.isEmpty ? nil : nextMonitor,
            report: RestoreReport(
                restoredWindows: [],
                skippedWindows: [],
                failedWindows: failed,
                lateRestoredWindows: lateRestored,
                lateSkippedWindows: lateSkipped
            )
        )
    }
}

public struct LateWindowMonitorResult: Sendable {
    public let monitor: LateWindowMonitor?
    public let report: RestoreReport

    public init(monitor: LateWindowMonitor?, report: RestoreReport) {
        self.monitor = monitor
        self.report = report
    }
}
