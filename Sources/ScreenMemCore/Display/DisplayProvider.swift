import Foundation

public protocol DisplayProviding: Sendable {
    @MainActor
    func currentDisplaySnapshots() -> [DisplaySnapshot]
}

public struct LiveDisplayProvider: DisplayProviding {
    public init() {}

    @MainActor
    public func currentDisplaySnapshots() -> [DisplaySnapshot] {
        DisplaySampler.currentSnapshots()
    }
}

public struct MockDisplayProvider: DisplayProviding {
    private let snapshots: [DisplaySnapshot]

    public init(snapshots: [DisplaySnapshot]) {
        self.snapshots = snapshots
    }

    @MainActor
    public func currentDisplaySnapshots() -> [DisplaySnapshot] {
        snapshots
    }
}
