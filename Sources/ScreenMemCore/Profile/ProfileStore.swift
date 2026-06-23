import Foundation

public enum ProfileStoreError: Error, Equatable {
    case emptyDisplaySet
}

public struct ProfileStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static var `default`: ProfileStore {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return ProfileStore(fileURL: baseURL.appendingPathComponent("ScreenMem/profiles.json"))
    }

    public func loadProfiles() throws -> [Profile] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try Self.decoder.decode([Profile].self, from: data)
    }

    public func saveProfiles(_ profiles: [Profile]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try Self.encoder.encode(profiles)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func createProfileFromCurrentDisplays(
        name: String,
        snapshots: [DisplaySnapshot],
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) throws -> Profile {
        guard !snapshots.isEmpty else {
            throw ProfileStoreError.emptyDisplaySet
        }

        var profiles = try loadProfiles()
        let displays = snapshots.map(\.identity)
        let profile = Profile(
            id: id,
            name: name,
            createdAt: createdAt,
            displayFingerprint: DisplaySetFingerprint.exact(for: displays),
            displays: displays,
            windowStates: []
        )
        profiles.append(profile)
        try saveProfiles(profiles)
        return profile
    }

    public func matchingProfile(for snapshots: [DisplaySnapshot]) throws -> Profile? {
        let fingerprint = DisplaySetFingerprint.exact(for: snapshots)
        return try loadProfiles().first { profile in
            profile.displayFingerprint == fingerprint
        }
    }

    public func updateProfile(_ updatedProfile: Profile) throws {
        var profiles = try loadProfiles()
        guard let index = profiles.firstIndex(where: { $0.id == updatedProfile.id }) else {
            return
        }
        profiles[index] = updatedProfile
        try saveProfiles(profiles)
    }

    public func renameProfile(id: UUID, to name: String) throws {
        guard let profile = try loadProfiles().first(where: { $0.id == id }) else {
            return
        }
        try updateProfile(Profile(
            id: profile.id,
            name: name,
            createdAt: profile.createdAt,
            displayFingerprint: profile.displayFingerprint,
            displays: profile.displays,
            windowStates: profile.windowStates
        ))
    }

    public func deleteProfile(id: UUID) throws {
        try saveProfiles(try loadProfiles().filter { $0.id != id })
    }

    public func duplicateProfile(id: UUID, newID: UUID = UUID(), createdAt: Date = Date()) throws -> Profile? {
        guard let profile = try loadProfiles().first(where: { $0.id == id }) else {
            return nil
        }
        let copy = Profile(
            id: newID,
            name: "\(profile.name) Copy",
            createdAt: createdAt,
            displayFingerprint: profile.displayFingerprint,
            displays: profile.displays,
            windowStates: profile.windowStates
        )
        var profiles = try loadProfiles()
        profiles.append(copy)
        try saveProfiles(profiles)
        return copy
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
