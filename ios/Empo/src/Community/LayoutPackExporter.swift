import Foundation
import GameProbe

/// Builds `.xppocket-pack` ZIPs from on-device layout profiles.
enum LayoutPackExporter {
    struct Metadata: Sendable {
        var id: String
        var name: String
        var description: String
        var author: String
        var tags: [String]
    }

    enum Error: LocalizedError {
        case profileMissing
        case controlsMissing
        case writeFailed

        var errorDescription: String? {
            switch self {
            case .profileMissing: "The layout profile could not be found."
            case .controlsMissing: "The profile has no controls.json."
            case .writeFailed: "Could not build the layout pack."
            }
        }
    }

    /// Slug suitable for catalog IDs: lowercase letters, digits, hyphens.
    static func suggestedCatalogID(for profileName: String) -> String {
        let lowered = profileName.lowercased()
        let slug = lowered.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) { return Character(scalar) }
            return "-"
        }
        var cleaned = String(slug)
        while cleaned.contains("--") { cleaned = cleaned.replacingOccurrences(of: "--", with: "-") }
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        if cleaned.isEmpty { return "layout" }
        if cleaned.first?.isNumber == true { cleaned = "layout-\(cleaned)" }
        return String(cleaned.prefix(63))
    }

    static func export(
        profileName: String,
        metadata: Metadata? = nil,
        store: LayoutProfileStore = LayoutProfilesManager.store
    ) throws -> Data {
        guard store.profileExists(profileName) else { throw Error.profileMissing }
        let profileURL = store.profileURL(profileName)
        let fm = FileManager.default

        let controlsURL = store.controlsURL(profileName)
        guard let controlsData = try? Data(contentsOf: controlsURL), !controlsData.isEmpty else {
            throw Error.controlsMissing
        }

        let meta = metadata ?? Metadata(
            id: suggestedCatalogID(for: profileName),
            name: profileName,
            description: "",
            author: "",
            tags: [])

        let manifest: [String: Any] = [
            "format": "xppocket-layout-pack",
            "format_version": 1,
            "id": meta.id,
            "name": meta.name,
            "description": meta.description,
            "author": meta.author,
            "tags": meta.tags,
            "min_app_version": "1.0.0",
        ]
        guard let manifestData = try? JSONSerialization.data(
            withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
        else { throw Error.writeFailed }

        var entries: [ZipArchiveWriter.Entry] = [
            .init(path: "manifest.json", data: manifestData),
            .init(path: "controls.json", data: controlsData),
        ]

        let screenURL = store.screenURL(profileName)
        if let screenData = try? Data(contentsOf: screenURL), !screenData.isEmpty {
            entries.append(.init(path: ScreenRegionFile.fileName, data: screenData))
        }

        let skinURL = profileURL.appendingPathComponent(ControlSkinFile.fileName)
        if let skinData = try? Data(contentsOf: skinURL), !skinData.isEmpty {
            entries.append(.init(path: ControlSkinFile.fileName, data: skinData))
        }

        let assetsURL = profileURL.appendingPathComponent(
            ControlSkinFile.assetsDirectoryName, isDirectory: true)
        if fm.fileExists(atPath: assetsURL.path),
            let files = try? fm.contentsOfDirectory(
                at: assetsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        {
            for file in files where !file.hasDirectoryPath {
                if let data = try? Data(contentsOf: file), !data.isEmpty {
                    let relative = "\(ControlSkinFile.assetsDirectoryName)/\(file.lastPathComponent)"
                    entries.append(.init(path: relative, data: data))
                }
            }
        }

        do {
            return try ZipArchiveWriter.archive(entries: entries)
        } catch {
            throw Error.writeFailed
        }
    }
}
