import AppTrackingTransparency
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
        /// 30 minutes of play passed since the last ad.
        case playTime
    }

    /// Posted once the SDK may be asked for ads (consent resolved + SDK started).
    static let didBecomeReadyNotification = Notification.Name("AdCoordinator.didBecomeReady")

    /// Google drops a loaded interstitial after one hour; refresh a bit earlier.
    private static let interstitialLifetime: TimeInterval = 55 * 60
    private static let retryBaseDelay: TimeInterval = 15
    private static let retryMaxDelay: TimeInterval = 10 * 60
    /// After this many no-fills in a row the interstitial stops retrying
    /// on its own. The next moment an ad could show loads again. Each
    /// request without an ad lowers the match rate.
    private static let maxBackgroundRetries = 4

    private(set) var isShowingInterstitial = false
    private var startedSDK = false
    private var sdkReady = false
    private var isGatheringConsent = false
    private var interstitial: GADInterstitialAd?
    private var interstitialLoadedAt: Date?
    private var isLoadingInterstitial = false
    private var interstitialFailures = 0
    private var interstitialRetryAt: Date?
    private var interstitialRetryTask: Task<Void, Never>?

    /// True once the game reached `AdsConfig.playTimeInterval` of play and
    /// was paused for the ad. It stays true until an ad shows.
    private(set) var playTimeAdDue = false
    private static let playTimeTick: TimeInterval = 10

    private var playSeconds: TimeInterval {
        get { UserDefaults.standard.double(forKey: DefaultsKey.adPlaySeconds) }
        set { UserDefaults.standard.set(newValue, forKey: DefaultsKey.adPlaySeconds) }
    }

    private init() {}

    var shouldShowAds: Bool {
        !AccountSession.shared.hasPro
    }

    /// True once consent is resolved and the SDK has started. Ad requests
    /// before this point would go out without a valid consent state.
    var canRequestAds: Bool { sdkReady }

    func prepare() {
        guard shouldShowAds, AdsConfig.isConfigured else { return }
        if startedSDK {
            // A new moment to show an ad: retry even after a no-fill streak.
            interstitialFailures = min(interstitialFailures, Self.maxBackgroundRetries - 1)
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

        await requestTrackingAuthorizationIfNeeded()

        if info.canRequestAds { startSDK() }
    }

    /// Google's order: the UMP consent first, then the ATT prompt. A user
    /// who allows both gets personalized ads, which fill more requests and
    /// pay more. The prompt only shows once, and only while the app is
    /// active: iOS denies it at once otherwise.
    private func requestTrackingAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        for _ in 0..<40 where UIApplication.shared.applicationState != .active {
            try? await Task.sleep(for: .milliseconds(250))
        }
        guard UIApplication.shared.applicationState == .active else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    private func startSDK() {
        guard !startedSDK else { return }
        startedSDK = true
        // Load only after the SDK finished starting: the first requests
        // then go out with every adapter and the consent state ready.
        GADMobileAds.sharedInstance().start { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.sdkReady = true
                NotificationCenter.default.post(name: Self.didBecomeReadyNotification, object: nil)
                self.preloadInterstitial()
            }
        }
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
            postponePlayTimeAd(for: reason)
            return
        }
        guard let presenter = AppWindow.topViewController else {
            postponePlayTimeAd(for: reason)
            return
        }
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

    // MARK: - Play time

    /// Counts the seconds of play while the game runs in the foreground.
    /// After `AdsConfig.playTimeInterval` it pauses the game, which takes
    /// the player back to the library. The library then shows the ad,
    /// and the player resumes the game from there. The task ends when
    /// the game leaves `.playing`, and RootView restarts it on the next
    /// play.
    func trackPlayTime(of appState: AppState) async {
        guard shouldShowAds, AdsConfig.isConfigured else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Self.playTimeTick))
            guard !Task.isCancelled, appState.phase == .playing else { return }
            guard UIApplication.shared.applicationState == .active, shouldShowAds else { continue }
            // An alert holds the game, so wait until the player closes it.
            guard appState.shownError == nil, appState.infoMessage == nil else { continue }
            playSeconds += Self.playTimeTick
            guard playSeconds >= AdsConfig.playTimeInterval, !isShowingInterstitial else { continue }
            playTimeAdDue = true
            appState.requestPause()
            return
        }
    }

    /// No ad was ready for the ad of play time. The game must not pause
    /// again at once, so the count goes back and the ad is due again in
    /// five minutes.
    private func postponePlayTimeAd(for reason: InterstitialReason) {
        guard reason == .playTime else { return }
        playTimeAdDue = false
        playSeconds = max(AdsConfig.playTimeInterval - 5 * 60, 0)
    }

    /// The reason to ask for when a game session ends.
    var sessionEndReason: InterstitialReason {
        playTimeAdDue ? .playTime : .sessionEnd
    }

    // MARK: - Policy

    private func canPresentInterstitial(reason: InterstitialReason) -> Bool {
        if isShowingInterstitial { return false }

        // Every game launch shows one, regardless of the cooldown. So does
        // the ad of 30 minutes of play.
        if reason == .gameLoad || reason == .playTime { return true }

        let now = Date().timeIntervalSince1970
        if let last = UserDefaults.standard.object(forKey: DefaultsKey.lastInterstitialTimestamp) as? TimeInterval,
            now - last < AdsConfig.interstitialCooldown
        {
            return false
        }

        switch reason {
        case .importComplete, .gameLoad, .sessionEnd, .playTime:
            return true
        }
    }

    private func recordInterstitialShown() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: DefaultsKey.lastInterstitialTimestamp)
        // Any ad restarts the count of play time.
        playSeconds = 0
        playTimeAdDue = false
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
            request: AdsConfig.adRequest()
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
        guard interstitialFailures < Self.maxBackgroundRetries else {
            interstitialRetryTask?.cancel()
            interstitialRetryTask = nil
            interstitialRetryAt = nil
            return
        }
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
