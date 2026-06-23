import Foundation
import ScreenMemCore

struct CheckFailure: Error, CustomStringConvertible {
    let description: String
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw CheckFailure(description: message)
    }
}

func expectClose(_ actual: Double, _ expected: Double, _ message: String) throws {
    try expect(abs(actual - expected) < 0.000_001, message)
}

func expectValue<T>(_ value: T?, _ message: String) throws -> T {
    guard let value else {
        throw CheckFailure(description: message)
    }
    return value
}

func checkDefaultStatusMenuContainsStatusTextAndQuitCommand() throws {
    let menu = StatusMenuModel.default

    try expect(menu.statusTitle == "ScreenMem: Ready", "status title should describe the static menu state")
    try expect(menu.items.map(\.title).contains("Profile: None"), "menu should show current profile")
    try expect(menu.items.map(\.title).contains("State: Learning"), "menu should show learning state")
    try expect(menu.items.map(\.title).contains("Displays: 0"), "menu should show display count")
    try expect(menu.items.contains { $0.command == .restoreNow }, "menu should contain Restore Now")
    try expect(menu.items.contains { $0.command == .createProfileFromCurrentDisplays }, "menu should contain profile creation")
    try expect(menu.items.contains { $0.command == .togglePauseRestore }, "menu should contain Pause Restore")
    try expect(menu.items.contains { $0.command == .togglePauseLearning }, "menu should contain Pause Learning")
    try expect(menu.items.contains { $0.command == .togglePauseAll }, "menu should contain Pause All")
    try expect(menu.items.first?.isEnabled == false, "status menu item should be disabled")
    try expect(menu.items.last?.command == .quit, "last menu item should quit the app")
}

func checkMenuStatusShowsProfileStateDisplayAndReport() throws {
    let report = RestoreReport(
        restoredWindows: [RestoredWindowReport(identity: LearnedWindowIdentity(
            bundleIdentifier: "dev.screenmem.fixture",
            processIdentifier: 1,
            appLocalOrdinal: 0,
            titleHint: "Editor"
        ), targetFrame: WindowRect(x: 0, y: 0, width: 100, height: 100))],
        skippedWindows: [SkippedRestoreReport(identity: nil, reason: .noExactProfile)],
        failedWindows: []
    )
    let menu = StatusMenuModel.make(viewState: MenuViewState(
        profileName: "Desk",
        automationState: .learning,
        displayCount: 2,
        permissionState: .granted,
        pauseState: .none,
        recentReport: RestoreReportViewModel(report: report)
    ))
    let titles = menu.items.map(\.title)

    try expect(titles.contains("Profile: Desk"), "menu should show exact profile name")
    try expect(titles.contains("State: Learning"), "menu should show automation state")
    try expect(titles.contains("Displays: 2"), "menu should show display count")
    try expect(titles.contains("Latest Restore: Restored 1, skipped 1, failed 0"), "menu should show recent restore summary")
}

func checkPauseStateGuardsRestoreAndLearning() throws {
    let pauseAll = AutomationPauseState(allPaused: true)
    let engine = WindowRestorationEngine { _, _ in .moved }
    let restoreReport = engine.restoreExactProfile(
        profile: nil,
        displaySnapshots: [],
        currentWindows: [],
        pauseState: pauseAll
    )
    try expect(restoreReport.skippedWindows.map(\.reason) == [.automationPaused], "pause all should block restore")

    let display = sampleDisplayIdentity("Pause", builtIn: true)
    let sample = sampleDisplaySnapshot(display, orderIndex: 0)
    let learning = ProfileLearningService().poll(
        mode: .learning,
        profile: learningProfile(display: display),
        displaySnapshots: [sample],
        windowSnapshots: [learningWindow(title: "A")],
        priorSample: nil,
        now: Date(timeIntervalSince1970: 1),
        pauseState: pauseAll
    )
    try expect(learning.profileToSave == nil && learning.sample == nil, "pause all should block learning")
}

func checkRestoreReportViewModelExplainsOutcomes() throws {
    let identity = LearnedWindowIdentity(
        bundleIdentifier: "dev.screenmem.fixture",
        processIdentifier: 1,
        appLocalOrdinal: 0,
        titleHint: "Editor"
    )
    let viewModel = RestoreReportViewModel(report: RestoreReport(
        restoredWindows: [RestoredWindowReport(identity: identity, targetFrame: WindowRect(x: 0, y: 0, width: 100, height: 100))],
        skippedWindows: [SkippedRestoreReport(identity: identity, reason: .noCurrentWindowMatch)],
        failedWindows: [FailedRestoreReport(identity: identity, reason: .moveRejected)]
    ))

    try expect(viewModel.summary == "Restored 1, skipped 1, failed 1", "report summary should count outcomes")
    try expect(viewModel.rows.contains(RestoreReportRow(title: "Editor", outcome: "Skipped: noCurrentWindowMatch")), "report should explain skipped reason")
    try expect(viewModel.rows.contains(RestoreReportRow(title: "Editor", outcome: "Failed: moveRejected")), "report should explain failure reason")
}

func checkProfileManagementActions() throws {
    let display = sampleDisplayIdentity("Profile", builtIn: true)
    let profile = learningProfile(display: display)
    let state = ProfileManagementState(profiles: [profile], manualRestoreSourceID: nil)
    let renamed = state.renamed(id: profile.id, to: "Renamed")
    let duplicated = renamed.duplicated(
        id: profile.id,
        newID: UUID(uuidString: "00000000-0000-0000-0000-000000000050")!,
        createdAt: Date(timeIntervalSince1970: 5)
    )
    let selected = duplicated.selectedManualRestoreSource(id: profile.id)
    let deleted = selected.deleted(id: profile.id)

    try expect(renamed.profiles.first?.name == "Renamed", "profile view model should rename")
    try expect(duplicated.profiles.count == 2, "profile view model should duplicate")
    try expect(selected.manualRestoreSourceID == profile.id, "profile view model should select manual restore source")
    try expect(deleted.profiles.count == 1 && deleted.manualRestoreSourceID == nil, "profile view model should delete and clear manual source")
}

func checkPermissionMissingMenuExposesSettingsAction() throws {
    let menu = StatusMenuModel.make(permissionState: .permissionMissing)

    try expect(menu.items.map(\.title).contains("Permission Missing"), "permission missing state should be visible")
    try expect(
        menu.items.contains { $0.command == .openAccessibilitySettings && $0.isEnabled },
        "permission missing menu should expose Accessibility settings action"
    )
}

