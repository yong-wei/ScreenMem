import AppKit
import ScreenMemCore

@main
@MainActor
final class ScreenMemApplication: NSObject, NSApplicationDelegate {
    private static var sharedDelegate: ScreenMemApplication?

    private var statusBarController: StatusBarController?
    private let profileStore: ProfileStore
    private let permissionService: AccessibilityPermissionService

    override init() {
        self.profileStore = .default
        self.permissionService = AccessibilityPermissionService()
        super.init()
    }

    static func main() {
        if CommandLine.arguments.contains("--smoke-check") {
            print(StatusMenuModel.default.statusTitle)
            return
        }

        let app = NSApplication.shared
        let delegate = ScreenMemApplication()
        sharedDelegate = delegate
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let permissionState = permissionService.permissionState()
        statusBarController = StatusBarController(
            menuModel: StatusMenuModel.make(permissionState: permissionState),
            onCreateProfileFromCurrentDisplays: { [weak self] in
                self?.createProfileFromCurrentDisplays()
            },
            onOpenAccessibilitySettings: {
                NSWorkspace.shared.open(AccessibilityPermissionService.settingsURL)
            }
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func createProfileFromCurrentDisplays() {
        do {
            let snapshots = DisplaySampler.currentSnapshots()
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let profile = try profileStore.createProfileFromCurrentDisplays(
                name: "Display Profile \(timestamp)",
                snapshots: snapshots
            )
            NSLog("ScreenMem created display profile %@", profile.name)
        } catch {
            NSLog("ScreenMem failed to create display profile: %@", String(describing: error))
        }
    }
}
