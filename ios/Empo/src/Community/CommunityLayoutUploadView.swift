import GameProbe
import SwiftUI

/// Publish a layout profile to the community catalog or export a pack file.
struct CommunityLayoutUploadView: View {
    var profileName: String?
    var existingLayout: CommunityLayoutAPI.LayoutSummary?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedProfile: String
    @State private var layoutID: String
    @State private var name: String
    @State private var descriptionText: String
    @State private var author: String
    @State private var tags: String
    @State private var catalog: [CommunityLayoutAPI.LayoutSummary] = []
    @State private var selectedCatalogID = ""
    @State private var adminKey = CommunityAdminCredentials.adminKey
    @State private var rememberAdminKey = !CommunityAdminCredentials.adminKey.isEmpty
    @State private var uploading = false
    @State private var exportURL: URL?
    @State private var showExporter = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    init(
        profileName: String? = nil,
        existingLayout: CommunityLayoutAPI.LayoutSummary? = nil
    ) {
        self.profileName = profileName
        self.existingLayout = existingLayout
        _selectedProfile = State(initialValue: profileName ?? "")
        _layoutID = State(initialValue: existingLayout?.id ?? "")
        _name = State(initialValue: existingLayout?.name ?? "")
        _descriptionText = State(initialValue: existingLayout?.description ?? "")
        _author = State(initialValue: existingLayout?.author ?? "")
        _tags = State(initialValue: existingLayout?.tags.joined(separator: ", ") ?? "")
        _selectedCatalogID = State(initialValue: existingLayout?.id ?? "")
    }

    private var profiles: [String] {
        LayoutProfilesManager.store.listProfiles()
    }

    private var metadata: LayoutPackExporter.Metadata {
        LayoutPackExporter.Metadata(
            id: layoutID.trimmingCharacters(in: .whitespacesAndNewlines),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tags
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty })
    }

    private var replacesExisting: Bool {
        catalog.contains { $0.id == metadata.id }
    }

    private var isUpdating: Bool {
        existingLayout != nil || replacesExisting
    }

    var body: some View {
        Form {
            Section {
                if profileName == nil {
                    Picker("Profile", selection: $selectedProfile) {
                        Text("Choose a profile").tag("")
                        ForEach(profiles, id: \.self) { profile in
                            Text(profile).tag(profile)
                        }
                    }
                    .onChange(of: selectedProfile) { _, new in
                        if existingLayout == nil {
                            applyProfileDefaults(new)
                        }
                    }
                } else {
                    LabeledContent("Profile", value: selectedProfile)
                }
            } footer: {
                Text("The pack includes controls, screen region, skin images, and assets from the selected profile.")
            }

            if existingLayout == nil, !catalog.isEmpty {
                Section {
                    Picker("Catalog entry", selection: $selectedCatalogID) {
                        Text("New entry").tag("")
                        ForEach(catalog) { layout in
                            Text(layout.name).tag(layout.id)
                        }
                    }
                    .onChange(of: selectedCatalogID) { _, new in
                        guard !new.isEmpty, let layout = catalog.first(where: { $0.id == new }) else {
                            return
                        }
                        applyCatalogEntry(layout)
                    }
                } footer: {
                    Text("Pick an existing layout to update it with the same ID.")
                }
            }

            Section("Catalog entry") {
                TextField("Layout ID", text: $layoutID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(existingLayout != nil)
                TextField("Display name", text: $name)
                TextField("Description", text: $descriptionText, axis: .vertical)
                    .lineLimit(2 ... 5)
                TextField("Author", text: $author)
                TextField("Tags (comma separated)", text: $tags)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            if isUpdating {
                Section {
                    Label("Updates the existing catalog entry.", systemImage: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }

            Section {
                SecureField("Admin key", text: $adminKey)
                Toggle("Remember admin key on this device", isOn: $rememberAdminKey)
            } header: {
                Text("Server access")
            } footer: {
                Text("Publishing requires the X-Admin-Key configured on api.xppocket.app.")
            }

            Section {
                Button {
                    Task { await upload() }
                } label: {
                    HStack {
                        Spacer()
                        if uploading {
                            ProgressView()
                        } else {
                            Label(
                                isUpdating ? String(localized: "Update on community") : String(localized: "Publish to community"),
                                systemImage: isUpdating ? "arrow.triangle.2.circlepath" : "icloud.and.arrow.up")
                        }
                        Spacer()
                    }
                }
                .disabled(uploading || !canSubmit)

                Button {
                    prepareExport()
                } label: {
                    Label("Export pack file", systemImage: "square.and.arrow.up")
                }
                .disabled(selectedProfile.isEmpty)
            }
        }
        .navigationTitle(isUpdating ? "Update layout" : "Publish layout")
        .navigationBarTitleDisplayMode(.inline)
        .task { await reloadCatalog() }
        .onAppear {
            if selectedProfile.isEmpty, let first = profiles.first {
                selectedProfile = first
            }
            if existingLayout == nil, layoutID.isEmpty {
                applyProfileDefaults(selectedProfile)
            }
            adminKey = CommunityAdminCredentials.adminKey
            rememberAdminKey = !adminKey.isEmpty
        }
        .sheet(isPresented: $showExporter) {
            if let exportURL {
                ActivityShareSheet(items: [exportURL])
            }
        }
        .alert("Could not publish", isPresented: errorPresented) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert(isUpdating ? "Updated" : "Published", isPresented: successPresented) {
            Button("OK", role: .cancel) {
                successMessage = nil
                dismiss()
            }
        } message: {
            Text(successMessage ?? "")
        }
    }

    private var canSubmit: Bool {
        !selectedProfile.isEmpty
            && metadata.id.range(of: "^[a-z0-9][a-z0-9-]{1,62}$", options: .regularExpression) != nil
            && !metadata.name.isEmpty
            && !adminKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var errorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private var successPresented: Binding<Bool> {
        Binding(get: { successMessage != nil }, set: { if !$0 { successMessage = nil } })
    }

    @MainActor
    private func reloadCatalog() async {
        catalog = (try? await CommunityLayoutAPI.fetchCatalog()) ?? []
    }

    private func applyProfileDefaults(_ profile: String) {
        guard !profile.isEmpty else { return }
        if selectedCatalogID.isEmpty {
            layoutID = LayoutPackExporter.suggestedCatalogID(for: profile)
        }
        if name.isEmpty { name = profile }
    }

    private func applyCatalogEntry(_ layout: CommunityLayoutAPI.LayoutSummary) {
        selectedCatalogID = layout.id
        layoutID = layout.id
        name = layout.name
        descriptionText = layout.description
        author = layout.author
        tags = layout.tags.joined(separator: ", ")
    }

    @MainActor
    private func upload() async {
        uploading = true
        defer { uploading = false }
        do {
            let pack = try LayoutPackExporter.export(profileName: selectedProfile, metadata: metadata)
            if rememberAdminKey {
                CommunityAdminCredentials.adminKey = adminKey
            } else {
                CommunityAdminCredentials.adminKey = ""
            }
            let summary = try await CommunityLayoutAPI.publishLayout(
                metadata: metadata,
                packData: pack,
                adminKey: adminKey,
                replaceExisting: isUpdating)
            successMessage =
                isUpdating
                ? "“\(summary.name)” was updated on the community catalog."
                : "“\(summary.name)” is now on the community catalog."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func prepareExport() {
        do {
            let data = try LayoutPackExporter.export(profileName: selectedProfile, metadata: metadata)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(metadata.id.isEmpty ? "layout" : metadata.id).xppocket-pack.zip")
            try data.write(to: url, options: .atomic)
            exportURL = url
            showExporter = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