func rawWindow(
    processIdentifier: Int32,
    title: String,
    role: String? = "AXWindow",
    subrole: String? = "AXStandardWindow",
    frame: WindowRect? = WindowRect(x: 10, y: 20, width: 400, height: 300),
    canMove: Bool = true,
    canResize: Bool = true,
    isApplicationHidden: Bool = false,
    isFullscreenLike: Bool = false
) -> RawWindowRecord {
    RawWindowRecord(
        appName: "Fixture App",
        bundleIdentifier: "dev.screenmem.fixture",
        processIdentifier: processIdentifier,
        role: role,
        subrole: subrole,
        titleHint: title,
        frame: frame,
        isMinimized: false,
        canMove: canMove,
        canResize: canResize,
        isApplicationHidden: isApplicationHidden,
        isFullscreenLike: isFullscreenLike
    )
}

func checkPermissionMissingPreventsWindowEnumeration() throws {
    let permissionService = AccessibilityPermissionService { _ in false }
    let inventory = WindowInventoryFilter.makeInventory(
        permissionState: permissionService.permissionState(),
        records: [rawWindow(processIdentifier: 100, title: "Should Not Enumerate")]
    )

    try expect(inventory.permissionState == .permissionMissing, "inventory should report missing permission")
    try expect(inventory.restorationCandidates.isEmpty, "missing permission should not produce candidates")
    try expect(inventory.skippedWindows.isEmpty, "missing permission should not inspect skipped windows")
}

func checkOrdinaryWindowFilteringAndOrdinals() throws {
    let inventory = WindowInventoryFilter.makeInventory(
        permissionState: .granted,
        records: [
            rawWindow(processIdentifier: 100, title: "First"),
            rawWindow(processIdentifier: 100, title: "Second"),
            rawWindow(processIdentifier: 200, title: "Fullscreen", isFullscreenLike: true),
            rawWindow(processIdentifier: 201, title: "Hidden", isApplicationHidden: true),
            rawWindow(processIdentifier: 202, title: "System", role: "AXSheet"),
            rawWindow(processIdentifier: 203, title: "Fixed", canMove: false),
            rawWindow(processIdentifier: 204, title: "Locked Size", canResize: false),
            rawWindow(processIdentifier: 205, title: "No Frame", frame: nil)
        ]
    )

    try expect(inventory.permissionState == .granted, "inventory should report granted permission")
    try expect(inventory.restorationCandidates.count == 2, "only ordinary windows should be candidates")
    try expect(
        inventory.restorationCandidates.map(\.appLocalOrdinal) == [0, 1],
        "multiple app windows should receive stable app-local ordinals"
    )
    try expect(
        inventory.restorationCandidates.map(\.titleHint) == ["First", "Second"],
        "ordinary windows should preserve title hints"
    )
    try expect(
        Set(inventory.skippedWindows.map(\.reason)) == [
            .fullscreenLike,
            .hiddenApplication,
            .systemSpecial,
            .nonMovable,
            .nonResizable,
            .missingFrame
        ],
        "unsupported windows should record skip reasons"
    )
}

func sampleDisplayIdentity(_ suffix: String, builtIn: Bool = false) -> DisplayIdentity {
    DisplayIdentity(
        isBuiltIn: builtIn,
        name: "Display \(suffix)",
        vendorID: 100,
        productID: 200,
        serialNumber: UInt32(suffix.unicodeScalars.first?.value ?? 0),
        nominalPixelSize: DisplaySize(width: 1920, height: 1080),
        backingScaleFactor: 2.0
    )
}

func sampleDisplaySnapshot(_ identity: DisplayIdentity, orderIndex: Int) -> DisplaySnapshot {
    DisplaySnapshot(
        identity: identity,
        frame: DisplayRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: DisplayRect(x: 0, y: 25, width: 1440, height: 875),
        isMain: orderIndex == 0,
        orderIndex: orderIndex
    )
}

func checkDisplayFingerprintIsOrderIndependent() throws {
    let builtIn = sampleDisplayIdentity("A", builtIn: true)
    let external = sampleDisplayIdentity("B")

    let first = DisplaySetFingerprint.exact(for: [builtIn, external])
    let second = DisplaySetFingerprint.exact(for: [external, builtIn])

    try expect(first == second, "display-set fingerprint should ignore display order")
    try expect(first.contains("builtin:1"), "fingerprint should include built-in display identity")
}

@MainActor
func checkCurrentDisplaySamplerEnumeratesDisplays() throws {
    let snapshots = DisplaySampler.currentSnapshots()

    try expect(!snapshots.isEmpty, "current display sampler should return at least one display")
    try expect(snapshots.filter(\.isMain).count <= 1, "current display sampler should mark at most one main display")

    for (expectedIndex, snapshot) in snapshots.enumerated() {
        try expect(snapshot.orderIndex == expectedIndex, "display order index should match sampled order")
        try expect(!snapshot.identity.stableID.isEmpty, "display identity should include a stable id")
        try expect(!snapshot.identity.name.isEmpty, "display identity should include a display name")
        try expect(snapshot.identity.nominalPixelSize.width > 0, "display identity should include nominal pixel width")
        try expect(snapshot.identity.nominalPixelSize.height > 0, "display identity should include nominal pixel height")
        try expect(snapshot.identity.backingScaleFactor > 0, "display identity should include backing scale")
        try expect(snapshot.frame.width > 0, "display snapshot should include frame width")
        try expect(snapshot.frame.height > 0, "display snapshot should include frame height")
        try expect(snapshot.visibleFrame.width > 0, "display snapshot should include visible frame width")
        try expect(snapshot.visibleFrame.height > 0, "display snapshot should include visible frame height")
    }
}

func checkProfileStoreCreatesAndLoadsUserProfiles() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("ScreenMemShellChecks-\(UUID().uuidString)")
    defer {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    let store = ProfileStore(fileURL: tempRoot.appendingPathComponent("profiles.json"))
    let identity = sampleDisplayIdentity("A", builtIn: true)
    let snapshot = sampleDisplaySnapshot(identity, orderIndex: 0)
    let createdAt = Date(timeIntervalSince1970: 1_800_000_000)
    let profile = try store.createProfileFromCurrentDisplays(
        name: "Desk",
        snapshots: [snapshot],
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        createdAt: createdAt
    )

    try expect(profile.name == "Desk", "created profile should keep the requested name")
    try expect(FileManager.default.fileExists(atPath: store.fileURL.path), "profile store should write JSON")
    let loadedProfiles = try store.loadProfiles()
    let matchingProfile = try store.matchingProfile(for: [snapshot])
    try expect(loadedProfiles == [profile], "profile store should load saved profiles")
    try expect(matchingProfile == profile, "matching profile should be found by fingerprint")
}

