import AuthenticationServices
import StoreKit
import SwiftUI

/// Pro subscription sheet: launch promo, Settings, and upsell entry points.
/// Purchase does not require Sign in with Apple (App Review 5.1.1(v)).
struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accountSession) private var session

    /// When false, hides the top-right Done control (Settings entry points).
    var showsToolbarDismiss = true

    /// Cold-start promo: Skip in toolbar; primary bottom CTA is Subscribe.
    var isLaunchPromo = false

    /// When false, the view is pushed inside an existing NavigationStack
    /// (Settings). Nesting another stack dismissed the paywall immediately.
    var embedsOwnNavigation = true

    @State private var errorMessage: String?

    private var subscriptions: SubscriptionManager { SubscriptionManager.shared }

    var body: some View {
        Group {
            if embedsOwnNavigation {
                NavigationStack { paywallContent }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled(!showsToolbarDismiss && !isLaunchPromo && !session.hasPro)
            } else {
                paywallContent
            }
        }
        .task {
            await subscriptions.loadProducts()
            await subscriptions.refreshLocalEntitlements()
        }
        .alert("Subscription", isPresented: errorPresented) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var paywallContent: some View {
        List {
            Section {
                featureRow("nosign", String(localized: "No ads"), String(localized: "Remove banner and full-screen ads."))
                featureRow("icloud.fill", String(localized: "Cloud save"), String(localized: "Back up and restore saves across devices."))
                featureRow("wand.and.stars", String(localized: "Cheats"), String(localized: "In-game cheat menu for supported games."))
                featureRow("hare.fill", String(localized: "Fast forward"), String(localized: "Speed up repetitive sections."))
                featureRow("square.grid.3x3", String(localized: "Premium layouts"), String(localized: "Exclusive community control packs."))
            }

            if session.hasPro {
                Section {
                    Label("Your Pro subscription is active.", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.brand)
                    Button("Manage subscription") {
                        Task { await manageSubscription() }
                    }
                }
                if !session.isSignedIn {
                    optionalSignInSection(
                        message: String(localized: "Sign in with Apple to enable cloud save on all your devices. Pro features on this device stay active without an account.")
                    )
                }
            } else {
                pricingSection
                if !session.isSignedIn {
                    optionalSignInSection(
                        message: String(localized: "Playing stays free without an account. Sign in is optional — useful later for cloud save across devices.")
                    )
                }
                if !isLaunchPromo {
                    restoreSection
                }
                legalSection
            }
        }
        .navigationTitle("XP Pocket Pro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsToolbarDismiss || session.hasPro || isLaunchPromo {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isLaunchPromo ? "Skip" : "Done") { dismiss() }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !session.hasPro {
                primaryBottomBar
            }
        }
    }

    private var primaryBottomBar: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                Task { await subscribe() }
            } label: {
                HStack {
                    if subscriptions.isPurchasing || session.isBusy {
                        ProgressView()
                            .tint(.onBrand)
                    }
                    Text(subscribeButtonTitle)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.primary)
            .disabled(subscriptions.isPurchasing || session.isBusy)

            if !isLaunchPromo {
                Button("Not now") { dismiss() }
                    .buttonStyle(.secondary)
            } else {
                Text("Or tap Skip above to keep using the free version.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(.bar)
    }

    private var subscribeButtonTitle: String {
        if let product = subscriptions.product {
            return String(localized: "Subscribe — \(product.displayPrice)/month")
        }
        return String(localized: "Subscribe to Pro")
    }

    @ViewBuilder
    private var pricingSection: some View {
        Section {
            if subscriptions.isLoadingProducts {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let product = subscriptions.product {
                LabeledContent("XP Pocket Pro", value: "1 month")
                LabeledContent("Price", value: product.displayPrice + " / month")
            } else {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Could not load subscription pricing from the App Store.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let detail = subscriptions.lastError {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Try again") {
                        Task { await subscriptions.loadProducts() }
                    }
                    .font(.footnote)
                }
            }
        }
    }

    @ViewBuilder
    private func optionalSignInSection(message: String) -> some View {
        Section {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)

            AppleSignInButton { token in
                Task {
                    do {
                        try await session.signIn(identityToken: token)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            } onFailure: { error in
                if (error as NSError).code == ASAuthorizationError.canceled.rawValue { return }
                errorMessage = error.localizedDescription
            }
            .disabled(session.isBusy)
        }
    }

    @ViewBuilder
    private var restoreSection: some View {
        Section {
            Button("Restore purchases") {
                Task { await restore() }
            }
            .disabled(subscriptions.isPurchasing)
        } footer: {
            Text("Restores a Pro subscription purchased with this Apple ID on any of your devices.")
        }
    }

    private var legalSection: some View {
        Section {
            Link("Privacy Policy", destination: AppInfo.privacyURL)
            Link("Terms of Use", destination: AppInfo.termsURL)
            Text(
                "Subscription renews automatically each month until cancelled in Settings → Apple ID → Subscriptions."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func subscribe() async {
        if subscriptions.product == nil {
            await subscriptions.loadProducts()
            guard subscriptions.product != nil else {
                errorMessage = subscriptions.lastError
                    ?? SubscriptionManager.PurchaseError.productUnavailable.localizedDescription
                return
            }
        }
        do {
            try await subscriptions.purchase(session: session)
            if session.hasPro {
                dismiss()
            }
        } catch SubscriptionManager.PurchaseError.userCancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func restore() async {
        do {
            try await subscriptions.restorePurchases(session: session)
            if session.hasPro {
                dismiss()
            } else {
                errorMessage = String(localized: "No active Pro subscription was found for this Apple ID.")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func manageSubscription() async {
        do {
            try await subscriptions.showManageSubscriptions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func featureRow(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(.brand)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title).font(.headline)
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

/// Typealias kept for call sites that already reference the old name.
typealias ProUpsellSheet = ProPaywallView
