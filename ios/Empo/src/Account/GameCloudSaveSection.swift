import SwiftUI

/// Per-game cloud save actions in Game Settings.
struct GameCloudSaveSection: View {
    let game: GameEntry
    @Binding var blocksSheetDismiss: Bool
    @Environment(\.accountSession) private var session
    @State private var busy = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var showProInfo = false
    @State private var confirmDownload = false

    init(game: GameEntry, blocksSheetDismiss: Binding<Bool> = .constant(false)) {
        self.game = game
        _blocksSheetDismiss = blocksSheetDismiss
    }

    var body: some View {
        Section {
            if !session.isSignedIn {
                AccountSignInControls { message in
                    errorMessage = message
                }
                .disabled(session.isBusy)
            } else if !session.hasPro {
                Button {
                    showProInfo = true
                } label: {
                    Label("Cloud save (Pro)", systemImage: "lock.fill")
                }
            } else if game.container == nil {
                Text("Cloud save is unavailable while this game is importing.")
                    .foregroundStyle(.secondary)
            } else if confirmDownload {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(
                        "Replace local saves with the cloud copy? Your current local progress will be archived beside the restored files."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Button(role: .destructive) {
                        confirmDownload = false
                        Task { await download() }
                    } label: {
                        Label("Replace local saves", systemImage: "icloud.and.arrow.down")
                    }
                    .disabled(busy)

                    Button("Cancel") {
                        confirmDownload = false
                    }
                    .disabled(busy)
                }
            } else {
                Button {
                    Task { await upload() }
                } label: {
                    Label("Upload save to cloud", systemImage: "icloud.and.arrow.up")
                }
                .disabled(busy)

                Button {
                    confirmDownload = true
                } label: {
                    Label("Download save from cloud", systemImage: "icloud.and.arrow.down")
                }
                .disabled(busy)

                if busy {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
        } header: {
            Text("Cloud save")
        } footer: {
            if let statusMessage {
                Text(statusMessage)
            } else if !confirmDownload {
                Text("Uploads every save location for this game. Download replaces local saves with the cloud copy — restart the game to load it.")
            }
        }
        .alert("Cloud save", isPresented: errorPresented) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showProInfo) {
            ProUpsellSheet()
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func setBusy(_ value: Bool) {
        guard busy != value else { return }
        busy = value
        if blocksSheetDismiss != value {
            blocksSheetDismiss = value
        }
    }

    private func upload() async {
        guard let token = session.accessToken else {
            errorMessage = String(localized: "Sign in with Apple first.")
            return
        }
        setBusy(true)
        defer { setBusy(false) }
        do {
            let result = try await CloudSaveManager.upload(game: game, accessToken: token)
            statusMessage =
                String(localized: "Uploaded revision \(result.revision) (\(ByteCountFormatter.string(fromByteCount: Int64(result.sizeBytes), countStyle: .file))).")
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func download() async {
        guard let token = session.accessToken else {
            errorMessage = String(localized: "Sign in with Apple first.")
            return
        }
        setBusy(true)
        defer { setBusy(false) }
        do {
            try await CloudSaveManager.download(game: game, accessToken: token)
            statusMessage =
                String(localized: "Cloud save restored. Quit the game completely (not just pause) and launch it again to load the cloud copy.")
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