func checkNormalizedRectClampsAgainstVisibleFrame() throws {
    let visibleFrame = DisplayRect(x: 100, y: 50, width: 1000, height: 500)
    let windowFrame = WindowRect(x: 50, y: 100, width: 1200, height: 250)
    let normalized = WindowGeometryNormalizer.normalize(windowFrame, in: visibleFrame)

    try expect(normalized.x == 0, "normalized x should clamp below visible frame")
    try expect(normalized.y == 0.1, "normalized y should be relative to visible frame")
    try expect(normalized.width == 1, "normalized width should clamp to visible frame")
    try expect(normalized.height == 0.5, "normalized height should be relative to visible frame")

    let denormalized = WindowGeometryNormalizer.denormalize(normalized, in: visibleFrame)
    try expect(denormalized.x == 100, "denormalized x should use visible frame origin")
    try expect(denormalized.y == 100, "denormalized y should use visible frame origin")
    try expect(denormalized.width == 1000, "denormalized width should use visible frame width")
    try expect(denormalized.height == 250, "denormalized height should use visible frame height")

    let overflowing = WindowGeometryNormalizer.denormalize(
        NormalizedRect(x: 0.9, y: 0.8, width: 0.4, height: 0.4),
        in: visibleFrame
    )
    try expect(overflowing.x + overflowing.width <= visibleFrame.x + visibleFrame.width, "denormalized rect should not overflow right edge")
    try expect(overflowing.y + overflowing.height <= visibleFrame.y + visibleFrame.height, "denormalized rect should not overflow bottom edge")
}

func learningProfile(display: DisplayIdentity, createdAt: Date = Date(timeIntervalSince1970: 1)) -> Profile {
    Profile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
        name: "Learning",
        createdAt: createdAt,
        displayFingerprint: DisplaySetFingerprint.exact(for: [display]),
        displays: [display],
        windowStates: []
    )
}

func learningWindow(title: String, ordinal: Int = 0) -> WindowSnapshot {
    WindowSnapshot(
        appName: "Fixture App",
        bundleIdentifier: "dev.screenmem.fixture",
        processIdentifier: 300,
        appLocalOrdinal: ordinal,
        role: "AXWindow",
        subrole: "AXStandardWindow",
        titleHint: title,
        frame: WindowRect(x: 100, y: 100, width: 400, height: 300),
        isMinimized: false,
        canMove: true,
        canResize: true
    )
}

func learningWindow(title: String, x: Double, y: Double, width: Double = 400, height: Double = 300) -> WindowSnapshot {
    WindowSnapshot(
        appName: "Fixture App",
        bundleIdentifier: "dev.screenmem.fixture",
        processIdentifier: 300,
        appLocalOrdinal: 0,
        role: "AXWindow",
        subrole: "AXStandardWindow",
        titleHint: title,
        frame: WindowRect(x: x, y: y, width: width, height: height),
        isMinimized: false,
        canMove: true,
        canResize: true
    )
}

func checkLearningWritesOnlyForExactLearningState() throws {
    let display = sampleDisplayIdentity("L", builtIn: true)
    let matchingSnapshot = sampleDisplaySnapshot(display, orderIndex: 0)
    let otherSnapshot = sampleDisplaySnapshot(sampleDisplayIdentity("X"), orderIndex: 0)
    let service = ProfileLearningService(configuration: ProfileLearningConfiguration(debounceInterval: 1))
    let profile = learningProfile(display: display)
    let now = Date(timeIntervalSince1970: 2_000_000_000)

    let stopped = service.poll(
        mode: .stopped,
        profile: profile,
        displaySnapshots: [matchingSnapshot],
        windowSnapshots: [learningWindow(title: "A")],
        priorSample: nil,
        now: now
    )
    try expect(stopped.profileToSave == nil && stopped.sample == nil, "stopped mode should not write or sample")

    let unknownDisplay = service.poll(
        mode: .learning,
        profile: profile,
        displaySnapshots: [otherSnapshot],
        windowSnapshots: [learningWindow(title: "A")],
        priorSample: nil,
        now: now
    )
    try expect(unknownDisplay.profileToSave == nil && unknownDisplay.sample == nil, "unknown display set should not write")
}

func checkLearningDebouncesStableWindowState() throws {
    let display = sampleDisplayIdentity("L", builtIn: true)
    let snapshot = sampleDisplaySnapshot(display, orderIndex: 0)
    let service = ProfileLearningService(configuration: ProfileLearningConfiguration(debounceInterval: 1))
    let profile = learningProfile(display: display)
    let firstTime = Date(timeIntervalSince1970: 2_000_000_000)

    let first = service.poll(
        mode: .learning,
        profile: profile,
        displaySnapshots: [snapshot],
        windowSnapshots: [learningWindow(title: "A")],
        priorSample: nil,
        now: firstTime
    )
    try expect(first.profileToSave == nil, "first learning sample should not save before debounce")

    let moved = WindowSnapshot(
        appName: "Fixture App",
        bundleIdentifier: "dev.screenmem.fixture",
        processIdentifier: 300,
        appLocalOrdinal: 0,
        role: "AXWindow",
        subrole: "AXStandardWindow",
        titleHint: "A",
        frame: WindowRect(x: 200, y: 100, width: 400, height: 300),
        isMinimized: false,
        canMove: true,
        canResize: true
    )
    let moving = service.poll(
        mode: .learning,
        profile: profile,
        displaySnapshots: [snapshot],
        windowSnapshots: [moved],
        priorSample: first.sample,
        now: firstTime.addingTimeInterval(0.5)
    )
    try expect(moving.profileToSave == nil, "changed state inside debounce should not save")

    let stable = service.poll(
        mode: .learning,
        profile: profile,
        displaySnapshots: [snapshot],
        windowSnapshots: [moved],
        priorSample: moving.sample,
        now: firstTime.addingTimeInterval(1.6)
    )
    try expect(stable.profileToSave?.windowStates.count == 1, "stable final state should save after debounce")
    let expectedX = moved.frame.x / snapshot.visibleFrame.width
    try expectClose(
        stable.profileToSave?.windowStates.first?.normalizedFrame.x ?? -1,
        expectedX,
        "saved state should reflect final stable window position"
    )
}

