import Foundation

public enum ProfileSelection: Equatable, Sendable {
    case exact(Profile)
    case partial(Profile)
    case none
}

public enum ProfileSelector {
    public static func select(profiles: [Profile], displaySnapshots: [DisplaySnapshot]) -> ProfileSelection {
        let currentFingerprint = DisplaySetFingerprint.exact(for: displaySnapshots)
        if let exact = profiles.first(where: { $0.displayFingerprint == currentFingerprint }) {
            return .exact(exact)
        }

        let currentIDs = Set(displaySnapshots.map(\.identity.stableID))
        let scoredProfiles = profiles.compactMap { profile -> (profile: Profile, score: Int)? in
            let profileIDs = Set(profile.displays.map(\.stableID))
            let score = profileIDs.intersection(currentIDs).count
            return score > 0 ? (profile, score) : nil
        }

        guard let best = scoredProfiles.max(by: { left, right in
            if left.score != right.score {
                return left.score < right.score
            }
            return left.profile.createdAt < right.profile.createdAt
        }) else {
            return .none
        }

        return .partial(best.profile)
    }
}
