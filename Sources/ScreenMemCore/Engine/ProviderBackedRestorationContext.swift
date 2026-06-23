import Foundation

public struct ProviderBackedRestorationContext {
    private let displayProvider: any DisplayProviding
    private let windowProvider: any WindowProviding
    private let restorationEngine: WindowRestorationEngine

    public init(
        displayProvider: any DisplayProviding,
        windowProvider: any WindowProviding,
        restorationEngine: WindowRestorationEngine
    ) {
        self.displayProvider = displayProvider
        self.windowProvider = windowProvider
        self.restorationEngine = restorationEngine
    }

    @MainActor
    public func selectProfile(from profiles: [Profile]) -> ProfileSelection {
        ProfileSelector.select(
            profiles: profiles,
            displaySnapshots: displayProvider.currentDisplaySnapshots()
        )
    }

    @MainActor
    public func restoreExactProfile(_ profile: Profile?, pauseState: AutomationPauseState = .none) -> RestoreReport {
        restorationEngine.restoreExactProfile(
            profile: profile,
            displaySnapshots: displayProvider.currentDisplaySnapshots(),
            currentWindows: windowProvider.currentWindowInventory().restorationCandidates,
            pauseState: pauseState
        )
    }
}