func checkLearningAssignsWindowsToIntersectingDisplay() throws {
    let leftDisplay = sampleDisplayIdentity("L", builtIn: true)
    let rightDisplay = sampleDisplayIdentity("R")
    let leftSnapshot = DisplaySnapshot(
        identity: leftDisplay,
        frame: DisplayRect(x: 0, y: 0, width: 1000, height: 800),
        visibleFrame: DisplayRect(x: 0, y: 0, width: 1000, height: 800),
        isMain: true,
        orderIndex: 0
    )
    let rightSnapshot = DisplaySnapshot(
        identity: rightDisplay,
        frame: DisplayRect(x: 1000, y: 0, width: 1000, height: 800),
        visibleFrame: DisplayRect(x: 1000, y: 0, width: 1000, height: 800),
        isMain: false,
        orderIndex: 1
    )
    let profile = Profile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
        name: "Dual Display",
        createdAt: Date(timeIntervalSince1970: 1),
        displayFingerprint: DisplaySetFingerprint.exact(for: [leftDisplay, rightDisplay]),
        displays: [leftDisplay, rightDisplay],
        windowStates: []
    )
    let service = ProfileLearningService(configuration: ProfileLearningConfiguration(debounceInterval: 1))
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    let window = learningWindow(title: "Right", x: 1200, y: 100)
    let first = service.poll(
        mode: .learning,
        profile: profile,
        displaySnapshots: [leftSnapshot, rightSnapshot],
        windowSnapshots: [window],
        priorSample: nil,
        now: now
    )
    let stable = service.poll(
        mode: .learning,
        profile: profile,
        displaySnapshots: [leftSnapshot, rightSnapshot],
        windowSnapshots: [window],
        priorSample: first.sample,
        now: now.addingTimeInterval(1.2)
    )

    let learnedState = try expectValue(stable.profileToSave?.windowStates.first, "stable multi-display state should save")
    try expect(learnedState.displayStableID == rightDisplay.stableID, "window should be learned against intersecting display")
    try expectClose(learnedState.normalizedFrame.x, 0.2, "window x should be normalized against right display")
}

func checkLearningTombstonesRecentlyMissingWindows() throws {
    let display = sampleDisplayIdentity("L", builtIn: true)
    let snapshot = sampleDisplaySnapshot(display, orderIndex: 0)
    let service = ProfileLearningService(
        configuration: ProfileLearningConfiguration(debounceInterval: 1, tombstoneGracePeriod: 5)
    )
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    let state = WindowState(
        identity: LearnedWindowIdentity(snapshot: learningWindow(title: "A")),
        normalizedFrame: NormalizedRect(x: 0.1, y: 0.1, width: 0.4, height: 0.3),
        displayStableID: display.stableID,
        learnedAt: now,
        tombstone: nil
    )
    let profile = Profile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
        name: "Learning",
        createdAt: now,
        displayFingerprint: DisplaySetFingerprint.exact(for: [display]),
        displays: [display],
        windowStates: [state]
    )

    let missing = service.poll(
        mode: .learning,
        profile: profile,
        displaySnapshots: [snapshot],
        windowSnapshots: [],
        priorSample: nil,
        now: now.addingTimeInterval(1)
    )
    try expect(missing.sample?.windowStates.first?.tombstone != nil, "missing window should become tombstoned")

    let retained = service.poll(
        mode: .learning,
        profile: profile,
        displaySnapshots: [snapshot],
        windowSnapshots: [],
        priorSample: missing.sample,
        now: now.addingTimeInterval(2.2)
    )
    try expect(retained.profileToSave?.windowStates.count == 1, "recent tombstone should be retained")

    let expired = service.poll(
        mode: .learning,
        profile: profile,
        displaySnapshots: [snapshot],
        windowSnapshots: [],
        priorSample: retained.sample,
        now: now.addingTimeInterval(8)
    )
    try expect(expired.profileToSave?.windowStates.isEmpty == true, "expired tombstone should be deleted")
}

func checkRestorationStateMachineProtectsLearningWrites() throws {
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    let protected = RestorationStateMachine.displayChangeDetected(currentState: .learning, now: now)

    try expect(!RestorationStateMachine.allowsLearningWrites(protected), "display change should stop learning writes")

    let waiting = RestorationStateMachine.displaysSampledStable(
        currentState: protected,
        now: now.addingTimeInterval(1),
        stabilizationInterval: 2
    )
    try expect(!RestorationStateMachine.allowsLearningWrites(waiting), "stable wait should still protect learning writes")

    let restoring = RestorationStateMachine.displaysSampledStable(
        currentState: waiting,
        now: now.addingTimeInterval(4),
        stabilizationInterval: 2
    )
    try expect(restoring == .restoring, "stable display set should enter restoring state")
    try expect(
        RestorationStateMachine.restorationCompleted(currentState: restoring) == .learning,
        "completed restoration should return to learning"
    )
}

func restorationProfile(display: DisplayIdentity, states: [WindowState]) -> Profile {
    Profile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
        name: "Restore",
        createdAt: Date(timeIntervalSince1970: 1),
        displayFingerprint: DisplaySetFingerprint.exact(for: [display]),
        displays: [display],
        windowStates: states
    )
}

func learnedState(
    snapshot: WindowSnapshot,
    display: DisplayIdentity,
    normalizedFrame: NormalizedRect = NormalizedRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
) -> WindowState {
    WindowState(
        identity: LearnedWindowIdentity(snapshot: snapshot),
        normalizedFrame: normalizedFrame,
        displayStableID: display.stableID,
        learnedAt: Date(timeIntervalSince1970: 2),
        tombstone: nil
    )
}

final class MoveAttemptRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var titles: [String] = []

    func append(_ title: String) {
        lock.lock()
        titles.append(title)
        lock.unlock()
    }

    func snapshot() -> [String] {
        lock.lock()
        let currentTitles = titles
        lock.unlock()
        return currentTitles
    }
}

final class MoveTargetRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var frames: [WindowRect] = []

    func append(_ frame: WindowRect) {
        lock.lock()
        frames.append(frame)
        lock.unlock()
    }

    func snapshot() -> [WindowRect] {
        lock.lock()
        let currentFrames = frames
        lock.unlock()
        return currentFrames
    }
}

func checkWindowMatcherMatchesLearnedIdentity() throws {
    let first = learningWindow(title: "A", ordinal: 0)
    let second = learningWindow(title: "B", ordinal: 1)
    let display = sampleDisplayIdentity("R")
    let matches = WindowMatcher.match(
        currentWindows: [second, first],
        learnedStates: [learnedState(snapshot: first, display: display)]
    )

    try expect(matches.map(\.snapshot.titleHint) == ["A"], "matcher should match by learned identity")
}

func checkExactProfileRestoresMatchedWindowsAndContinuesAfterFailure() throws {
    let display = sampleDisplayIdentity("R", builtIn: true)
    let displaySnapshot = sampleDisplaySnapshot(display, orderIndex: 0)
    let first = learningWindow(title: "A", ordinal: 0)
    let second = learningWindow(title: "B", ordinal: 1)
    let firstState = learnedState(snapshot: first, display: display)
    let secondState = learnedState(
        snapshot: second,
        display: display,
        normalizedFrame: NormalizedRect(x: 0.2, y: 0.2, width: 0.3, height: 0.4)
    )
    let profile = restorationProfile(display: display, states: [firstState, secondState])
    let recorder = MoveAttemptRecorder()
    let engine = WindowRestorationEngine { snapshot, _ in
        recorder.append(snapshot.titleHint ?? "")
        return snapshot.titleHint == "A" ? .rejected : .moved
    }

    let report = engine.restoreExactProfile(
        profile: profile,
        displaySnapshots: [displaySnapshot],
        currentWindows: [first, second]
    )

    try expect(recorder.snapshot() == ["A", "B"], "restore should continue after one rejected move")
    try expect(report.failedWindows.map(\.identity.titleHint) == ["A"], "restore report should record rejected window")
    try expect(report.restoredWindows.map(\.identity.titleHint) == ["B"], "restore report should record restored window")
}

