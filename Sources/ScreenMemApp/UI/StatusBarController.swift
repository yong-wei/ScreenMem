import AppKit
import ScreenMemCore

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let onCreateProfileFromCurrentDisplays: () -> Void

    init(
        menuModel: StatusMenuModel,
        statusBar: NSStatusBar = .system,
        onCreateProfileFromCurrentDisplays: @escaping () -> Void = {}
    ) {
        self.onCreateProfileFromCurrentDisplays = onCreateProfileFromCurrentDisplays
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = ApplicationIdentity.name
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

    @objc private func createProfileFromCurrentDisplays(_ sender: NSMenuItem) {
        onCreateProfileFromCurrentDisplays()
    }
}
