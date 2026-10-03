import Foundation
import GameProbe
import UIKit

/// Empo-private skin manifest at `Profiles/<name>/skin.json`.
/// References PNG/JPEG assets under `Profiles/<name>/assets/`.
enum ControlSkinFile {
    static let fileName = "skin.json"
    static let assetsDirectoryName = "assets"

    struct Document: Equatable, Sendable {
        var portrait: Orientation?
        var landscape: Orientation?
    }

    struct Orientation: Equatable, Sendable {
        /// Device shell / bezel image, usually anchored to the bottom.
        var frame: String?
        var frameOpacity: Double
        /// D-pad sprite(s).
        var dpad: String?
        var dpadPressed: String?
        /// W3C `KeyboardEvent.code` → asset path (e.g. `"Enter"` → `"assets/a.png"`).
        var buttonsByKey: [String: String]
        /// Visible label → asset path (fallback when key lookup misses).
        var buttonsByLabel: [String: String]

        init(
            frame: String? = nil,
            frameOpacity: Double = 1,
            dpad: String? = nil,
            dpadPressed: String? = nil,
            buttonsByKey: [String: String] = [:],
            buttonsByLabel: [String: String] = [:]
        ) {
            self.frame = frame
            self.frameOpacity = frameOpacity
            self.dpad = dpad
            self.dpadPressed = dpadPressed
            self.buttonsByKey = buttonsByKey
            self.buttonsByLabel = buttonsByLabel
        }
    }

    struct Resolved: Sendable {
        var frame: UIImage?
        var frameOpacity: Double
        var dpad: UIImage?
        var dpadPressed: UIImage?
        private var buttonsByKey: [String: UIImage]
        private var buttonsByLabel: [String: UIImage]

        func buttonImage(keyCode: String?, label: String) -> UIImage? {
            if let keyCode, let image = buttonsByKey[keyCode] { return image }
            if let image = buttonsByLabel[label] { return image }
            return nil
        }

        fileprivate init(
            frame: UIImage?,
            frameOpacity: Double,
            dpad: UIImage?,
            dpadPressed: UIImage?,
            buttonsByKey: [String: UIImage],
            buttonsByLabel: [String: UIImage]
        ) {
            self.frame = frame
            self.frameOpacity = frameOpacity
            self.dpad = dpad
            self.dpadPressed = dpadPressed
            self.buttonsByKey = buttonsByKey
            self.buttonsByLabel = buttonsByLabel
        }

        var hasSkinnedControls: Bool {
            dpad != nil || dpadPressed != nil || !buttonsByKey.isEmpty || !buttonsByLabel.isEmpty
        }

        var hasFrame: Bool { frame != nil }
    }

    // MARK: - Parse

    static func parse(_ data: Data) -> Document? {
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let version = raw["version"] as? Int, version == 1
        else { return nil }
        return Document(
            portrait: parseOrientation(raw["portrait"]),
            landscape: parseOrientation(raw["landscape"])
        )
    }

    private static func parseOrientation(_ raw: Any?) -> Orientation? {
        guard let object = raw as? [String: Any] else { return nil }
        var buttonsByKey: [String: String] = [:]
        var buttonsByLabel: [String: String] = [:]
        if let buttons = object["buttons"] as? [String: String] {
            for (key, path) in buttons {
                if key.hasPrefix("Key") || key == "Enter" || key == "Escape" || key.hasPrefix("Digit") {
                    buttonsByKey[key] = path
                } else {
                    buttonsByLabel[key] = path
                }
            }
        }
        if let byKey = object["buttonsByKey"] as? [String: String] {
            buttonsByKey.merge(byKey) { _, new in new }
        }
        if let byLabel = object["buttonsByLabel"] as? [String: String] {
            buttonsByLabel.merge(byLabel) { _, new in new }
        }
        let dpadBlock = object["dpad"] as? [String: Any]
        return Orientation(
            frame: object["frame"] as? String,
            frameOpacity: (object["frameOpacity"] as? Double)
                ?? (object["frame_opacity"] as? Double)
                ?? 1,
            dpad: object["dpad"] as? String ?? dpadBlock?["image"] as? String,
            dpadPressed: object["dpadPressed"] as? String
                ?? object["dpad_pressed"] as? String
                ?? dpadBlock?["pressed"] as? String,
            buttonsByKey: buttonsByKey,
            buttonsByLabel: buttonsByLabel
        )
    }

