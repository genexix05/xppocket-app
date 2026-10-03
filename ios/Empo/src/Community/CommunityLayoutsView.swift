import GameProbe
import SwiftUI

/// Browse and install layout packs from the XP Pocket community catalog.
struct CommunityLayoutsView: View {
    @State private var layouts: [CommunityLayoutAPI.LayoutSummary] = []
    @State private var loading = false
    @State private var installingID: String?
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showImporter = false
    @State private var lastInstallWasUpdate = false

    var body: some View {
        List {
            if loading && layouts.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading catalog…")
                        Spacer()
                    }
                    .padding(.vertical, Spacing.lg)
                }
            } else if layouts.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No layouts yet",
                        systemImage: "square.grid.3x3",
                        description: Text("Pull down to refresh or try again later.")
                    )
                }
            } else {
                Section {
                    ForEach(layouts) { layout in
                        layoutRow(layout)
                    }
                } footer: {
                    Text(
                        "Packs can include controls, screen region, skin.json and PNG assets (device frames, button art). Installed profiles appear under Layout profiles."
                    )
                }
            }
        }
        .navigationTitle("Community layouts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showImporter = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .accessibilityLabel("Import pack file")
            }
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    CommunityLayoutUploadView()
                } label: {
                    Image(systemName: "icloud.and.arrow.up")
                }
                .accessibilityLabel("Publish layout")
            }
        }
        .layoutPackImport(
            isPresented: $showImporter,
            errorMessage: $errorMessage,
            successMessage: $successMessage)
        .onChange(of: successMessage) { _, message in
            if message != nil { Task { await reload() } }
        }
        .refreshable { await reload() }
        .task { await reload() }
        .alert("Could not install", isPresented: errorPresented) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert(installAlertTitle, isPresented: successPresented) {
            Button("OK", role: .cancel) { successMessage = nil }
        } message: {
            Text(successMessage ?? "")
        }
    }

    private var installAlertTitle: String {
        lastInstallWasUpdate ? "Updated" : "Installed"
    }

    private var errorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private var successPresented: Binding<Bool> {
        Binding(get: { successMessage != nil }, set: { if !$0 { successMessage = nil } })
    }

    @ViewBuilder
    private func layoutRow(_ layout: CommunityLayoutAPI.LayoutSummary) -> some View {
        let state = LayoutPackInstaller.InstalledIndex.installState(
            for: layout, store: LayoutProfilesManager.store)

        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(layout.name)
                        .font(.headline)
                    if !layout.author.isEmpty {
                        Text(layout.author)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if installingID == layout.id {
                    ProgressView()
                } else {
                    switch state {
                    case .notInstalled:
                        EmptyView()
                    case .upToDate:
                        Label("Installed", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.success)
                    case .updateAvailable:
                        Label("Update available", systemImage: "arrow.down.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.warning)
                    }
                }
            }

            if !layout.description.isEmpty {
                Text(layout.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !layout.tags.isEmpty {
                Text(layout.tags.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if state != .upToDate {
                Button {
                    Task { await install(layout, wasUpdate: state == .updateAvailable) }
                } label: {
                    Text(state == .updateAvailable ? "Update" : "Install")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(state == .updateAvailable ? .warning : .brand)
                .disabled(installingID != nil)
            }

            NavigationLink {
                CommunityLayoutUploadView(existingLayout: layout)
            } label: {
                Text("Update on server")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, Spacing.xxs)
    }

    @MainActor
    private func reload() async {
        loading = true
        defer { loading = false }
        do {
            layouts = try await CommunityLayoutAPI.fetchCatalog()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func install(_ layout: CommunityLayoutAPI.LayoutSummary, wasUpdate: Bool) async {
        installingID = layout.id
        defer { installingID = nil }
        do {
            let data = try await CommunityLayoutAPI.downloadPack(layoutID: layout.id)
            let result = try LayoutPackInstaller.install(
                packData: data,
                layoutID: layout.id,
                suggestedName: layout.name,
                catalogUpdatedAt: layout.updatedAt,
                store: LayoutProfilesManager.store)
            lastInstallWasUpdate = wasUpdate || result.updated
            successMessage =
                lastInstallWasUpdate
                ? "Updated profile “\(result.profileName)” to the latest version."
                : "Added profile “\(result.profileName)”."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
