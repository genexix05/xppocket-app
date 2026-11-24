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

    /// Must match the auto-renewable product ids in App Store Connect. Both
    /// are in the "XP Pocket Pro" group, so a user holds one at a time and
    /// can switch between them.
    static let monthlyProductID = "app.xppocket.player.pro.monthly"
    static let annualProductID = "app.xppocket.player.pro.annual"
    static let proProductIDs: Set<String> = [monthlyProductID, annualProductID]

    private(set) var monthlyProduct: Product?
    private(set) var annualProduct: Product?

    /// Any loaded plan, for code that only needs to know the store answered.
    var product: Product? { annualProduct ?? monthlyProduct }

    /// Whole percent the annual plan saves against twelve monthly payments.
    var annualSavingsPercent: Int? {
        guard let monthly = monthlyProduct?.price, let annual = annualProduct?.price, monthly > 0 else {
            return nil
        }
        let yearOfMonths = monthly * 12
        let saving = (yearOfMonths - annual) / yearOfMonths * 100
        // `intValue` gives 0 for a decimal with many digits (16.4158… here),
        // so go through Double and round down.
        let percent = Int(NSDecimalNumber(decimal: saving).doubleValue.rounded(.down))
        return percent > 0 ? percent : nil
    }
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
            let products = try await Product.products(for: Self.proProductIDs)
            monthlyProduct = products.first { $0.id == Self.monthlyProductID }
            annualProduct = products.first { $0.id == Self.annualProductID }
            if !products.isEmpty {
                lastError = nil
            } else {
                let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
                lastError =
                    String(localized: "App Store returned no product for \(Self.monthlyProductID). ")
                    + String(localized: "This app’s bundle ID is \(bundleID). ")
                    + String(localized: "In App Store Connect the subscription must belong to that app, ")
                    + "with Paid Apps Agreement active. New products can take a few hours to appear."
            }
        } catch {
            monthlyProduct = nil
            annualProduct = nil
            lastError = error.localizedDescription
        }
    }

    /// Reads StoreKit entitlements and updates `AccountSession.hasStoreKitPro`.
    func refreshLocalEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result) else { continue }
            if Self.proProductIDs.contains(transaction.productID), transaction.revocationDate == nil {
                active = true
                break
            }
        }
        AccountSession.shared.applyStoreKitPro(active)
    }

    /// Purchases a Pro plan. Does not require Sign in with Apple.
    func purchase(_ product: Product, session: AccountSession) async throws {
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
                guard Self.proProductIDs.contains(transaction.productID) else { continue }
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
                String(localized: "The Pro subscription is not available right now. Try again later.")
            case .pending:
                String(localized: "Your purchase is pending approval.")
            case .userCancelled:
                String(localized: "Purchase cancelled.")
            case .unverifiedTransaction:
                String(localized: "Could not verify the App Store transaction.")
            case .manageUnavailable:
                String(localized: "Could not open subscription management. Try Settings → Apple ID → Subscriptions.")
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
                guard Self.proProductIDs.contains(transaction.productID) else {
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
        let fallbackDays: Double = transaction.productID == Self.annualProductID ? 365 : 30
        let expiresAt = transaction.expirationDate ?? Date().addingTimeInterval(fallbackDays * 24 * 3600)
        try await AccountAPI.verifySubscription(
            accessToken: token,
            productID: transaction.productID,
            originalTransactionID: String(transaction.originalID),
            expiresAt: expiresAt,
            signedTransaction: transaction.jsonRepresentation.base64EncodedString()
        )
    }
}
