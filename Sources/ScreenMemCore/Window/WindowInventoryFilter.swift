import Foundation

public struct RawWindowRecord: Equatable, Sendable {
    public let appName: String
    public let bundleIdentifier: String?
    public let processIdentifier: Int32
    public let role: String?
    public let subrole: String?
    public let titleHint: String?
    public let frame: WindowRect?
    public let isMinimized: Bool
    public let canMove: Bool
    public let canResize: Bool
    public let isApplicationHidden: Bool
    public let isFullscreenLike: Bool

    public init(
        appName: String,
        bundleIdentifier: String?,
        processIdentifier: Int32,
        role: String?,
        subrole: String?,
        titleHint: String?,
        frame: WindowRect?,
        isMinimized: Bool,
        canMove: Bool,
        canResize: Bool,
        isApplicationHidden: Bool,
        isFullscreenLike: Bool
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
        self.role = role
        self.subrole = subrole
        self.titleHint = titleHint
        self.frame = frame
        self.isMinimized = isMinimized
        self.canMove = canMove
        self.canResize = canResize
        self.isApplicationHidden = isApplicationHidden
        self.isFullscreenLike = isFullscreenLike
    }
}

public enum WindowInventoryFilter {
    public static func makeInventory(
        permissionState: AccessibilityPermissionState,
        records: [RawWindowRecord]
    ) -> WindowInventory {
        guard permissionState == .granted else {
            return WindowInventory(
                permissionState: .permissionMissing,
                restorationCandidates: [],
                skippedWindows: []
            )
        }

        var ordinalsByProcess: [Int32: Int] = [:]
        var candidates: [WindowSnapshot] = []
        var skipped: [SkippedWindowSnapshot] = []

        for record in records {
            if let reason = skipReason(for: record) {
                skipped.append(SkippedWindowSnapshot(
                    appName: record.appName,
                    processIdentifier: record.processIdentifier,
                    titleHint: record.titleHint,
                    reason: reason
                ))
                continue
            }

            guard let frame = record.frame else {
                skipped.append(SkippedWindowSnapshot(
                    appName: record.appName,
                    processIdentifier: record.processIdentifier,
                    titleHint: record.titleHint,
                    reason: .missingFrame
                ))
                continue
            }

            let ordinal = ordinalsByProcess[record.processIdentifier, default: 0]
            ordinalsByProcess[record.processIdentifier] = ordinal + 1
            candidates.append(WindowSnapshot(
                appName: record.appName,
                bundleIdentifier: record.bundleIdentifier,
                processIdentifier: record.processIdentifier,
                appLocalOrdinal: ordinal,
                role: record.role,
                subrole: record.subrole,
                titleHint: record.titleHint,
                frame: frame,
                isMinimized: record.isMinimized,
                canMove: record.canMove,
                canResize: record.canResize
            ))
        }

        return WindowInventory(
            permissionState: .granted,
            restorationCandidates: candidates,
            skippedWindows: skipped
        )
    }

    private static func skipReason(for record: RawWindowRecord) -> WindowSkipReason? {
        if record.isApplicationHidden {
            return .hiddenApplication
        }

        guard record.role == "AXWindow" else {
            return .systemSpecial
        }

        if let subrole = record.subrole,
           !["AXStandardWindow", "AXDialog"].contains(subrole) {
            return .systemSpecial
        }

        if record.isFullscreenLike {
            return .fullscreenLike
        }

        if !record.canMove {
            return .nonMovable
        }

        if !record.canResize {
            return .nonResizable
        }

        return nil
    }
}
