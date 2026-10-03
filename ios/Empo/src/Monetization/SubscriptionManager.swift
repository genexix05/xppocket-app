import Foundation
import StoreKit
import UIKit

/// StoreKit 2 subscription flow for XP Pocket Pro.
///
/// Purchase and restore work without an account (App Review 5.1.1(v)).
/// Sign in with Apple is optional afterward so cloud save can sync Pro
/// entitlements to the server.
@MainActor
@Observable
final class SubscriptionManager {
    static let shared = SubscriptionManager()

    /// Must match the auto-renewable product id in App Store Connect.
    static let proProductID = "app.xppocket.player.pro.monthly"

    private(set) var product: Product?
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    private(set) var lastError: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task { await listenForTransactionUpdates() }
    }

    // Singleton lives for the process lifetime; no deinit cleanup needed.

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let products = try await Product.products(for: [Self.proProductID])
            if let loaded = products.first {
                product = loaded
                lastError = nil
            } else {
                product = nil
                let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
                lastError =
                    "App Store returned no product for \(Self.proProductID). "
                    + "This app’s bundle ID is \(bundleID). "
                    + "In App Store Connect the subscription must belong to that app, "
                    + "with Paid Apps Agreement active. New products can take a few hours to appear."
            }
        } catch {
            product = nil
            lastError = error.localizedDescription
        }
    }

    /// Reads StoreKit entitlements and updates `AccountSession.hasStoreKitPro`.
    func refreshLocalEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result) else { continue }
            if transaction.productID == Self.proProductID {
                active = true
                break
            }
        }
        AccountSession.shared.applyStoreKitPro(active)
    }

    /// Purchases Pro. Does not require Sign in with Apple.
    func purchase(session: AccountSession) async throws {
        guard let product else {
            await loadProducts()
            guard let product else { throw PurchaseError.productUnavailable }
            try await purchase(product: product, session: session)
            return
        }
        try await purchase(product: product, session: session)
    }

    /// Restores purchases via StoreKit. Does not require Sign in with Apple.
    func restorePurchases(session: AccountSession) async throws {
        isPurchasing = true
        defer { isPurchasing = false }
        try await AppStore.sync()
        await refreshLocalEntitlements()
        if session.isSignedIn {
            await syncPurchasesToServer(session: session)
        }
        lastError = nil
    }

    /// Pushes active StoreKit Pro entitlements to the API when signed in.
    func syncPurchasesToServer(session: AccountSession) async {
        guard session.isSignedIn else { return }
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try verified(result)
                guard transaction.productID == Self.proProductID else { continue }
                try await submit(transaction: transaction, session: session)
            } catch {
                lastError = error.localizedDescription
            }
        }
        await session.refreshEntitlements(silent: true)
    }

    /// Opens Apple’s subscription management UI.
    func showManageSubscriptions() async throws {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive })
            ?? scenes.first
        else {
            throw PurchaseError.manageUnavailable
        }
        try await AppStore.showManageSubscriptions(in: scene)
        await refreshLocalEntitlements()
    }

    // MARK: - Private

    enum PurchaseError: LocalizedError {
        case productUnavailable
        case pending
        case userCancelled
        case unverifiedTransaction
        case manageUnavailable

        var errorDescription: String? {
            switch self {
            case .productUnavailable:
                "The Pro subscription is not available right now. Try again later."
            case .pending:
                "Your purchase is pending approval."
            case .userCancelled:
                "Purchase cancelled."
            case .unverifiedTransaction:
                "Could not verify the App Store transaction."
            case .manageUnavailable:
                "Could not open subscription management. Try Settings → Apple ID → Subscriptions."
            }
        }
    }

    private func purchase(product: Product, session: AccountSession) async throws {
        isPurchasing = true
        defer { isPurchasing = false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verified(verification)
            AccountSession.shared.applyStoreKitPro(true)
            await transaction.finish()
            await refreshLocalEntitlements()
            if session.isSignedIn {
                do {
                    try await submit(transaction: transaction, session: session)
                    await session.refreshEntitlements(silent: true)
                } catch {
                    NSLog("SubscriptionManager: server verify failed: %@", error.localizedDescription)
                }
            }
            lastError = nil
        case .userCancelled:
            throw PurchaseError.userCancelled
        case .pending:
            throw PurchaseError.pending
        @unknown default:
            throw PurchaseError.productUnavailable
        }
    }

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            do {
                let transaction = try verified(result)
                guard transaction.productID == Self.proProductID else {
                    await transaction.finish()
                    continue
                }
                AccountSession.shared.applyStoreKitPro(true)
                if AccountSession.shared.isSignedIn {
                    try? await submit(
                        transaction: transaction, session: AccountSession.shared)
                    await AccountSession.shared.refreshEntitlements(silent: true)
                }
                await transaction.finish()
                await refreshLocalEntitlements()
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw PurchaseError.unverifiedTransaction
        }
    }

    private func submit(transaction: Transaction, session: AccountSession) async throws {
        guard let token = session.accessToken else { return }
        let expiresAt = transaction.expirationDate ?? Date().addingTimeInterval(30 * 24 * 3600)
        try await AccountAPI.verifySubscription(
            accessToken: token,
            productID: transaction.productID,
            originalTransactionID: String(transaction.originalID),
            expiresAt: expiresAt,
            signedTransaction: transaction.jsonRepresentation.base64EncodedString()
        )
    }
}
