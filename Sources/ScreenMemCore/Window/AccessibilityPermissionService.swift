import ApplicationServices
import Foundation

public enum AccessibilityPermissionState: String, Codable, Equatable, Sendable {
    case granted
    case permissionMissing
}

public struct AccessibilityPermissionService: Sendable {
    private let trustCheck: @Sendable (_ prompt: Bool) -> Bool

    public init() {
        self.trustCheck = Self.systemTrustCheck
    }

    public init(trustCheck: @escaping @Sendable (_ prompt: Bool) -> Bool) {
        self.trustCheck = trustCheck
    }

    public func permissionState(prompt: Bool = false) -> AccessibilityPermissionState {
        trustCheck(prompt) ? .granted : .permissionMissing
    }

    public static let settingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )!

    private static func systemTrustCheck(prompt: Bool) -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
