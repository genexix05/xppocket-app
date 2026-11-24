import GoogleMobileAds
import UIKit
import UserMessagingPlatform

/// AdMob banner + interstitial orchestration for the free tier.
@MainActor
final class AdCoordinator {
    static let shared = AdCoordinator()

    enum InterstitialReason: String {
        case importComplete
        case gameLoad
        case sessionEnd
    }

    /// Posted once the SDK may be asked for ads (consent resolved + SDK started).
    static let didBecomeReadyNotification = Notification.Name("AdCoordinator.didBecomeReady")

    /// Google drops a loaded interstitial after one hour; refresh a bit earlier.
    private static let interstitialLifetime: TimeInterval = 55 * 60
    private static let retryBaseDelay: TimeInterval = 15
    private static let retryMaxDelay: TimeInterval = 10 * 60

    private(set) var isShowingInterstitial = false
    private var startedSDK = false
    private var isGatheringConsent = false
    private var interstitial: GADInterstitialAd?
    private var interstitialLoadedAt: Date?
    private var isLoadingInterstitial = false
    private var interstitialFailures = 0
    private var interstitialRetryAt: Date?
    private var interstitialRetryTask: Task<Void, Never>?

    private init() {}

    var shouldShowAds: Bool {
        !AccountSession.shared.hasPro
    }

    /// True once consent is resolved and the SDK has started. Ad requests
    /// before this point would go out without a valid consent state.
    var canRequestAds: Bool { startedSDK }

    func prepare() {
        guard shouldShowAds, AdsConfig.isConfigured else { return }
        if startedSDK {
            preloadInterstitial()
            return
        }
        guard !isGatheringConsent else { return }
        isGatheringConsent = true
        Task { await gatherConsentAndStart() }
    }

    // MARK: - Consent (Google UMP)

    /// Whether Settings should offer a "Privacy choices" entry (EEA/UK).
    var isPrivacyOptionsRequired: Bool {
        UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
    }

    func presentPrivacyOptions() async {
        guard let presenter = AppWindow.topViewController else { return }
        do {
            try await UMPConsentForm.presentPrivacyOptionsForm(from: presenter)
        } catch {
            NSLog("AdCoordinator: privacy options failed: \(error.localizedDescription)")
        }
    }

    private func gatherConsentAndStart() async {
        defer { isGatheringConsent = false }
        let info = UMPConsentInformation.sharedInstance

        // A consent state from a previous launch already allows ads.
        if info.canRequestAds { startSDK() }

        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false
        do {
            try await info.requestConsentInfoUpdate(with: parameters)
            var presenter = AppWindow.topViewController
            for _ in 0..<20 where presenter == nil {
                try? await Task.sleep(for: .milliseconds(250))
                presenter = AppWindow.topViewController
            }
            if let presenter {
                try await UMPConsentForm.loadAndPresentIfRequired(from: presenter)
            }
        } catch {
            NSLog("AdCoordinator: consent flow failed: \(error.localizedDescription)")
        }

        if info.canRequestAds { startSDK() }
    }

    private func startSDK() {
        guard !startedSDK else { return }
        startedSDK = true
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        NotificationCenter.default.post(name: Self.didBecomeReadyNotification, object: nil)
        preloadInterstitial()
    }

    /// Returns after the interstitial is dismissed or skipped by policy.
    func showInterstitialIfNeeded(reason: InterstitialReason) async {
        guard shouldShowAds, AdsConfig.isConfigured else { return }
        guard canPresentInterstitial(reason: reason) else { return }
        prepare()
        dropInterstitialIfExpired()
        if interstitial == nil, canRequestAds, !isInterstitialBackingOff {
            preloadInterstitial()
            for _ in 0..<25 {
                if interstitial != nil { break }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        guard let interstitial else {
            NSLog("AdCoordinator: interstitial not ready for \(reason.rawValue)")
            return
        }
        guard let presenter = AppWindow.topViewController else { return }
        isShowingInterstitial = true
        defer {
            isShowingInterstitial = false
            recordInterstitialShown()
            self.interstitial = nil
            self.interstitialLoadedAt = nil
            preloadInterstitial()
        }
        await withCheckedContinuation { continuation in
            interstitial.fullScreenContentDelegate = InterstitialDelegate {
                continuation.resume()
            }
            interstitial.present(fromRootViewController: presenter)
        }
    }

    // MARK: - Policy

    private func canPresentInterstitial(reason: InterstitialReason) -> Bool {
        if isShowingInterstitial { return false }

        // Every game launch shows one, regardless of the cooldown.
        if reason == .gameLoad { return true }

        let now = Date().timeIntervalSince1970
        if let last = UserDefaults.standard.object(forKey: DefaultsKey.lastInterstitialTimestamp) as? TimeInterval,
            now - last < AdsConfig.interstitialCooldown
        {
            return false
        }

        switch reason {
        case .importComplete, .gameLoad, .sessionEnd:
            return true
        }
    }

    private func recordInterstitialShown() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: DefaultsKey.lastInterstitialTimestamp)
    }

    private var isInterstitialBackingOff: Bool {
        guard let retryAt = interstitialRetryAt else { return false }
        return Date() < retryAt
    }

    private func dropInterstitialIfExpired() {
        guard interstitial != nil, let loadedAt = interstitialLoadedAt else { return }
        if Date().timeIntervalSince(loadedAt) >= Self.interstitialLifetime {
            interstitial = nil
            interstitialLoadedAt = nil
        }
    }

    private func preloadInterstitial() {
        guard shouldShowAds, canRequestAds, !isLoadingInterstitial else { return }
        dropInterstitialIfExpired()
        guard interstitial == nil, !isInterstitialBackingOff else { return }
        isLoadingInterstitial = true
        GADInterstitialAd.load(
            withAdUnitID: AdsConfig.interstitialUnitID,
            request: AdsConfig.nonPersonalizedRequest()
        ) {
            [weak self] ad, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoadingInterstitial = false
                if let ad {
                    self.interstitial = ad
                    self.interstitialLoadedAt = Date()
                    self.interstitialFailures = 0
                    self.interstitialRetryAt = nil
                } else {
                    if let error {
                        NSLog("AdCoordinator: interstitial load failed: \(error.localizedDescription)")
                    }
                    self.scheduleInterstitialRetry()
                }
            }
        }
    }

    /// Exponential backoff (15 s, 30 s, … capped at 10 min) so a no-fill
    /// streak does not turn into thousands of useless requests.
    private func scheduleInterstitialRetry() {
        interstitialFailures += 1
        let delay = min(
            Self.retryBaseDelay * pow(2, Double(interstitialFailures - 1)),
            Self.retryMaxDelay)
        interstitialRetryAt = Date().addingTimeInterval(delay)
        interstitialRetryTask?.cancel()
        interstitialRetryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.preloadInterstitial()
        }
    }

    private final class InterstitialDelegate: NSObject, GADFullScreenContentDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            onDismiss()
        }

        func ad(
            _ ad: GADFullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error
        ) {
            onDismiss()
        }
    }
}
