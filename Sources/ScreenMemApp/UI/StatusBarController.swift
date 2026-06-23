import AppKit
import ScreenMemCore

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let onCreateProfileFromCurrentDisplays: () -> Void
    private let onOpenAccessibilitySettings: () -> Void
    private let onRestoreNow: () -> Void
    private let onTogglePauseRestore: () -> Void
    private let onTogglePauseLearning: () -> Void
    private let onTogglePauseAll: () -> Void
    private let onOpenProfiles: () -> Void
    private let onOpenPermissions: () -> Void
    private let onOpenRecentRestoreReport: () -> Void

    init(
        menuModel: StatusMenuModel,
        statusBar: NSStatusBar = .system,
        onCreateProfileFromCurrentDisplays: @escaping () -> Void = {},
        onOpenAccessibilitySettings: @escaping () -> Void = {},
        onRestoreNow: @escaping () -> Void = {},
        onTogglePauseRestore: @escaping () -> Void = {},
        onTogglePauseLearning: @escaping () -> Void = {},
        onTogglePauseAll: @escaping () -> Void = {},
        onOpenProfiles: @escaping () -> Void = {},
        onOpenPermissions: @escaping () -> Void = {},
        onOpenRecentRestoreReport: @escaping () -> Void = {}
    ) {
        self.onCreateProfileFromCurrentDisplays = onCreateProfileFromCurrentDisplays
        self.onOpenAccessibilitySettings = onOpenAccessibilitySettings
        self.onRestoreNow = onRestoreNow
        self.onTogglePauseRestore = onTogglePauseRestore
        self.onTogglePauseLearning = onTogglePauseLearning
        self.onTogglePauseAll = onTogglePauseAll
        self.onOpenProfiles = onOpenProfiles
        self.onOpenPermissions = onOpenPermissions
        self.onOpenRecentRestoreReport = onOpenRecentRestoreReport
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = ApplicationIdentity.name
        update(menuModel: menuModel)
    }

    func update(menuModel: StatusMenuModel) {
        statusItem.menu = makeMenu(from: menuModel)
    }

    private func makeMenu(from model: StatusMenuModel) -> NSMenu {
        let menu = NSMenu()

        for item in model.items {
            switch item.command {
            case .none:
                let menuItem = NSMenuItem(title: item.title, action: nil, keyEquivalent: "")
                menuItem.isEnabled = item.isEnabled
                menu.addItem(menuItem)
            case .createProfileFromCurrentDisplays:
                let menuItem = NSMenuItem(
                    title: item.title,
                    action: #selector(createProfileFromCurrentDisplays(_:)),
                    keyEquivalent: ""
                )
                menuItem.target = self
                menuItem.isEnabled = item.isEnabled
                menu.addItem(menuItem)
            case .openAccessibilitySettings:
                let menuItem = NSMenuItem(
                    title: item.title,
                    action: #selector(openAccessibilitySettings(_:)),
                    keyEquivalent: ""
                )
                menuItem.target = self
                menuItem.isEnabled = item.isEnabled
                menu.addItem(menuItem)
            case .restoreNow:
                menu.addItem(actionItem(item, action: #selector(restoreNow(_:))))
            case .togglePauseRestore:
                menu.addItem(actionItem(item, action: #selector(togglePauseRestore(_:))))
            case .togglePauseLearning:
                menu.addItem(actionItem(item, action: #selector(togglePauseLearning(_:))))
            case .togglePauseAll:
                menu.addItem(actionItem(item, action: #selector(togglePauseAll(_:))))
            case .openProfiles:
                menu.addItem(actionItem(item, action: #selector(openProfiles(_:))))
            case .openPermissions:
                menu.addItem(actionItem(item, action: #selector(openPermissions(_:))))
            case .openRecentRestoreReport:
                menu.addItem(actionItem(item, action: #selector(openRecentRestoreReport(_:))))
            case .quit:
                menu.addItem(.separator())
                let menuItem = NSMenuItem(
                    title: item.title,
                    action: #selector(NSApplication.terminate(_:)),
                    keyEquivalent: "q"
                )
                menuItem.target = NSApplication.shared
                menuItem.isEnabled = item.isEnabled
                menu.addItem(menuItem)
            }
        }

        return menu
    }

    private func actionItem(_ item: StatusMenuItem, action: Selector) -> NSMenuItem {
        let menuItem = NSMenuItem(title: item.title, action: action, keyEquivalent: "")
        menuItem.target = self
        menuItem.isEnabled = item.isEnabled
        return menuItem
    }

    @objc private func createProfileFromCurrentDisplays(_ sender: NSMenuItem) {
        onCreateProfileFromCurrentDisplays()
    }

    @objc private func openAccessibilitySettings(_ sender: NSMenuItem) {
        onOpenAccessibilitySettings()
    }

    @objc private func restoreNow(_ sender: NSMenuItem) {
        onRestoreNow()
    }

    @objc private func togglePauseRestore(_ sender: NSMenuItem) {
        onTogglePauseRestore()
    }

    @objc private func togglePauseLearning(_ sender: NSMenuItem) {
        onTogglePauseLearning()
    }

    @objc private func togglePauseAll(_ sender: NSMenuItem) {
        onTogglePauseAll()
    }

    @objc private func openProfiles(_ sender: NSMenuItem) {
        onOpenProfiles()
    }

    @objc private func openPermissions(_ sender: NSMenuItem) {
        onOpenPermissions()
    }

    @objc private func openRecentRestoreReport(_ sender: NSMenuItem) {
        onOpenRecentRestoreReport()
    }
}
