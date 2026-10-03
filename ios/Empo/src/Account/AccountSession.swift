import Foundation
import Observation

/// Signed-in XP Pocket account and Pro entitlements from `api.xppocket.app`.
///
/// Pro unlocks also come from StoreKit on-device (`hasStoreKitPro`) so
/// purchase works without registration (App Review 5.1.1(v)).
@MainActor
@Observable
final class AccountSession {
    static let shared = AccountSession()

    private(set) var profile: AccountAPI.AccountProfile?
    private(set) var accessToken: String?
    private(set) var isBusy = false
    private(set) var lastError: String?

    /// Active Pro from StoreKit on this device (no account needed).
    private(set) var hasStoreKitPro = false

    var isSignedIn: Bool { accessToken != nil && profile != nil }
    var entitlements: AccountAPI.Entitlements { profile?.entitlements ?? .free }

    /// Pro from App Store receipt and/or server account.
    var hasPro: Bool { entitlements.pro || hasStoreKitPro }

    private let keychainService = "app.xppocket.player.account"
    private let tokenKey = "access_token"

    private init() {
        accessToken = KeychainStore.read(service: keychainService, account: tokenKey)
    }

    func applyStoreKitPro(_ active: Bool) {
        hasStoreKitPro = active
    }

    func refreshOnLaunch() async {
        if let token = accessToken {
            do {
                let account = try await AccountAPI.fetchAccount(accessToken: token)
                profile = account
                lastError = nil
            } catch {
                if case AccountAPI.Error.badStatus(401, _) = error {
                    signOut()
                }
                lastError = error.localizedDescription
            }
        }
        await SubscriptionManager.shared.refreshLocalEntitlements()
        if isSignedIn, hasStoreKitPro, !entitlements.pro {
            await SubscriptionManager.shared.syncPurchasesToServer(session: self)
        }
    }

    func signIn(identityToken: String) async throws {
        isBusy = true
        defer { isBusy = false }
        let response = try await AccountAPI.signInWithApple(identityToken: identityToken)
        try persistSignIn(response)
        await SubscriptionManager.shared.syncPurchasesToServer(session: self)
    }

    func signInDev(deviceLabel: String) async throws {
        isBusy = true
        defer { isBusy = false }
        let response = try await AccountAPI.signInDev(deviceLabel: deviceLabel)
        try persistSignIn(response)
        await SubscriptionManager.shared.syncPurchasesToServer(session: self)
    }

    private func persistSignIn(_ response: AccountAPI.SignInResponse) throws {
        try KeychainStore.save(response.accessToken, service: keychainService, account: tokenKey)
        accessToken = response.accessToken
        profile = response.account
        lastError = nil
    }

    func refreshEntitlements(silent: Bool = false) async {
        guard let token = accessToken else { return }
        if !silent { isBusy = true }
        defer { if !silent { isBusy = false } }
        do {
            profile = try await AccountAPI.fetchAccount(accessToken: token)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func signOut() {
        KeychainStore.delete(service: keychainService, account: tokenKey)
        accessToken = nil
        profile = nil
        lastError = nil
        // StoreKit Pro remains — sign-out must not revoke a paid subscription.
    }

    /// Deletes the remote account (cloud saves included) and signs out locally.
    /// Does not cancel an App Store subscription — Apple requires the user
    /// to manage that in Settings → Apple ID → Subscriptions.
    func deleteAccount() async throws {
        guard let token = accessToken else { return }
        isBusy = true
        defer { isBusy = false }
        try await AccountAPI.deleteAccount(accessToken: token)
        signOut()
    }
}
