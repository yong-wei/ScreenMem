import AppKit
import ScreenMemCore

@main
@MainActor
final class ScreenMemApplication: NSObject, NSApplicationDelegate {
    private static var sharedDelegate: ScreenMemApplication?

    private var statusBarController: StatusBarController?
    private let profileStore: ProfileStore
    private let permissionService: AccessibilityPermissionService
    private let displayProvider: any DisplayProviding
    private var pauseState = AutomationPauseState.none
    private var recentRestoreReport: RestoreReport?
    private var detailWindowController: NSWindowController?

    init(displayProvider: any DisplayProviding = LiveDisplayProvider()) {
        self.profileStore = .default
        self.permissionService = AccessibilityPermissionService()
        self.displayProvider = displayProvider
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
        rebuildStatusMenu()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func rebuildStatusMenu() {
        let permissionState = permissionService.permissionState()
        let viewState = MenuViewState(
            profileName: (try? profileStore.loadProfiles().first?.name) ?? nil,
            automationState: pauseState.allPaused ? .paused : .learning,
            displayCount: displayProvider.currentDisplaySnapshots().count,
            permissionState: permissionState,
            pauseState: pauseState,
            recentReport: RestoreReportViewModel(report: recentRestoreReport)
        )
        let menuModel = StatusMenuModel.make(viewState: viewState)
        if let statusBarController {
            statusBarController.update(menuModel: menuModel)
        } else {
            statusBarController = StatusBarController(
                menuModel: menuModel,
                onCreateProfileFromCurrentDisplays: { [weak self] in
                    self?.createProfileFromCurrentDisplays()
                },
                onOpenAccessibilitySettings: {
                    NSWorkspace.shared.open(AccessibilityPermissionService.settingsURL)
                },
                onRestoreNow: { [weak self] in
                    self?.restoreNow()
                },
                onTogglePauseRestore: { [weak self] in
                    self?.togglePauseRestore()
                },
                onTogglePauseLearning: { [weak self] in
                    self?.togglePauseLearning()
                },
                onTogglePauseAll: { [weak self] in
                    self?.togglePauseAll()
                },
                onOpenProfiles: { [weak self] in
                    self?.openProfilesWindow()
                },
                onOpenPermissions: { [weak self] in
                    self?.openPermissionsWindow()
                },
                onOpenRecentRestoreReport: { [weak self] in
                    self?.openRecentRestoreReportWindow()
                }
            )
        }
    }

    private func createProfileFromCurrentDisplays() {
        do {
            let snapshots = displayProvider.currentDisplaySnapshots()
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let profile = try profileStore.createProfileFromCurrentDisplays(
                name: "Display Profile \(timestamp)",
                snapshots: snapshots
            )
            NSLog("ScreenMem created display profile %@", profile.name)
            rebuildStatusMenu()
        } catch {
            NSLog("ScreenMem failed to create display profile: %@", String(describing: error))
        }
    }

    private func restoreNow() {
        recentRestoreReport = RestoreReport(
            restoredWindows: [],
            skippedWindows: [SkippedRestoreReport(identity: nil, reason: pauseState.allowsRestore ? .noExactProfile : .automationPaused)],
            failedWindows: []
        )
        rebuildStatusMenu()
    }

    private func togglePauseRestore() {
        pauseState = AutomationPauseState(
            restorePaused: !pauseState.restorePaused,
            learningPaused: pauseState.learningPaused,
            allPaused: pauseState.allPaused
        )
        rebuildStatusMenu()
    }

    private func togglePauseLearning() {
        pauseState = AutomationPauseState(
            restorePaused: pauseState.restorePaused,
            learningPaused: !pauseState.learningPaused,
            allPaused: pauseState.allPaused
        )
        rebuildStatusMenu()
    }

    private func togglePauseAll() {
        pauseState = AutomationPauseState(
            restorePaused: pauseState.restorePaused,
            learningPaused: pauseState.learningPaused,
            allPaused: !pauseState.allPaused
        )
        rebuildStatusMenu()
    }

    private func openProfilesWindow() {
        let profiles = (try? profileStore.loadProfiles()) ?? []
        showDetailWindow(
            title: "Profiles",
            lines: profiles.isEmpty ? ["No profiles"] : profiles.map { $0.name }
        )
    }

    private func openPermissionsWindow() {
        let viewModel = PermissionsViewModel(state: permissionService.permissionState())
        showDetailWindow(
            title: "Permissions",
            lines: ["Accessibility: \(viewModel.state.rawValue)", viewModel.settingsURL.absoluteString]
        )
    }

    private func openRecentRestoreReportWindow() {
        let viewModel = RestoreReportViewModel(report: recentRestoreReport)
        let rows = viewModel.rows.map { "\($0.title): \($0.outcome)" }
        showDetailWindow(title: "Recent Restore Report", lines: [viewModel.summary] + rows)
    }

    private func showDetailWindow(title: String, lines: [String]) {
        let text = NSTextView(frame: NSRect(x: 0, y: 0, width: 520, height: 260))
        text.string = lines.joined(separator: "\n")
        text.isEditable = false
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 260),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.contentView = text
        window.center()
        let controller = NSWindowController(window: window)
        detailWindowController = controller
        controller.showWindow(nil)
    }
}
