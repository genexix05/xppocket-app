import Foundation

/// Canonical on-disk names for a game's container layout.
///
/// Shared between the app and GameProbe so tests, migrations, and
/// cloud-save filtering stay aligned when a directory is renamed.
public enum GameContainerPaths {
    public static let gameDirectoryName = "Game"
    public static let userDataDirectoryName = "UserData"
    public static let playerDataDirectoryName = "PlayerData"
    public static let logsDirectoryName = "Logs"
    public static let metadataDirectoryName = "Metadata"

    /// Pre–XP Pocket folder name. Migrated to `playerDataDirectoryName`
    /// at launch by `GameContainerMigration`.
    public static let legacyPlayerDataDirectoryName = "EmpoState"

    public static func playerDataURL(in container: URL) -> URL {
        container.appendingPathComponent(playerDataDirectoryName, isDirectory: true)
    }

    public static func legacyPlayerDataURL(in container: URL) -> URL {
        container.appendingPathComponent(legacyPlayerDataDirectoryName, isDirectory: true)
    }
}
