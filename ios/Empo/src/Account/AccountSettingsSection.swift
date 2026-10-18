import SwiftUI

/// Account section in app Settings. Sign in is optional — gameplay works without it.
struct AccountSettingsSection: View {
    @Environment(\.accountSession) private var session
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false

    var body: some View {
        Section {
            if session.isSignedIn {
                signedInRows
            } else {
                unsignedRows
            }
        } header: {
            Text("Account")
        } footer: {
            Text(
                "Playing is free and does not require an account. You can subscribe to Pro without signing in. Sign in is optional and enables cloud save across devices. Deleting your account removes your XP Pocket profile and cloud saves from our servers. It does not cancel an App Store subscription — manage that in Settings → Apple ID → Subscriptions."
            )
        }
        .alert("Account", isPresented: errorPresented) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Delete account?", isPresented: $showDeleteConfirm) {
            Button("Delete account", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This permanently deletes your XP Pocket account and cloud saves on our servers. Games and saves stored on this device stay. App Store subscriptions must be cancelled separately in Apple ID settings."
            )
        }
    }

    private var signedInRows: some View {
        Group {
            if let email = session.profile?.email, !email.isEmpty {
                LabeledContent("Apple ID", value: email)
            } else {
                LabeledContent("Status", value: String(localized: "Signed in"))
            }

            proEntryRow

            Button("Refresh subscription", systemImage: "arrow.clockwise") {
                Task { await session.refreshEntitlements() }
            }
            .disabled(session.isBusy)

            Button("Sign out", role: .destructive) {
                session.signOut()
            }

            Button("Delete account", role: .destructive) {
                showDeleteConfirm = true
            }
            .disabled(session.isBusy)
        }
    }

    private var unsignedRows: some View {
        Group {
            AccountSignInControls { message in
                errorMessage = message
            }

            // Push inside Settings' NavigationStack — presenting another
            // sheet/cover from this sheet was dismissing immediately.
            proEntryRow

            if session.isBusy {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var proEntryRow: some View {
        if session.hasPro {
            Label("XP Pocket Pro active", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.brand)
            Button("Manage subscription", systemImage: "creditcard") {
                Task { await manageSubscription() }
            }
            NavigationLink {
                ProPaywallView(
                    showsToolbarDismiss: true,
                    isLaunchPromo: false,
                    embedsOwnNavigation: false
                )
            } label: {
                Label("Pro details", systemImage: "sparkles")
            }
        } else {
            NavigationLink {
                ProPaywallView(
                    showsToolbarDismiss: true,
                    isLaunchPromo: false,
                    embedsOwnNavigation: false
                )
            } label: {
                Label("Get XP Pocket Pro", systemImage: "sparkles")
            }
        }
    }

    private func manageSubscription() async {
        do {
            try await SubscriptionManager.shared.showManageSubscriptions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteAccount() async {
        do {
            try await session.deleteAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }
}
