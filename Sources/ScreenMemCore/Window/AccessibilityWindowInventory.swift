import AppKit
import ApplicationServices
import Foundation

public struct AccessibilityWindowInventory: Sendable {
    private let permissionService: AccessibilityPermissionService

    public init(permissionService: AccessibilityPermissionService = AccessibilityPermissionService()) {
        self.permissionService = permissionService
    }

    @MainActor
    public func currentInventory() -> WindowInventory {
        let permissionState = permissionService.permissionState()
        guard permissionState == .granted else {
            return WindowInventoryFilter.makeInventory(permissionState: permissionState, records: [])
        }

        let records = NSWorkspace.shared.runningApplications.flatMap { application in
            rawRecords(for: application)
        }
        return WindowInventoryFilter.makeInventory(permissionState: permissionState, records: records)
    }

    @MainActor
    private func rawRecords(for application: NSRunningApplication) -> [RawWindowRecord] {
        guard !application.isTerminated else {
            return []
        }

        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        guard let windows = copyAttribute(appElement, kAXWindowsAttribute) as [AXUIElement]? else {
            return []
        }

        return windows.map { window in
            RawWindowRecord(
                appName: application.localizedName ?? "Unknown App",
                bundleIdentifier: application.bundleIdentifier,
                processIdentifier: application.processIdentifier,
                role: copyAttribute(window, kAXRoleAttribute),
                subrole: copyAttribute(window, kAXSubroleAttribute),
                titleHint: copyAttribute(window, kAXTitleAttribute),
                frame: windowFrame(window),
                isMinimized: copyAttribute(window, kAXMinimizedAttribute) ?? false,
                canMove: isAttributeSettable(window, kAXPositionAttribute),
                canResize: isAttributeSettable(window, kAXSizeAttribute),
                isApplicationHidden: application.isHidden,
                isFullscreenLike: copyAttribute(window, "AXFullScreen") ?? false
            )
        }
    }
}

private func copyAttribute<T>(_ element: AXUIElement, _ attribute: String) -> T? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
        return nil
    }
    return value as? T
}

private func windowFrame(_ window: AXUIElement) -> WindowRect? {
    guard let position: AXValue = copyAttribute(window, kAXPositionAttribute),
          let size: AXValue = copyAttribute(window, kAXSizeAttribute) else {
        return nil
    }

    var point = CGPoint.zero
    var cgSize = CGSize.zero
    guard AXValueGetValue(position, .cgPoint, &point),
          AXValueGetValue(size, .cgSize, &cgSize) else {
        return nil
    }

    return WindowRect(
        x: Double(point.x),
        y: Double(point.y),
        width: Double(cgSize.width),
        height: Double(cgSize.height)
    )
}

private func isAttributeSettable(_ element: AXUIElement, _ attribute: String) -> Bool {
    var settable = DarwinBoolean(false)
    guard AXUIElementIsAttributeSettable(element, attribute as CFString, &settable) == .success else {
        return false
    }
    return settable.boolValue
}
