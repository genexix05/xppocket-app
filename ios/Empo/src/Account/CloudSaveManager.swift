import CryptoKit
import Foundation
import GameProbe

/// Zip and restore saves from every location XP Pocket uses on disk.
enum CloudSaveManager {
    private static let manifestFileName = "manifest.json"
    private static let dataPrefix = "data"
    private static let gamePrefix = "game"
    private static let userDataPrefix = "userdata"

    private static let engineFolderNames: Set<String> = [
        "data", "graphics", "audio", "fonts", "system", "movies",
    ]

    private static let saveFolderNames: Set<String> = [
        "save", "saves", "save data", "savedata", "save game",
    ]

    enum Error: LocalizedError {
        case missingContainer
        case emptySaveData(searched: String)
        case packFailed
        case restoreFailed(String)

        var errorDescription: String? {
            switch self {
            case .missingContainer: "This game is not installed on disk."
            case .emptySaveData(let searched):
                "No save data found. Save in-game once, then try again.\n\nSearched:\n\(searched)"
            case .packFailed: "Could not pack save data."
            case .restoreFailed(let detail): detail
            }
        }
    }

    /// The folder cloud saves cover. A core that names no shared data
    /// folder keeps its saves in the game's own `UserData/`.
    private static func dataRoot(for container: GameContainer) -> URL {
        let core = GameCores.core(forGameAt: container.gameURL)
        return DataDirectory.resolve(for: container, core: core)
            ?? container.url.appendingPathComponent("UserData", isDirectory: true)
    }

    private static func dataRootPrepared(for container: GameContainer) -> URL {
        let core = GameCores.core(forGameAt: container.gameURL)
        return DataDirectory.resolveAndPrepare(for: container, core: core)
            ?? container.url.appendingPathComponent("UserData", isDirectory: true)
    }

