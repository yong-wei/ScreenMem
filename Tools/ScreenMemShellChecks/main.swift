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

func checkDefaultStatusMenuContainsStatusTextAndQuitCommand() throws {
    let menu = StatusMenuModel.default

    try expect(menu.statusTitle == "ScreenMem: Ready", "status title should describe the static menu state")
    try expect(
        menu.items.map(\.title) == [
            "ScreenMem: Ready",
            "Create Profile from Current Displays",
            "Quit ScreenMem"
        ],
        "menu should contain status text, profile creation, and Quit"
    )
    try expect(menu.items.first?.isEnabled == false, "status menu item should be disabled")
    try expect(
        menu.items.dropFirst().first?.command == .createProfileFromCurrentDisplays,
        "second menu item should create a display profile"
    )
    try expect(menu.items.last?.command == .quit, "last menu item should quit the app")
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
            ("display fingerprint is order independent", checkDisplayFingerprintIsOrderIndependent),
            ("current display sampler enumerates displays", checkCurrentDisplaySamplerEnumeratesDisplays),
            ("profile store creates and loads user profiles", checkProfileStoreCreatesAndLoadsUserProfiles),
            ("unknown display set does not create a profile automatically", checkUnknownDisplaySetDoesNotCreateProfileAutomatically),
            ("required module folders exist", checkRequiredModuleFoldersExist),
            ("README documents MVP scope and non-goals", checkReadmeDocumentsMvpScopeAndNonGoals),
            ("build runner builds and launches ScreenMem executable", checkBuildRunnerBuildsAndLaunchesScreenMemExecutable),
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
