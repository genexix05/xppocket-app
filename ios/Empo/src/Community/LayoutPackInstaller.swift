import Foundation
import GameProbe
import UniformTypeIdentifiers

/// Installs `.xppocket-pack` ZIPs (controls, screen, skin, assets).
enum LayoutPackInstaller {
    struct Result: Sendable {
        let profileName: String
        let updated: Bool
    }

    struct Manifest: Decodable {
        let name: String?
    }

    enum Error: LocalizedError {
        case emptyPack
        case missingControls
        case invalidControls(String)
        case invalidScreen(String)
        case invalidSkin(String)
        case invalidProfileName
        case writeFailed
        case importFailed(String)

        var errorDescription: String? {
            switch self {
            case .emptyPack: String(localized: "The pack file is empty.")
            case .missingControls: String(localized: "The pack does not include controls.json.")
            case .invalidControls(let detail): String(localized: "Invalid controls.json: \(detail)")
            case .invalidScreen(let detail): String(localized: "Invalid screen.json: \(detail)")
            case .invalidSkin(let detail): String(localized: "Invalid skin.json: \(detail)")
            case .invalidProfileName: String(localized: "Could not derive a valid profile name.")
            case .writeFailed: String(localized: "Could not save the layout profile.")
            case .importFailed(let detail): detail
            }
        }
    }

    static let packTypes: [UTType] = [.zip, .archive]

    /// Maps community layout IDs to on-device profile folder names and catalog versions.
    enum InstalledIndex {
        private static let profileKey = "communityLayouts.installedByID"
        private static let updatedAtKey = "communityLayouts.installedUpdatedAtByID"

        enum InstallState: Equatable {
            case notInstalled
            case upToDate
            case updateAvailable
        }

        static func profileName(for layoutID: String) -> String? {
            guard let map = UserDefaults.standard.dictionary(forKey: profileKey) as? [String: String]
            else { return nil }
            return map[layoutID]
        }

        static func catalogUpdatedAt(for layoutID: String) -> String? {
            guard let map = UserDefaults.standard.dictionary(forKey: updatedAtKey) as? [String: String]
            else { return nil }
            return map[layoutID]
        }

        static func set(
            layoutID: String,
            profileName: String,
            catalogUpdatedAt: String? = nil
        ) {
            var profiles =
                (UserDefaults.standard.dictionary(forKey: profileKey) as? [String: String]) ?? [:]
            profiles[layoutID] = profileName
            UserDefaults.standard.set(profiles, forKey: profileKey)

            guard let catalogUpdatedAt else { return }
            var versions =
                (UserDefaults.standard.dictionary(forKey: updatedAtKey) as? [String: String]) ?? [:]
            versions[layoutID] = catalogUpdatedAt
            UserDefaults.standard.set(versions, forKey: updatedAtKey)
        }

        static func isInstalled(layoutID: String, store: LayoutProfileStore) -> Bool {
            guard let name = profileName(for: layoutID) else { return false }
            return store.profileExists(name)
        }

        static func installState(
            for layout: CommunityLayoutAPI.LayoutSummary,
            store: LayoutProfileStore
        ) -> InstallState {
            guard isInstalled(layoutID: layout.id, store: store) else { return .notInstalled }
            guard let installedAt = catalogUpdatedAt(for: layout.id) else {
                // Installed before version tracking — offer one refresh to sync.
                return .updateAvailable
            }
            return CatalogTimestamp.isServerNewer(layout.updatedAt, than: installedAt)
                ? .updateAvailable
                : .upToDate
        }
    }

    /// ISO-8601 comparison for catalog `updated_at` strings.
    private enum CatalogTimestamp {
        private static let formatters: [ISO8601DateFormatter] = {
            let withFraction = ISO8601DateFormatter()
            withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            return [withFraction, plain]
        }()

        static func isServerNewer(_ server: String, than local: String) -> Bool {
            guard let serverDate = parse(server), let localDate = parse(local) else {
                return server != local
            }
            return serverDate > localDate
        }

        private static func parse(_ raw: String) -> Date? {
            for formatter in formatters {
                if let date = formatter.date(from: raw) { return date }
            }
            return nil
        }
    }

    @MainActor
    static func install(
        packData: Data,
        layoutID: String,
        suggestedName: String,
        catalogUpdatedAt: String? = nil,
        store: LayoutProfileStore
    ) throws -> Result {
        let result = try installExtracted(
            packData: packData,
            suggestedName: suggestedName,
            layoutID: layoutID,
            store: store)
        InstalledIndex.set(
            layoutID: layoutID,
            profileName: result.profileName,
            catalogUpdatedAt: catalogUpdatedAt)
        return result
    }