    static func gameKey(for container: GameContainer) -> String {
        let dataURL = dataRoot(for: container)
        let root = DataDirectory.sharedRootURL.path
        var relative = dataURL.path
        if relative.hasPrefix(root + "/") {
            relative = String(relative.dropFirst(root.count + 1))
        } else if relative == root {
            relative = dataURL.lastPathComponent
        }
        let digest = SHA256.hash(data: Data(relative.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Read-only snapshot of every on-disk save location. Does not
    /// drain or move files (safe while a session is paused).
    static func packData(for container: GameContainer) throws -> Data {
        let fm = FileManager.default
        SaveMigration.migrateLegacySavesIfNeeded(for: container)
        let dataRoot = dataRoot(for: container)
        try? fm.createDirectory(at: dataRoot, withIntermediateDirectories: true)
        var entries: [ZipArchiveWriter.Entry] = []
        var searched: [String] = []

        if fm.fileExists(atPath: dataRoot.path) {
            searched.append("Data: \(dataRoot.path)")
            entries.append(contentsOf: try collectZipEntries(at: dataRoot, prefix: dataPrefix))
        }

        searched.append("Game: \(container.gameURL.path)")
        entries.append(contentsOf: try collectPortableEntries(at: container.gameURL))
        entries.append(contentsOf: try collectDeepGameSaveEntries(at: container.gameURL))

        let userData = container.userDataURL
        if fm.fileExists(atPath: userData.path) {
            searched.append("UserData: \(userData.path)")
            entries.append(contentsOf: try collectZipEntries(at: userData, prefix: userDataPrefix))
        }

        if let legacyRoot = SaveMigration.lingeringLegacySaveDirectory(for: container) {
            searched.append("Legacy: \(legacyRoot.path)")
            entries.append(
                contentsOf: try collectZipEntries(at: legacyRoot, prefix: "\(dataPrefix)/legacy"))
        }

        searched.append("Container: \(container.url.path)")
        entries.append(contentsOf: try collectContainerRootSaveEntries(at: container.url))

        entries = deduplicated(entries)

        entries.removeAll { $0.path == manifestFileName }

        guard !entries.isEmpty else {
            NSLog(
                "[CloudSave] Pack empty for %@. Searched:\n%@",
                container.folderName,
                searched.joined(separator: "\n"))
            throw Error.emptySaveData(searched: searched.joined(separator: "\n"))
        }

        NSLog(
            "[CloudSave] Packed %ld file(s) for %@ (%ld bytes before zip)",
            entries.count - 1,
            container.folderName,
            entries.dropFirst().reduce(0) { $0 + $1.data.count })

        let manifest: [String: Any] = [
            "format": "xppocket-cloud-save",
            "format_version": 1,
            "data_path": dataRelativePath(for: container),
        ]
        guard
            let manifestData = try? JSONSerialization.data(
                withJSONObject: manifest, options: [.sortedKeys])
        else { throw Error.packFailed }
        entries.insert(.init(path: manifestFileName, data: manifestData), at: 0)

        do {
            return try ZipArchiveWriter.archive(entries: entries)
        } catch {
            throw Error.packFailed
        }
    }

    static func applyPack(_ data: Data, to container: GameContainer) throws {
        let fm = FileManager.default
        let dataDestination = dataRootPrepared(for: container)

        let stagingRoot = fm.temporaryDirectory.appendingPathComponent(
            "xppocket-cloud-\(UUID().uuidString)", isDirectory: true)
        let zipURL = stagingRoot.appendingPathComponent("save.zip")
        let extracted = stagingRoot.appendingPathComponent("contents", isDirectory: true)
        defer { try? fm.removeItem(at: stagingRoot) }

        do {
            try fm.createDirectory(at: stagingRoot, withIntermediateDirectories: true)
            try fm.createDirectory(at: extracted, withIntermediateDirectories: true)
            try data.write(to: zipURL, options: .atomic)
            try ArchiveExtractor.extract(archive: zipURL, to: extracted)

            var restoredSomething = false

            let dataSrc = extracted.appendingPathComponent(dataPrefix, isDirectory: true)
            if fm.fileExists(atPath: dataSrc.path) {
                let outcome = LegacyDataDrain.drain(
                    from: dataSrc, into: dataDestination,
                    policy: .preferSource, fm: fm)
                NSLog(
                    "[CloudSave] Restored Data tree (%ld entries) -> %@",
                    outcome.movedCount, dataDestination.path)
                restoredSomething = true
            }

            let gameSrc = extracted.appendingPathComponent(gamePrefix, isDirectory: true)
            if fm.fileExists(atPath: gameSrc.path) {
                try fm.createDirectory(at: container.gameURL, withIntermediateDirectories: true)
                let outcome = LegacyDataDrain.drain(
                    from: gameSrc, into: container.gameURL,
                    policy: .preferSource, fm: fm)
                NSLog(
                    "[CloudSave] Restored Game tree (%ld entries) -> %@",
                    outcome.movedCount, container.gameURL.path)
                restoredSomething = true
            }

            let userDataSrc = extracted.appendingPathComponent(userDataPrefix, isDirectory: true)
            if fm.fileExists(atPath: userDataSrc.path) {
                try fm.createDirectory(at: container.userDataURL, withIntermediateDirectories: true)
                let outcome = LegacyDataDrain.drain(
                    from: userDataSrc, into: container.userDataURL,
                    policy: .preferSource, fm: fm)
                NSLog(
                    "[CloudSave] Restored UserData tree (%ld entries) -> %@",
                    outcome.movedCount, container.userDataURL.path)
                restoredSomething = true
            }

            if !restoredSomething {
                let topLevel = try fm.contentsOfDirectory(atPath: extracted.path)
                    .filter { $0 != manifestFileName }
                if !topLevel.isEmpty {
                    let outcome = LegacyDataDrain.drain(
                        from: extracted, into: dataDestination,
                        policy: .preferSource, fm: fm)
                    NSLog(
                        "[CloudSave] Restored legacy flat pack (%ld entries) -> %@",
                        outcome.movedCount, dataDestination.path)
                    restoredSomething = true
                }
            }

            guard restoredSomething else {
                throw Error.restoreFailed("The cloud save pack was empty.")
            }
        } catch let error as Error {
            throw error
        } catch {
            throw Error.restoreFailed(error.localizedDescription)
        }
    }

    static func upload(
        game: GameEntry,
        accessToken: String
    ) async throws -> AccountAPI.SaveUploadResult {
        guard let container = game.container else { throw Error.missingContainer }
        let gameKey = gameKey(for: container)
        let title = game.title
        let pack = try await Task.detached(priority: .userInitiated) {
            try packData(for: container)
        }.value
        NSLog("[CloudSave] Uploading %ld bytes for %@", pack.count, gameKey)
        return try await AccountAPI.uploadCloudSave(
            accessToken: accessToken,
            gameKey: gameKey,
            gameTitle: title,
            packData: pack)
    }

    static func download(game: GameEntry, accessToken: String) async throws {
        guard let container = game.container else { throw Error.missingContainer }
        let gameKey = gameKey(for: container)
        let data = try await AccountAPI.downloadCloudSave(
            accessToken: accessToken,
            gameKey: gameKey)
        try await Task.detached(priority: .userInitiated) {
            try applyPack(data, to: container)
        }.value
        NSLog("[CloudSave] Applied cloud save for %@", gameKey)
    }

    private static func deduplicated(_ entries: [ZipArchiveWriter.Entry]) -> [ZipArchiveWriter.Entry] {
        var seen = Set<String>()
        var result: [ZipArchiveWriter.Entry] = []
        for entry in entries {
            guard seen.insert(entry.path).inserted else { continue }
            result.append(entry)
        }
        return result
    }

    private static func dataRelativePath(for container: GameContainer) -> String {
        let dataURL = dataRoot(for: container)
        let root = DataDirectory.sharedRootURL.path
        var relative = dataURL.path
        if relative.hasPrefix(root + "/") {
            relative = String(relative.dropFirst(root.count + 1))
        }
        return relative
    }

    private static func collectPortableEntries(at gameRoot: URL) throws -> [ZipArchiveWriter.Entry] {
        let fm = FileManager.default
        var entries: [ZipArchiveWriter.Entry] = []
        for name in PortableGameSaves.entryNames(atGameRoot: gameRoot, fm: fm) {
            let url = gameRoot.appendingPathComponent(name)
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory) else { continue }
            if isDirectory.boolValue {
                entries.append(contentsOf: try collectZipEntries(at: url, prefix: "\(gamePrefix)/\(name)"))
            } else if let data = try? Data(contentsOf: url) {
                entries.append(.init(path: "\(gamePrefix)/\(name)", data: data))
            }
        }
        return entries
    }

    /// Saves nested under `Game/` outside engine asset folders (e.g. `Game/Save Files/`).
    private static func collectDeepGameSaveEntries(at gameRoot: URL) throws -> [ZipArchiveWriter.Entry] {
        let fm = FileManager.default
        var entries: [ZipArchiveWriter.Entry] = []
        guard fm.fileExists(atPath: gameRoot.path) else { return entries }

        func walk(_ directory: URL, relative: String) throws {
            let items = try fm.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles])
            for item in items {
                let name = item.lastPathComponent
                let itemRelative = relative.isEmpty ? name : "\(relative)/\(name)"
                let zipPath = "\(gamePrefix)/\(itemRelative)"
                let values = try item.resourceValues(forKeys: [.isDirectoryKey])
                if values.isDirectory == true {
                    let lowered = name.lowercased()
                    if engineFolderNames.contains(lowered) { continue }
                    if saveFolderNames.contains(lowered) {
                        entries.append(contentsOf: try collectZipEntries(at: item, prefix: zipPath))
                        continue
                    }
                    if containsSaveShapedFile(in: item) {
                        entries.append(contentsOf: try collectZipEntries(at: item, prefix: zipPath))
                        continue
                    }
                    try walk(item, relative: itemRelative)
                } else if isSaveShapedFile(name: name, at: item) {
                    if let data = try? Data(contentsOf: item) {
                        entries.append(.init(path: zipPath, data: data))
                    }
                }
            }
        }

        try walk(gameRoot, relative: "")
        return entries
    }