func checkRestorationRequiresExactProfile() throws {
    let display = sampleDisplayIdentity("R", builtIn: true)
    let otherDisplay = sampleDisplayIdentity("Other")
    let profile = restorationProfile(display: display, states: [])
    let engine = WindowRestorationEngine { _, _ in .moved }

    let report = engine.restoreExactProfile(
        profile: profile,
        displaySnapshots: [sampleDisplaySnapshot(otherDisplay, orderIndex: 0)],
        currentWindows: []
    )

    try expect(report.restoredWindows.isEmpty, "non-exact profile should not restore windows")
    try expect(report.skippedWindows.map(\.reason) == [.noExactProfile], "non-exact profile should be reported")
}

func checkRestorationSkipsAmbiguousDisplaysWithoutCrashing() throws {
    let display = sampleDisplayIdentity("D")
    let firstDisplay = DisplaySnapshot(
        identity: display,
        frame: DisplayRect(x: 0, y: 0, width: 1000, height: 800),
        visibleFrame: DisplayRect(x: 0, y: 0, width: 1000, height: 800),
        isMain: true,
        orderIndex: 0
    )
    let duplicateDisplay = DisplaySnapshot(
        identity: display,
        frame: DisplayRect(x: 1000, y: 0, width: 1000, height: 800),
        visibleFrame: DisplayRect(x: 1000, y: 0, width: 1000, height: 800),
        isMain: false,
        orderIndex: 1
    )
    let window = learningWindow(title: "A")
    let profile = Profile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
        name: "Ambiguous",
        createdAt: Date(timeIntervalSince1970: 1),
        displayFingerprint: DisplaySetFingerprint.exact(for: [display, display]),
        displays: [display, display],
        windowStates: [learnedState(snapshot: window, display: display)]
    )
    let engine = WindowRestorationEngine { _, _ in .moved }

    let report = engine.restoreExactProfile(
        profile: profile,
        displaySnapshots: [firstDisplay, duplicateDisplay],
        currentWindows: [window]
    )

    try expect(report.restoredWindows.isEmpty, "ambiguous display target should not restore")
    try expect(report.skippedWindows.map(\.reason) == [.displayAmbiguous], "ambiguous display target should be reported")
}

func checkProfileSelectorChoosesExactPartialAndNone() throws {
    let builtIn = sampleDisplayIdentity("BuiltIn", builtIn: true)
    let external = sampleDisplayIdentity("External")
    let iPad = sampleDisplayIdentity("iPad")
    let olderProfile = Profile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000030")!,
        name: "Older",
        createdAt: Date(timeIntervalSince1970: 1),
        displayFingerprint: DisplaySetFingerprint.exact(for: [builtIn]),
        displays: [builtIn],
        windowStates: []
    )
    let officeProfile = Profile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000031")!,
        name: "Office",
        createdAt: Date(timeIntervalSince1970: 2),
        displayFingerprint: DisplaySetFingerprint.exact(for: [builtIn, external]),
        displays: [builtIn, external],
        windowStates: []
    )
    let exact = ProfileSelector.select(
        profiles: [olderProfile, officeProfile],
        displaySnapshots: [sampleDisplaySnapshot(builtIn, orderIndex: 0), sampleDisplaySnapshot(external, orderIndex: 1)]
    )
    try expect(exact == .exact(officeProfile), "selector should prefer exact profile")

    let partial = ProfileSelector.select(
        profiles: [olderProfile, officeProfile],
        displaySnapshots: [
            sampleDisplaySnapshot(builtIn, orderIndex: 0),
            sampleDisplaySnapshot(external, orderIndex: 1),
            sampleDisplaySnapshot(iPad, orderIndex: 2)
        ]
    )
    try expect(partial == .partial(officeProfile), "selector should choose largest partial overlap")

    let none = ProfileSelector.select(
        profiles: [olderProfile, officeProfile],
        displaySnapshots: [sampleDisplaySnapshot(sampleDisplayIdentity("Unknown"), orderIndex: 0)]
    )
    try expect(none == .none, "selector should return none with no overlap")
}

func checkPartialRestoreFallsBackToKnownBuiltInDisplay() throws {
    let builtIn = sampleDisplayIdentity("BuiltIn", builtIn: true)
    let absentExternal = sampleDisplayIdentity("External")
    let iPad = sampleDisplayIdentity("iPad")
    let currentBuiltIn = DisplaySnapshot(
        identity: builtIn,
        frame: DisplayRect(x: 0, y: 0, width: 1000, height: 800),
        visibleFrame: DisplayRect(x: 0, y: 0, width: 1000, height: 800),
        isMain: true,
        orderIndex: 0
    )
    let newDisplay = DisplaySnapshot(
        identity: iPad,
        frame: DisplayRect(x: 1000, y: 0, width: 1000, height: 800),
        visibleFrame: DisplayRect(x: 1000, y: 0, width: 1000, height: 800),
        isMain: false,
        orderIndex: 1
    )
    let window = learningWindow(title: "External Window")
    let state = WindowState(
        identity: LearnedWindowIdentity(snapshot: window),
        normalizedFrame: NormalizedRect(x: 0.1, y: 0.1, width: 0.4, height: 0.3),
        displayStableID: absentExternal.stableID,
        learnedAt: Date(timeIntervalSince1970: 3),
        tombstone: nil
    )
    let profile = Profile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000032")!,
        name: "Partial",
        createdAt: Date(timeIntervalSince1970: 2),
        displayFingerprint: DisplaySetFingerprint.exact(for: [builtIn, absentExternal]),
        displays: [builtIn, absentExternal],
        windowStates: [state]
    )
    let recorder = MoveTargetRecorder()
    let engine = WindowRestorationEngine { _, frame in
        recorder.append(frame)
        return .moved
    }

    let report = engine.restorePartialProfile(
        profile: profile,
        displaySnapshots: [currentBuiltIn, newDisplay],
        currentWindows: [window]
    )

    try expect(report.restoredWindows.count == 1, "partial restore should restore missing-target window to fallback")
    let targetFrame = try expectValue(recorder.snapshot().first, "partial restore should move to a target frame")
    try expect(targetFrame.x >= currentBuiltIn.visibleFrame.x, "fallback target should be on known built-in display")
    try expect(
        targetFrame.x + targetFrame.width <= currentBuiltIn.visibleFrame.x + currentBuiltIn.visibleFrame.width,
        "fallback target should not use newly introduced display"
    )
}