    /// Import a `.zip` pack from Files, AirDrop, etc. (no catalog ID).
    @MainActor
    static func installLocalFile(
        _ fileURL: URL,
        store: LayoutProfileStore = LayoutProfilesManager.store
    ) throws -> Result {
        let accessed = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessed { fileURL.stopAccessingSecurityScopedResource() }
        }
        let data = try Data(contentsOf: fileURL)
        let suggested = manifestName(in: data) ?? fileURL.deletingPathExtension().lastPathComponent
        return try installExtracted(
            packData: data,
            suggestedName: suggested,
            layoutID: nil,
            store: store)
    }

    @MainActor
    private static func installExtracted(
        packData: Data,
        suggestedName: String,
        layoutID: String?,
        store: LayoutProfileStore
    ) throws -> Result {
        guard !packData.isEmpty else { throw Error.emptyPack }

        let fm = FileManager.default
        let scratch = fm.temporaryDirectory.appendingPathComponent(
            "xppocket-pack-\(UUID().uuidString)", isDirectory: true)
        defer { try? fm.removeItem(at: scratch) }

        let zipURL = scratch.appendingPathComponent("pack.zip")
        try fm.createDirectory(at: scratch, withIntermediateDirectories: true)
        try packData.write(to: zipURL, options: .atomic)
        try ArchiveExtractor.extract(archive: zipURL, to: scratch)

        let controlsURL = scratch.appendingPathComponent("controls.json")
        guard fm.fileExists(atPath: controlsURL.path) else { throw Error.missingControls }

        let controlsData = try Data(contentsOf: controlsURL)
        let parsed = ControlsManifestLoader.parse(data: controlsData)
        let errors = parsed.findings.filter { $0.severity == .error }
        if !errors.isEmpty || parsed.ignoredNewerVersion {
            let summary = errors.first.map { "[\($0.code)] \($0.message)" } ?? "Unknown error"
            throw Error.invalidControls(summary)
        }
        guard let touch = parsed.manifest?.touch else {
            throw Error.invalidControls("Missing touch section.")
        }

        var screenPortrait: ScreenPlacement?
        var screenLandscape: ScreenPlacement?
        let screenURL = scratch.appendingPathComponent(ScreenRegionFile.fileName)
        if fm.fileExists(atPath: screenURL.path) {
            let screenData = try Data(contentsOf: screenURL)
            let screen = ScreenRegionFile.parse(screenData)
            let screenErrors = screen.findings.filter { $0.hasPrefix("S0") }
            if !screenErrors.isEmpty {
                throw Error.invalidScreen(screenErrors[0])
            }
            screenPortrait = screen.portrait
            screenLandscape = screen.landscape
        }

        let skinURL = scratch.appendingPathComponent(ControlSkinFile.fileName)
        if fm.fileExists(atPath: skinURL.path) {
            let skinData = try Data(contentsOf: skinURL)
            guard ControlSkinFile.parse(skinData) != nil else {
                throw Error.invalidSkin("skin.json must be version 1.")
            }
        }

        let manifestURL = scratch.appendingPathComponent("manifest.json")
        let manifestName: String? =
            if fm.fileExists(atPath: manifestURL.path),
            let data = try? Data(contentsOf: manifestURL),
            let manifest = try? JSONDecoder().decode(Manifest.self, from: data)
        {
            manifest.name
        } else {
            nil
        }

        let preferredName = manifestName ?? suggestedName
        let baseName =
            LayoutProfileStore.validatedName(preferredName)
            ?? (layoutID.flatMap {
                LayoutProfileStore.validatedName($0.replacingOccurrences(of: "-", with: " "))
            })
            ?? LayoutProfileStore.validatedName("Layout")
        guard let baseName else { throw Error.invalidProfileName }

        let existingMapped = layoutID.flatMap { InstalledIndex.profileName(for: $0) }
        let targetName: String
        let updated: Bool

        if let existingMapped, store.profileExists(existingMapped) {
            targetName = existingMapped
            updated = true
        } else if store.profileExists(baseName) {
            targetName = store.uniqueName(base: baseName)
            updated = false
        } else {
            targetName = baseName
            updated = false
        }

        let wrote: Bool
        if updated {
            wrote = store.writeProfile(targetName, touch: touch)
        } else {
            wrote = store.createProfile(targetName, touch: touch)
        }
        guard wrote else { throw Error.writeFailed }

        if screenPortrait != nil || screenLandscape != nil {
            _ = store.writeScreen(targetName, portrait: screenPortrait, landscape: screenLandscape)
        }

        let profileURL = store.profileURL(targetName)
        if fm.fileExists(atPath: skinURL.path) {
            try fm.copyItem(
                at: skinURL,
                to: profileURL.appendingPathComponent(ControlSkinFile.fileName))
        }

        let assetsSource = scratch.appendingPathComponent(ControlSkinFile.assetsDirectoryName)
        if fm.fileExists(atPath: assetsSource.path) {
            let assetsDest = profileURL.appendingPathComponent(
                ControlSkinFile.assetsDirectoryName, isDirectory: true)
            try? fm.removeItem(at: assetsDest)
            try fm.copyItem(at: assetsSource, to: assetsDest)
        }

        ControlSkinFile.invalidateCache(for: targetName)
        LayoutProfilesManager.postProfileChange(name: targetName, from: nil)
        return Result(profileName: targetName, updated: updated)
    }

    private static func manifestName(in packData: Data) -> String? {
        let fm = FileManager.default
        let scratch = fm.temporaryDirectory.appendingPathComponent(
            "xppocket-manifest-\(UUID().uuidString)", isDirectory: true)
        defer { try? fm.removeItem(at: scratch) }
        do {
            try fm.createDirectory(at: scratch, withIntermediateDirectories: true)
            let zipURL = scratch.appendingPathComponent("pack.zip")
            try packData.write(to: zipURL)
            try ArchiveExtractor.extractSelective(
                archive: zipURL,
                to: scratch,
                include: { $0 == "manifest.json" || $0.hasSuffix("/manifest.json") }
            )
            let manifestURL = scratch.appendingPathComponent("manifest.json")
            guard let data = try? Data(contentsOf: manifestURL),
                let manifest = try? JSONDecoder().decode(Manifest.self, from: data)
            else { return nil }
            return manifest.name
        } catch {
            return nil
        }
    }
}