    // MARK: - Load document

    static func loadDocument(
        profileName: String,
        profilesRoot: URL = LayoutProfilesManager.profilesRootURL
    ) -> Document {
        let skinURL = profilesRoot
            .appendingPathComponent(profileName, isDirectory: true)
            .appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: skinURL), let document = parse(data) else {
            return Document()
        }
        return document
    }

    static func orientationSlice(
        _ document: Document, for orientation: ControlsOrientation
    ) -> Orientation {
        let existing = orientation == .portrait ? document.portrait : document.landscape
        return existing ?? Orientation()
    }

    static func setOrientationSlice(
        _ document: inout Document,
        orientation: ControlsOrientation,
        slice: Orientation?
    ) {
        let empty = slice.map(isOrientationEmpty) ?? true
        switch orientation {
        case .portrait:
            document.portrait = empty ? nil : slice
        case .landscape:
            document.landscape = empty ? nil : slice
        }
    }

    static func isOrientationEmpty(_ slice: Orientation) -> Bool {
        slice.frame == nil && slice.dpad == nil && slice.dpadPressed == nil
            && slice.buttonsByKey.isEmpty && slice.buttonsByLabel.isEmpty
    }

    // MARK: - Serialize / persist

    static func serialize(_ document: Document) -> Data? {
        var root: [String: Any] = ["version": 1]
        if let portrait = document.portrait, !isOrientationEmpty(portrait) {
            root["portrait"] = serializeOrientation(portrait)
        }
        if let landscape = document.landscape, !isOrientationEmpty(landscape) {
            root["landscape"] = serializeOrientation(landscape)
        }
        return try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
    }

    private static func serializeOrientation(_ slice: Orientation) -> [String: Any] {
        var object: [String: Any] = [:]
        if let frame = slice.frame { object["frame"] = frame }
        if slice.frameOpacity != 1 { object["frameOpacity"] = slice.frameOpacity }
        if let dpad = slice.dpad { object["dpad"] = dpad }
        if let dpadPressed = slice.dpadPressed { object["dpadPressed"] = dpadPressed }
        var buttons = slice.buttonsByKey
        for (label, path) in slice.buttonsByLabel { buttons[label] = path }
        if !buttons.isEmpty { object["buttons"] = buttons }
        return object
    }

    enum WriteError: LocalizedError {
        case invalidProfile
        case imageEncodeFailed
        case writeFailed

        var errorDescription: String? {
            switch self {
            case .invalidProfile: "Profile name is invalid."
            case .imageEncodeFailed: "Could not encode the image."
            case .writeFailed: "Could not save skin files."
            }
        }
    }

    @discardableResult
    static func saveDocument(
        _ document: Document,
        profileName: String,
        profilesRoot: URL = LayoutProfilesManager.profilesRootURL
    ) throws -> Bool {
        guard LayoutProfileStore.validatedName(profileName) != nil else {
            throw WriteError.invalidProfile
        }
        let profileURL = profilesRoot.appendingPathComponent(profileName, isDirectory: true)
        let fm = FileManager.default
        let skinURL = profileURL.appendingPathComponent(fileName)
        let hasContent = document.portrait != nil || document.landscape != nil
        if !hasContent {
            try? fm.removeItem(at: skinURL)
            return true
        }
        guard let data = serialize(document) else { throw WriteError.writeFailed }
        try fm.createDirectory(at: profileURL, withIntermediateDirectories: true)
        do {
            try data.write(to: skinURL, options: .atomic)
            return true
        } catch {
            throw WriteError.writeFailed
        }
    }

    /// Writes PNG under `assets/` and returns a relative path (`assets/foo.png`).
    static func saveAssetPNG(
        _ image: UIImage,
        profileName: String,
        basename: String,
        profilesRoot: URL = LayoutProfilesManager.profilesRootURL
    ) throws -> String {
        guard LayoutProfileStore.validatedName(profileName) != nil else {
            throw WriteError.invalidProfile
        }
        let safeBase = basename
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        let filename = safeBase.hasSuffix(".png") ? safeBase : "\(safeBase).png"
        let profileURL = profilesRoot.appendingPathComponent(profileName, isDirectory: true)
        let assetsURL = profileURL.appendingPathComponent(assetsDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: assetsURL, withIntermediateDirectories: true)
        guard let data = image.pngData() else { throw WriteError.imageEncodeFailed }
        let fileURL = assetsURL.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw WriteError.writeFailed
        }
        return "\(assetsDirectoryName)/\(filename)"
    }

    static func removeAsset(
        relativePath: String?,
        profileName: String,
        profilesRoot: URL = LayoutProfilesManager.profilesRootURL
    ) {
        guard let relativePath else { return }
        let normalized = relativePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, !normalized.contains("..") else { return }
        let fileURL = profilesRoot
            .appendingPathComponent(profileName, isDirectory: true)
            .appendingPathComponent(normalized)
        try? FileManager.default.removeItem(at: fileURL)
    }

    @MainActor
    static func persistDocument(
        _ document: Document,
        profileName: String
    ) throws {
        try saveDocument(document, profileName: profileName)
        invalidateCache(for: profileName)
        LayoutProfilesManager.postProfileChange(name: profileName, from: nil)
    }

    @MainActor
    static func load(
        profileName: String,
        orientation: ControlsOrientation,
        profilesRoot: URL = LayoutProfilesManager.profilesRootURL
    ) -> Resolved? {
        let profileURL = profilesRoot.appendingPathComponent(profileName, isDirectory: true)
        let skinURL = profileURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: skinURL),
            let document = parse(data)
        else { return nil }
        let slice = orientation == .portrait ? document.portrait : document.landscape
        guard let slice else { return nil }
        let loader = ControlSkinImageCache.shared
        let buttonsByKey = slice.buttonsByKey.compactMapValues {
            loader.image(relativePath: $0, profileRoot: profileURL)
        }
        let buttonsByLabel = slice.buttonsByLabel.compactMapValues {
            loader.image(relativePath: $0, profileRoot: profileURL)
        }
        let resolved = Resolved(
            frame: slice.frame.flatMap { loader.image(relativePath: $0, profileRoot: profileURL) },
            frameOpacity: min(1, max(0, slice.frameOpacity)),
            dpad: slice.dpad.flatMap { loader.image(relativePath: $0, profileRoot: profileURL) },
            dpadPressed: slice.dpadPressed.flatMap {
                loader.image(relativePath: $0, profileRoot: profileURL)
            },
            buttonsByKey: buttonsByKey,
            buttonsByLabel: buttonsByLabel
        )
        guard resolved.hasFrame || resolved.hasSkinnedControls else { return nil }
        return resolved
    }

    @MainActor
    static func invalidateCache(for profileName: String) {
        ControlSkinImageCache.shared.invalidate(profileName: profileName)
    }
}

/// In-memory cache for profile skin bitmaps (small PNGs).
@MainActor
final class ControlSkinImageCache {
    static let shared = ControlSkinImageCache()
    private var images: [String: UIImage] = [:]

    func image(relativePath: String, profileRoot: URL) -> UIImage? {
        let normalized = relativePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, !normalized.contains("..") else { return nil }
        let cacheKey = profileRoot.path + "::" + normalized
        if let cached = images[cacheKey] { return cached }
        let fileURL = profileRoot.appendingPathComponent(normalized)
        guard let data = try? Data(contentsOf: fileURL),
            let image = UIImage(data: data, scale: UIScreen.main.scale)
        else { return nil }
        images[cacheKey] = image
        return image
    }

    func invalidate(profileName: String) {
        let prefix = LayoutProfilesManager.profilesRootURL
            .appendingPathComponent(profileName, isDirectory: true).path + "::"
        images.keys.filter { $0.hasPrefix(prefix) }.forEach { images.removeValue(forKey: $0) }
    }

    func invalidateAll() {
        images.removeAll()
    }
}
