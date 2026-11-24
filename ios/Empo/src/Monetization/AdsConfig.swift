import Foundation
import GoogleMobileAds

/// AdMob identifiers. Production values belong in `Ads.xcconfig` (see
/// `Ads.xcconfig.example`) and map into Info.plist via build settings.
///
/// Ads are personalized only when the user allows it: the Google UMP
/// consent (EEA/UK) and the App Tracking Transparency prompt. The SDK
/// reads both on its own, so a request carries no `npa` flag.
enum AdsConfig {
    /// Google's official test App ID — safe for Simulator and dev builds.
    private static let testAppID = "ca-app-pub-3940256099942544~1458002511"
    private static let testBannerUnitID = "ca-app-pub-3940256099942544/2934735716"
    private static let testInterstitialUnitID = "ca-app-pub-3940256099942544/4411468910"

    static var isConfigured: Bool {
        !bannerUnitID.isEmpty && !interstitialUnitID.isEmpty
    }

    static var bannerUnitID: String {
        #if targetEnvironment(simulator)
        testBannerUnitID
        #else
        stringPlistKey("XPPocketAdMobBannerUnitID") ?? testBannerUnitID
        #endif
    }

    static var interstitialUnitID: String {
        #if targetEnvironment(simulator)
        testInterstitialUnitID
        #else
        stringPlistKey("XPPocketAdMobInterstitialUnitID") ?? testInterstitialUnitID
        #endif
    }

    static var appID: String {
        #if targetEnvironment(simulator)
        testAppID
        #else
        stringPlistKey("GADApplicationIdentifier") ?? testAppID
        #endif
    }

    /// Play time between two interstitials. The ad shows when a game has
    /// run for this long since the last ad. Game launches and this ad ignore
    /// the cooldown below.
    static let playTimeInterval: TimeInterval = 30 * 60

    /// Minimum seconds between interstitials (free tier). Game launches ignore it.
    static let interstitialCooldown: TimeInterval = 10 * 60

    /// AdMob request. Personalization follows the UMP consent and the ATT
    /// choice, which the SDK reads itself.
    static func adRequest() -> GADRequest {
        GADRequest()
    }

    private static func stringPlistKey(_ key: String) -> String? {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            !raw.isEmpty,
            !raw.hasPrefix("$(")
        else { return nil }
        return raw
    }
}