    private static func collectContainerRootSaveEntries(at containerRoot: URL) throws -> [ZipArchiveWriter.Entry] {
        let fm = FileManager.default
        var entries: [ZipArchiveWriter.Entry] = []
        guard let names = try? fm.contentsOfDirectory(atPath: containerRoot.path) else { return entries }
        for name in names {
            // Skip known container subdirectories.
            if [
                GameContainerPaths.gameDirectoryName,
                GameContainerPaths.userDataDirectoryName,
                GameContainerPaths.playerDataDirectoryName,
                GameContainerPaths.legacyPlayerDataDirectoryName,
                GameContainerPaths.logsDirectoryName,
                GameContainerPaths.metadataDirectoryName,
            ].contains(name) { continue }
            let url = containerRoot.appendingPathComponent(name)
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
                continue
            }
            if ConcatenatedSaveRecovery.remainder(ofConcatenatedName: name) != nil
                || isSaveShapedFile(name: name, at: url)
            {
                if let data = try? Data(contentsOf: url) {
                    entries.append(.init(path: "\(gamePrefix)/\(name)", data: data))
                }
            }
        }
        return entries
    }

    private static func containsSaveShapedFile(in directory: URL) -> Bool {
        let fm = FileManager.default
        guard let children = try? fm.contentsOfDirectory(atPath: directory.path) else { return false }
        return children.contains { child in
            let url = directory.appendingPathComponent(child)
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
                return false
            }
            return isSaveShapedFile(name: child, at: url)
        }
    }

    private static func isSaveShapedFile(name: String, at url: URL) -> Bool {
        if ConcatenatedSaveRecovery.isSaveFilename(name) { return true }
        return PortableGameSaves.hasMarshalMagic(url)
    }

    private static func collectZipEntries(at root: URL, prefix: String = "") throws -> [ZipArchiveWriter.Entry] {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return []
        }
        let items = try fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles])
        var entries: [ZipArchiveWriter.Entry] = []
        for item in items {
            let values = try item.resourceValues(forKeys: [.isDirectoryKey])
            let name = item.lastPathComponent
            let relative = prefix.isEmpty ? name : "\(prefix)/\(name)"
            if values.isDirectory == true {
                entries.append(contentsOf: try collectZipEntries(at: item, prefix: relative))
            } else if let data = try? Data(contentsOf: item) {
                entries.append(.init(path: relative, data: data))
            }
        }
        return entries
    }
}