func checkPartialRestoreFallsBackToKnownMainDisplayWithoutBuiltIn() throws {
    let knownMain = sampleDisplayIdentity("KnownMain")
    let absentExternal = sampleDisplayIdentity("External")
    let newDisplayIdentity = sampleDisplayIdentity("New")
    let currentKnownMain = DisplaySnapshot(
        identity: knownMain,
        frame: DisplayRect(x: 0, y: 0, width: 900, height: 700),
        visibleFrame: DisplayRect(x: 0, y: 0, width: 900, height: 700),
        isMain: true,
        orderIndex: 0
    )
    let newDisplay = DisplaySnapshot(
        identity: newDisplayIdentity,
        frame: DisplayRect(x: 900, y: 0, width: 900, height: 700),
        visibleFrame: DisplayRect(x: 900, y: 0, width: 900, height: 700),
        isMain: false,
        orderIndex: 1
    )
    let window = learningWindow(title: "External Window")
    let profile = Profile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000033")!,
        name: "Partial Main",
        createdAt: Date(timeIntervalSince1970: 2),
        displayFingerprint: DisplaySetFingerprint.exact(for: [knownMain, absentExternal]),
        displays: [knownMain, absentExternal],
        windowStates: [
            WindowState(
                identity: LearnedWindowIdentity(snapshot: window),
                normalizedFrame: NormalizedRect(x: 0.2, y: 0.2, width: 0.4, height: 0.3),
                displayStableID: absentExternal.stableID,
                learnedAt: Date(timeIntervalSince1970: 3),
                tombstone: nil
            )
        ]
    )
    let recorder = MoveTargetRecorder()
    let engine = WindowRestorationEngine { _, frame in
        recorder.append(frame)
        return .moved
    }

    let report = engine.restorePartialProfile(
        profile: profile,
        displaySnapshots: [currentKnownMain, newDisplay],
        currentWindows: [window]
    )

    try expect(report.restoredWindows.count == 1, "partial restore should use known main fallback without built-in")
    let targetFrame = try expectValue(recorder.snapshot().first, "partial restore should move to known main frame")
    try expect(targetFrame.x >= currentKnownMain.visibleFrame.x, "fallback target should be on known main display")
    try expect(
        targetFrame.x + targetFrame.width <= currentKnownMain.visibleFrame.x + currentKnownMain.visibleFrame.width,
        "fallback target should not use newly introduced display when no built-in exists"
    )
}

func checkPartialRestoreExitsToUnmanagedAndDoesNotLearn() throws {
    let display = sampleDisplayIdentity("Partial", builtIn: true)
    let snapshot = sampleDisplaySnapshot(display, orderIndex: 0)
    let partialCompleted = RestorationStateMachine.restorationCompleted(
        currentState: .restoring,
        exactProfileMatched: false
    )
    try expect(partialCompleted == .unmanaged, "partial restore should exit to unmanaged")
    try expect(!RestorationStateMachine.allowsLearningWrites(partialCompleted), "unmanaged state should block learning writes")

    let service = ProfileLearningService()
    let result = service.poll(
        mode: .stopped,
        profile: learningProfile(display: display),
        displaySnapshots: [snapshot],
        windowSnapshots: [learningWindow(title: "A")],
        priorSample: nil,
        now: Date(timeIntervalSince1970: 4)
    )
    try expect(result.profileToSave == nil, "partial unmanaged flow should not write profile state")
}

func lateWindowProfile(display: DisplayIdentity, window: WindowSnapshot) -> Profile {
    Profile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000040")!,
        name: "Late",
        createdAt: Date(timeIntervalSince1970: 1),
        displayFingerprint: DisplaySetFingerprint.exact(for: [display]),
        displays: [display],
        windowStates: [learnedState(snapshot: window, display: display)]
    )
}

func checkLateWindowRestoresOnceWithinMonitoringPeriod() throws {
    let display = sampleDisplayIdentity("Late", builtIn: true)
    let displaySnapshot = sampleDisplaySnapshot(display, orderIndex: 0)
    let window = learningWindow(title: "Late")
    let profile = lateWindowProfile(display: display, window: window)
    let initialReport = RestoreReport(
        restoredWindows: [],
        skippedWindows: [SkippedRestoreReport(identity: LearnedWindowIdentity(snapshot: window), reason: .noCurrentWindowMatch)],
        failedWindows: []
    )
    let monitor = LateWindowMonitor.start(
        profile: profile,
        restoredReport: initialReport,
        startedAt: Date(timeIntervalSince1970: 10)
    )
    let recorder = MoveTargetRecorder()
    let appeared = monitor.restoreNewWindows(
        currentWindows: [window],
        displaySnapshots: [displaySnapshot],
        now: Date(timeIntervalSince1970: 20),
        profileID: profile.id,
        moveWindow: { _, frame in
            recorder.append(frame)
            return .moved
        }
    )

    try expect(appeared.report.lateRestoredWindows.isEmpty, "first late observation should not move immediately")
    try expect(recorder.snapshot().isEmpty, "first late observation should only record frame")
    let result = try expectValue(appeared.monitor, "late monitor should remain active after first observation")
        .restoreNewWindows(
            currentWindows: [window],
            displaySnapshots: [displaySnapshot],
            now: Date(timeIntervalSince1970: 21),
            profileID: profile.id,
            moveWindow: { _, frame in
                recorder.append(frame)
                return .moved
            }
        )
    try expect(result.report.lateRestoredWindows.count == 1, "late matching window should restore within monitoring period")
    try expect(result.monitor == nil, "late restored window should be removed from monitor")
    try expect(recorder.snapshot().count == 1, "late window should be moved once")
}

func checkRestorationRunStartsLateWindowMonitor() throws {
    let display = sampleDisplayIdentity("Late", builtIn: true)
    let displaySnapshot = sampleDisplaySnapshot(display, orderIndex: 0)
    let window = learningWindow(title: "Late")
    let profile = lateWindowProfile(display: display, window: window)
    let engine = WindowRestorationEngine { _, _ in .moved }

    let result = engine.restoreExactProfileStartingLateMonitor(
        profile: profile,
        displaySnapshots: [displaySnapshot],
        currentWindows: [],
        startedAt: Date(timeIntervalSince1970: 10)
    )

    try expect(result.report.skippedWindows.map(\.reason) == [.noCurrentWindowMatch], "initial restore should report unresolved learned state")
    try expect(result.lateWindowMonitor?.pendingStates.map(\.identity) == [LearnedWindowIdentity(snapshot: window)], "restore run should start monitor for unresolved learned state")
}

