import Foundation

public struct ProfileManagementState: Equatable, Sendable {
    public let profiles: [Profile]
    public let manualRestoreSourceID: UUID?

    public init(profiles: [Profile], manualRestoreSourceID: UUID?) {
        self.profiles = profiles
        self.manualRestoreSourceID = manualRestoreSourceID
    }

    public func renamed(id: UUID, to name: String) -> ProfileManagementState {
        ProfileManagementState(
            profiles: profiles.map { profile in
                guard profile.id == id else {
                    return profile
                }
                return Profile(
                    id: profile.id,
                    name: name,
                    createdAt: profile.createdAt,
                    displayFingerprint: profile.displayFingerprint,
                    displays: profile.displays,
                    windowStates: profile.windowStates
                )
            },
            manualRestoreSourceID: manualRestoreSourceID
        )
    }

    public func deleted(id: UUID) -> ProfileManagementState {
        ProfileManagementState(
            profiles: profiles.filter { $0.id != id },
            manualRestoreSourceID: manualRestoreSourceID == id ? nil : manualRestoreSourceID
        )
    }

    public func duplicated(id: UUID, newID: UUID, createdAt: Date) -> ProfileManagementState {
        guard let profile = profiles.first(where: { $0.id == id }) else {
            return self
        }
        let copy = Profile(
            id: newID,
            name: "\(profile.name) Copy",
            createdAt: createdAt,
            displayFingerprint: profile.displayFingerprint,
            displays: profile.displays,
            windowStates: profile.windowStates
        )
        return ProfileManagementState(profiles: profiles + [copy], manualRestoreSourceID: manualRestoreSourceID)
    }

    public func selectedManualRestoreSource(id: UUID?) -> ProfileManagementState {
        ProfileManagementState(profiles: profiles, manualRestoreSourceID: id)
    }
}
