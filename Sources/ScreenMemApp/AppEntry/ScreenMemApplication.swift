import AppKit
import ScreenMemCore

@main
@MainActor
final class ScreenMemApplication: NSObject, NSApplicationDelegate {
    private static var sharedDelegate: ScreenMemApplication?

    private var statusBarController: StatusBarController?

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
        statusBarController = StatusBarController(menuModel: .default)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