func checkLateWindowMonitorExpires() throws {
    let display = sampleDisplayIdentity("Late", builtIn: true)
    let window = learningWindow(title: "Late")
    let profile = lateWindowProfile(display: display, window: window)
    let monitor = LateWindowMonitor(
        profileID: profile.id,
        startedAt: Date(timeIntervalSince1970: 10),
        pendingStates: profile.windowStates
    )
    let recorder = MoveTargetRecorder()
    let result = monitor.restoreNewWindows(
        currentWindows: [window],
        displaySnapshots: [sampleDisplaySnapshot(display, orderIndex: 0)],
        now: Date(timeIntervalSince1970: 71),
        profileID: profile.id,
        moveWindow: { _, frame in
            recorder.append(frame)
            return .moved
        }
    )

    try expect(result.monitor == nil, "late monitor should stop after expiration")
    try expect(recorder.snapshot().isEmpty, "expired monitor should not move late windows")
    try expect(result.report.lateSkippedWindows.map(\.reason) == [.monitoringExpired], "expired late window should be reported")
}

func checkLateWindowManualMovementIsRespected() throws {
    let display = sampleDisplayIdentity("Late", builtIn: true)
    let displaySnapshot = sampleDisplaySnapshot(display, orderIndex: 0)
    let originalWindow = learningWindow(title: "Late")
    let movedWindow = WindowSnapshot(
        appName: originalWindow.appName,
        bundleIdentifier: originalWindow.bundleIdentifier,
        processIdentifier: originalWindow.processIdentifier,
        appLocalOrdinal: originalWindow.appLocalOrdinal,
        role: originalWindow.role,
        subrole: originalWindow.subrole,
        titleHint: originalWindow.titleHint,
        frame: WindowRect(x: originalWindow.frame.x + 50, y: originalWindow.frame.y, width: originalWindow.frame.width, height: originalWindow.frame.height),
        isMinimized: originalWindow.isMinimized,
        canMove: originalWindow.canMove,
        canResize: originalWindow.canResize
    )
    let profile = lateWindowProfile(display: display, window: originalWindow)
    let monitor = LateWindowMonitor(
        profileID: profile.id,
        startedAt: Date(timeIntervalSince1970: 10),
        pendingStates: profile.windowStates
    )
    let recorder = MoveTargetRecorder()
    let appeared = monitor.restoreNewWindows(
        currentWindows: [originalWindow],
        displaySnapshots: [displaySnapshot],
        now: Date(timeIntervalSince1970: 20),
        profileID: profile.id,
        moveWindow: { _, frame in
            recorder.append(frame)
            return .moved
        }
    )
    let result = try expectValue(appeared.monitor, "late monitor should remain active after appearance")
        .restoreNewWindows(
            currentWindows: [movedWindow],
            displaySnapshots: [displaySnapshot],
            now: Date(timeIntervalSince1970: 21),
            profileID: profile.id,
            moveWindow: { _, frame in
                recorder.append(frame)
                return .moved
            }
        )

    try expect(recorder.snapshot().isEmpty, "manually moved late window should not be restored")
    try expect(result.report.lateSkippedWindows.map(\.reason) == [.manualMovementDetected], "manual movement should be reported")
    try expect(result.monitor == nil, "manually moved late window should be removed from monitor")
}

func checkLateWindowRejectedMoveIsNotRetried() throws {
    let display = sampleDisplayIdentity("Late", builtIn: true)
    let displaySnapshot = sampleDisplaySnapshot(display, orderIndex: 0)
    let window = learningWindow(title: "Late")
    let profile = lateWindowProfile(display: display, window: window)
    let monitor = LateWindowMonitor(
        profileID: profile.id,
        startedAt: Date(timeIntervalSince1970: 10),
        pendingStates: profile.windowStates,
        appearedFrames: [LearnedWindowIdentity(snapshot: window): window.frame]
    )
    let recorder = MoveAttemptRecorder()

    let result = monitor.restoreNewWindows(
        currentWindows: [window],
        displaySnapshots: [displaySnapshot],
        now: Date(timeIntervalSince1970: 20),
        profileID: profile.id,
        moveWindow: { snapshot, _ in
            recorder.append(snapshot.titleHint ?? "")
            return .rejected
        }
    )

    try expect(result.report.failedWindows.map(\.identity.titleHint) == ["Late"], "rejected late restore should be reported")
    try expect(result.monitor == nil, "rejected late restore should not be retried")
    try expect(recorder.snapshot() == ["Late"], "rejected late restore should be attempted once")
}

func checkUnknownDisplaySetDoesNotCreateProfileAutomatically() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("ScreenMemShellChecks-\(UUID().uuidString)")
    defer {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    let store = ProfileStore(fileURL: tempRoot.appendingPathComponent("profiles.json"))
    let snapshot = sampleDisplaySnapshot(sampleDisplayIdentity("Z"), orderIndex: 0)
    let matchingProfile = try store.matchingProfile(for: [snapshot])

    try expect(matchingProfile == nil, "unknown display set should not match a profile")
    try expect(!FileManager.default.fileExists(atPath: store.fileURL.path), "matching should not create a profile file")
}

func checkRequiredModuleFoldersExist() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let folders = [
        "AppEntry",
        "Display",
        "Window",
        "Profile",
        "Engine",
        "UI",
        "Logging"
    ]

    for folder in folders {
        let path = root.appendingPathComponent("Sources/ScreenMemCore/\(folder)").path
        try expect(FileManager.default.fileExists(atPath: path), "missing module folder: \(folder)")
    }
}

func checkReadmeDocumentsMvpScopeAndNonGoals() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let readme = try String(contentsOf: root.appendingPathComponent("README.md"))

    try expect(readme.contains("Restore only currently existing ordinary windows"), "README should state existing-window-only MVP scope")
    try expect(readme.contains("does not launch missing apps"), "README should exclude launching missing apps")
    try expect(readme.contains("create closed windows"), "README should exclude creating windows")
    try expect(readme.contains("restore browser tabs"), "README should exclude browser tab restoration")
    try expect(readme.contains("manage true fullscreen windows"), "README should exclude true fullscreen windows")
    try expect(readme.contains("move windows across Spaces"), "README should exclude Space movement")
    try expect(readme.contains("sync data through the cloud"), "README should exclude cloud sync")
}

