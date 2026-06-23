import Foundation

public enum WindowMoveResult: Equatable, Sendable {
    case moved
    case rejected
}

public struct WindowRestorationEngine: Sendable {
    private let moveWindow: @Sendable (_ snapshot: WindowSnapshot, _ frame: WindowRect) -> WindowMoveResult

    public init(moveWindow: @escaping @Sendable (_ snapshot: WindowSnapshot, _ frame: WindowRect) -> WindowMoveResult) {
        self.moveWindow = moveWindow
    }

    public func restoreExactProfile(
        profile: Profile?,
        displaySnapshots: [DisplaySnapshot],
        currentWindows: [WindowSnapshot]
    ) -> RestoreReport {
        guard let profile,
              profile.displayFingerprint == DisplaySetFingerprint.exact(for: displaySnapshots) else {
            return RestoreReport(
                restoredWindows: [],
                skippedWindows: [SkippedRestoreReport(identity: nil, reason: .noExactProfile)],
                failedWindows: []
            )
        }

        return restore(
            profile: profile,
            displaySnapshots: displaySnapshots,
            currentWindows: currentWindows,
            allowFallbackDisplays: false
        )
    }

    public func restorePartialProfile(
        profile: Profile,
        displaySnapshots: [DisplaySnapshot],
        currentWindows: [WindowSnapshot]
    ) -> RestoreReport {
        restore(
            profile: profile,
            displaySnapshots: displaySnapshots,
            currentWindows: currentWindows,
            allowFallbackDisplays: true
        )
    }

    private func restore(
        profile: Profile,
        displaySnapshots: [DisplaySnapshot],
        currentWindows: [WindowSnapshot],
        allowFallbackDisplays: Bool
    ) -> RestoreReport {
        let displaysByStableID = Dictionary(grouping: displaySnapshots, by: { $0.identity.stableID })
        let matches = WindowMatcher.match(currentWindows: currentWindows, learnedStates: profile.windowStates)
        let matchedIdentities = Set(matches.map { $0.state.identity })
        var restored: [RestoredWindowReport] = []
        var skipped: [SkippedRestoreReport] = []
        var failed: [FailedRestoreReport] = []

        for state in profile.windowStates where state.tombstone == nil && !matchedIdentities.contains(state.identity) {
            skipped.append(SkippedRestoreReport(identity: state.identity, reason: .noCurrentWindowMatch))
        }

        for match in matches {
            guard let displays = displaysByStableID[match.state.displayStableID], !displays.isEmpty else {
                if allowFallbackDisplays,
                   let fallbackDisplay = fallbackDisplay(from: displaySnapshots, profile: profile) {
                    restore(match: match, display: fallbackDisplay, restored: &restored, failed: &failed)
                    continue
                }
                skipped.append(SkippedRestoreReport(identity: match.state.identity, reason: .displayMissing))
                continue
            }
            guard displays.count == 1, let display = displays.first else {
                skipped.append(SkippedRestoreReport(identity: match.state.identity, reason: .displayAmbiguous))
                continue
            }

            restore(match: match, display: display, restored: &restored, failed: &failed)
        }

        return RestoreReport(restoredWindows: restored, skippedWindows: skipped, failedWindows: failed)
    }

    private func restore(
        match: WindowMatch,
        display: DisplaySnapshot,
        restored: inout [RestoredWindowReport],
        failed: inout [FailedRestoreReport]
    ) {
        let targetFrame = WindowGeometryNormalizer.denormalize(match.state.normalizedFrame, in: display.visibleFrame)
        switch moveWindow(match.snapshot, targetFrame) {
        case .moved:
            restored.append(RestoredWindowReport(identity: match.state.identity, targetFrame: targetFrame))
        case .rejected:
            failed.append(FailedRestoreReport(identity: match.state.identity, reason: .moveRejected))
        }
    }

    private func fallbackDisplay(from displaySnapshots: [DisplaySnapshot], profile: Profile) -> DisplaySnapshot? {
        let knownDisplayIDs = Set(profile.displays.map(\.stableID))
        let knownDisplays = displaySnapshots.filter { knownDisplayIDs.contains($0.identity.stableID) }
        return knownDisplays.first(where: { $0.identity.isBuiltIn })
            ?? knownDisplays.first(where: \.isMain)
    }
}
