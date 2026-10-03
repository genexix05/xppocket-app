import GameProbe
import SwiftUI

/// Visual editor for per-profile control skins (`skin.json` + `assets/`).
struct ProfileSkinEditorView: View {
    let profileName: String

    @Environment(\.dismiss) private var dismiss
    @State private var document: ControlSkinFile.Document
    @State private var orientation: ControlsOrientation = .portrait
    @State private var pickingSlot: SkinImageSlot?
    @State private var errorMessage: String?

    init(profileName: String) {
        self.profileName = profileName
        _document = State(initialValue: ControlSkinFile.loadDocument(profileName: profileName))
    }

    private var slice: ControlSkinFile.Orientation {
        ControlSkinFile.orientationSlice(document, for: orientation)
    }

    var body: some View {
        Form {
            Section {
                Picker("Orientation", selection: $orientation) {
                    Text("Portrait").tag(ControlsOrientation.portrait)
                    Text("Landscape").tag(ControlsOrientation.landscape)
                }
                .pickerStyle(.segmented)
            }

            Section {
                skinRow(
                    title: "Device frame",
                    subtitle: "Bezel or shell image, usually at the bottom.",
                    path: slice.frame)
                {
                    pickingSlot = .frame
                } onRemove: {
                    mutateSlice { $0.frame = nil }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Frame opacity")
                    Slider(
                        value: Binding(
                            get: { slice.frameOpacity },
                            set: { value in mutateSlice { $0.frameOpacity = value } }),
                        in: 0 ... 1)
                }
            } header: {
                Text("Frame")
            }

            Section {
                skinRow(
                    title: "D-pad",
                    subtitle: "Normal state.",
                    path: slice.dpad)
                {
                    pickingSlot = .dpad
                } onRemove: {
                    mutateSlice { $0.dpad = nil }
                }

                skinRow(
                    title: "D-pad (pressed)",
                    subtitle: "Shown while a direction is held.",
                    path: slice.dpadPressed)
                {
                    pickingSlot = .dpadPressed
                } onRemove: {
                    mutateSlice { $0.dpadPressed = nil }
                }
            } header: {
                Text("Movement")
            }

            Section {
                if buttonRows.isEmpty {
                    Text("No action buttons in this orientation. Add them in the layout editor first.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(buttonRows, id: \.key) { row in
                        skinRow(
                            title: row.title,
                            subtitle: row.key,
                            path: row.path)
                        {
                            pickingSlot = .button(key: row.key, label: row.label, basename: row.basename)
                        } onRemove: {
                            mutateSlice {
                                $0.buttonsByKey.removeValue(forKey: row.key)
                                if let label = row.label {
                                    $0.buttonsByLabel.removeValue(forKey: label)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Action buttons")
            } footer: {
                Text("Pick PNG or JPEG images from Photos, Files, or the camera. They are saved inside the profile folder.")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .imageSourcePicker(
            isPresented: Binding(
                get: { pickingSlot != nil },
                set: { if !$0 { pickingSlot = nil } }),
            title: pickingSlot?.pickerTitle ?? "Choose image",
            hasExisting: pickingSlot?.hasExisting(in: slice) ?? false,
            onImageSelected: { image in
                guard let slot = pickingSlot else { return }
                applyImage(image, to: slot)
                pickingSlot = nil
            },
            onRemove: {
                guard let slot = pickingSlot else { return }
                removeImage(for: slot)
                pickingSlot = nil
            })
        .alert("Could not save skin", isPresented: errorPresented) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private struct ButtonRow {
        let key: String
        let label: String?
        let title: String
        let basename: String
        var path: String? {
            nil // filled per call via slice
        }
    }

    private var buttonRows: [(key: String, label: String?, title: String, basename: String, path: String?)] {
        guard let touch = LayoutProfilesManager.store.readProfile(profileName)?.touch else { return [] }
        let layout = orientation == .portrait ? touch.portrait : touch.landscape
        guard let buttons = layout?.buttons else { return [] }
        return buttons.map { spec in
            let label = spec.label
            let title = label ?? spec.key
            let basename = (label ?? spec.key).lowercased()
            let path = slice.buttonsByKey[spec.key] ?? label.flatMap { slice.buttonsByLabel[$0] }
            return (spec.key, label, title, basename, path)
        }
    }

    @ViewBuilder
    private func skinRow(
        title: String,
        subtitle: String,
        path: String?,
        onPick: @escaping () -> Void,
        onRemove: @escaping () -> Void
    ) -> some View {
        HStack(spacing: Spacing.md) {
            thumbnail(for: path)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Choose", action: onPick)
                .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private func thumbnail(for path: String?) -> some View {
        let profileRoot = LayoutProfilesManager.store.profileURL(profileName)
        if let path,
            let image = ControlSkinImageCache.shared.image(relativePath: path, profileRoot: profileRoot)
        {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.surface.opacity(0.35))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func mutateSlice(_ update: (inout ControlSkinFile.Orientation) -> Void) {
        var next = slice
        update(&next)
        var copy = document
        ControlSkinFile.setOrientationSlice(&copy, orientation: orientation, slice: next)
        document = copy
        persist()
    }

    private func applyImage(_ image: UIImage, to slot: SkinImageSlot) {
        do {
            let path = try ControlSkinFile.saveAssetPNG(
                image, profileName: profileName, basename: slot.basename)
            mutateSliceWithoutPersist { slice in
                switch slot {
                case .frame:
                    ControlSkinFile.removeAsset(relativePath: slice.frame, profileName: profileName)
                    slice.frame = path
                case .dpad:
                    ControlSkinFile.removeAsset(relativePath: slice.dpad, profileName: profileName)
                    slice.dpad = path
                case .dpadPressed:
                    ControlSkinFile.removeAsset(relativePath: slice.dpadPressed, profileName: profileName)
                    slice.dpadPressed = path
                case .button(let key, let label, _):
                    if let old = slice.buttonsByKey[key] {
                        ControlSkinFile.removeAsset(relativePath: old, profileName: profileName)
                    }
                    if let label, let old = slice.buttonsByLabel[label] {
                        ControlSkinFile.removeAsset(relativePath: old, profileName: profileName)
                    }
                    slice.buttonsByKey[key] = path
                    if let label { slice.buttonsByLabel[label] = path }
                }
            }
            persist()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeImage(for slot: SkinImageSlot) {
        mutateSliceWithoutPersist { slice in
            switch slot {
            case .frame:
                ControlSkinFile.removeAsset(relativePath: slice.frame, profileName: profileName)
                slice.frame = nil
            case .dpad:
                ControlSkinFile.removeAsset(relativePath: slice.dpad, profileName: profileName)
                slice.dpad = nil
            case .dpadPressed:
                ControlSkinFile.removeAsset(relativePath: slice.dpadPressed, profileName: profileName)
                slice.dpadPressed = nil
            case .button(let key, let label, _):
                ControlSkinFile.removeAsset(relativePath: slice.buttonsByKey[key], profileName: profileName)
                slice.buttonsByKey.removeValue(forKey: key)
                if let label {
                    ControlSkinFile.removeAsset(
                        relativePath: slice.buttonsByLabel[label], profileName: profileName)
                    slice.buttonsByLabel.removeValue(forKey: label)
                }
            }
        }
        persist()
    }

    private func mutateSliceWithoutPersist(_ update: (inout ControlSkinFile.Orientation) -> Void) {
        var next = slice
        update(&next)
        var copy = document
        ControlSkinFile.setOrientationSlice(&copy, orientation: orientation, slice: next)
        document = copy
    }

    private func persist() {
        do {
            try ControlSkinFile.persistDocument(document, profileName: profileName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private enum SkinImageSlot: Equatable {
        case frame
        case dpad
        case dpadPressed
        case button(key: String, label: String?, basename: String)

        var basename: String {
            switch self {
            case .frame: "frame"
            case .dpad: "dpad"
            case .dpadPressed: "dpad-pressed"
            case .button(_, _, let basename): basename
            }
        }

        var pickerTitle: String {
            switch self {
            case .frame: "Device frame"
            case .dpad: "D-pad image"
            case .dpadPressed: "D-pad pressed image"
            case .button(_, let label, _): "\(label ?? "Button") image"
            }
        }

        func hasExisting(in slice: ControlSkinFile.Orientation) -> Bool {
            switch self {
            case .frame: slice.frame != nil
            case .dpad: slice.dpad != nil
            case .dpadPressed: slice.dpadPressed != nil
            case .button(let key, let label, _):
                slice.buttonsByKey[key] != nil
                    || (label.flatMap { slice.buttonsByLabel[$0] } != nil)
            }
        }
    }
}