func checkBuildRunnerBuildsAndLaunchesScreenMemExecutable() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let script = try String(contentsOf: root.appendingPathComponent("script/build_and_run.sh"))

    try expect(script.contains("swift build"), "runner should build the app")
    try expect(script.contains("APP_DIR=\"${ROOT_DIR}/.build/ScreenMem.app\""), "runner should create a local app bundle")
    try expect(script.contains("mkdir -p \"$APP_DIR/Contents/MacOS\""), "runner should create the bundle executable directory")
    try expect(script.contains("cp \"${BIN_DIR}/ScreenMem\" \"$APP_DIR/Contents/MacOS/ScreenMem\""), "runner should copy the built executable into the bundle")
    try expect(script.contains("codesign --force --sign - --identifier dev.screenmem.ScreenMem \"$APP_DIR\""), "runner should ad-hoc sign the generated app bundle")
    try expect(script.contains("APP_EXECUTABLE=\"${BIN_DIR}/ScreenMem\""), "runner should launch the SwiftPM build artifact")
    try expect(script.contains("MODE=\"${1:-run}\""), "runner should support a default run mode")
    try expect(script.contains("--smoke-test"), "runner should expose a bounded launch verification mode")
    try expect(script.contains("\"$APP_EXECUTABLE\" --smoke-check"), "runner smoke test should execute the app smoke check")
    try expect(script.contains("ScreenMem smoke check completed."), "runner smoke test should report a completed smoke check")
    try expect(script.contains("exec \"$APP_EXECUTABLE\""), "runner should launch the app in the foreground by default")
    try expect(script.contains("PID_FILE=\"${ROOT_DIR}/.logs/screenmem.pid\""), "runner should define the launched pid path")
    try expect(script.contains("echo \"$$\" > \"$PID_FILE\""), "runner should persist the foreground app pid")
    try expect(!script.contains("open -g"), "runner should not depend on LaunchServices for local debug launch")
    try expect(!script.contains("launchctl submit"), "runner should not depend on launchd for local debug launch")
}

func checkStatusMenuRebuildReusesStatusItem() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let controller = try String(contentsOf: root.appendingPathComponent("Sources/ScreenMemApp/UI/StatusBarController.swift"))
    let application = try String(contentsOf: root.appendingPathComponent("Sources/ScreenMemApp/AppEntry/ScreenMemApplication.swift"))

    try expect(controller.contains("func update(menuModel: StatusMenuModel)"), "status controller should update menu without creating a new item")
    try expect(application.contains("if let statusBarController"), "application should reuse the existing status controller")
    try expect(application.contains("statusBarController.update(menuModel: menuModel)"), "menu rebuild should update existing status item")
}

func checkCodexEnvironmentExposesAppRunner() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let environment = try String(contentsOf: root.appendingPathComponent(".codex/environments/environment.toml"))

    try expect(environment.contains("app-runner"), "environment should expose an app runner command")
    try expect(environment.contains("script/build_and_run.sh"), "app runner should call the local build script")
}

@main
@MainActor
enum ScreenMemShellChecks {
    static func main() {
        let checks: [(String, () throws -> Void)] = [
            ("default status menu contains status text and quit command", checkDefaultStatusMenuContainsStatusTextAndQuitCommand),
            ("menu status shows profile state display and report", checkMenuStatusShowsProfileStateDisplayAndReport),
            ("pause state guards restore and learning", checkPauseStateGuardsRestoreAndLearning),
            ("restore report view model explains outcomes", checkRestoreReportViewModelExplainsOutcomes),
            ("profile management actions", checkProfileManagementActions),
            ("permission missing menu exposes settings action", checkPermissionMissingMenuExposesSettingsAction),
            ("permission missing prevents window enumeration", checkPermissionMissingPreventsWindowEnumeration),
            ("ordinary window filtering and ordinals", checkOrdinaryWindowFilteringAndOrdinals),
            ("display fingerprint is order independent", checkDisplayFingerprintIsOrderIndependent),
            ("current display sampler enumerates displays", checkCurrentDisplaySamplerEnumeratesDisplays),
            ("profile store creates and loads user profiles", checkProfileStoreCreatesAndLoadsUserProfiles),
            ("normalized rect clamps against visible frame", checkNormalizedRectClampsAgainstVisibleFrame),
            ("learning writes only for exact learning state", checkLearningWritesOnlyForExactLearningState),
            ("learning debounces stable window state", checkLearningDebouncesStableWindowState),
            ("learning assigns windows to intersecting display", checkLearningAssignsWindowsToIntersectingDisplay),
            ("learning tombstones recently missing windows", checkLearningTombstonesRecentlyMissingWindows),
            ("restoration state machine protects learning writes", checkRestorationStateMachineProtectsLearningWrites),
            ("window matcher matches learned identity", checkWindowMatcherMatchesLearnedIdentity),
            ("exact profile restores matched windows and continues after failure", checkExactProfileRestoresMatchedWindowsAndContinuesAfterFailure),
            ("restoration requires exact profile", checkRestorationRequiresExactProfile),
            ("restoration skips ambiguous displays without crashing", checkRestorationSkipsAmbiguousDisplaysWithoutCrashing),
            ("profile selector chooses exact partial and none", checkProfileSelectorChoosesExactPartialAndNone),
            ("partial restore falls back to known built-in display", checkPartialRestoreFallsBackToKnownBuiltInDisplay),
            ("partial restore falls back to known main display without built-in", checkPartialRestoreFallsBackToKnownMainDisplayWithoutBuiltIn),
            ("partial restore exits to unmanaged and does not learn", checkPartialRestoreExitsToUnmanagedAndDoesNotLearn),
            ("restoration run starts late window monitor", checkRestorationRunStartsLateWindowMonitor),
            ("late window restores once within monitoring period", checkLateWindowRestoresOnceWithinMonitoringPeriod),
            ("late window monitor expires", checkLateWindowMonitorExpires),
            ("late window manual movement is respected", checkLateWindowManualMovementIsRespected),
            ("late window rejected move is not retried", checkLateWindowRejectedMoveIsNotRetried),
            ("unknown display set does not create a profile automatically", checkUnknownDisplaySetDoesNotCreateProfileAutomatically),
            ("required module folders exist", checkRequiredModuleFoldersExist),
            ("README documents MVP scope and non-goals", checkReadmeDocumentsMvpScopeAndNonGoals),
            ("build runner builds and launches ScreenMem executable", checkBuildRunnerBuildsAndLaunchesScreenMemExecutable),
            ("status menu rebuild reuses status item", checkStatusMenuRebuildReusesStatusItem),
            ("Codex environment exposes app runner", checkCodexEnvironmentExposesAppRunner)
        ]

        var failures: [String] = []

        for (name, check) in checks {
            do {
                try check()
                print("PASS: \(name)")
            } catch {
                failures.append("FAIL: \(name): \(error)")
            }
        }

        if !failures.isEmpty {
            for failure in failures {
                FileHandle.standardError.write(Data((failure + "\n").utf8))
            }
            exit(1)
        }
    }
}
