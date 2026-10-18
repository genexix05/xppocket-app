import GoogleMobileAds
import UIKit

/// AdMob banner + interstitial orchestration for the free tier.
@MainActor
final class AdCoordinator {
    static let shared = AdCoordinator()

    enum InterstitialReason: String {
        case importComplete
        case gameLoad
        case sessionEnd
    }

    private(set) var isShowingInterstitial = false
    private var startedSDK = false
    private var interstitial: GADInterstitialAd?
    private var isLoadingInterstitial = false

    private init() {}

    var shouldShowAds: Bool {
        !AccountSession.shared.hasPro
    }

    func prepare() {
        guard shouldShowAds, AdsConfig.isConfigured else { return }
        guard !startedSDK else {
            preloadInterstitial()
            return
        }
        startedSDK = true
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        preloadInterstitial()
    }

    /// Returns after the interstitial is dismissed or skipped by policy.
    func showInterstitialIfNeeded(reason: InterstitialReason) async {
        guard shouldShowAds, AdsConfig.isConfigured else { return }
        guard canPresentInterstitial(reason: reason) else { return }
        prepare()
        if interstitial == nil {
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

    private func preloadInterstitial() {
        guard shouldShowAds, !isLoadingInterstitial, interstitial == nil else { return }
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
                } else if let error {
                    NSLog("AdCoordinator: interstitial load failed: \(error.localizedDescription)")
                }
            }
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
