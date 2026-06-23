import Foundation

public protocol WindowProviding: Sendable {
    @MainActor
    func currentWindowInventory() -> WindowInventory
}

public struct LiveWindowProvider: WindowProviding {
    private let inventory: AccessibilityWindowInventory

    public init(inventory: AccessibilityWindowInventory = AccessibilityWindowInventory()) {
        self.inventory = inventory
    }

    @MainActor
    public func currentWindowInventory() -> WindowInventory {
        inventory.currentInventory()
    }
}

public struct MockWindowProvider: WindowProviding {
    private let inventory: WindowInventory

    public init(inventory: WindowInventory) {
        self.inventory = inventory
    }

    @MainActor
    public func currentWindowInventory() -> WindowInventory {
        inventory
    }
}
