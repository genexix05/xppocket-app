import Foundation
import GoogleMobileAds

/// AdMob identifiers. Production values belong in `Ads.xcconfig` (see
/// `Ads.xcconfig.example`) and map into Info.plist via build settings.
///
/// Requests always ask for **non-personalized** ads (`npa=1`) so the app
/// does not need App Tracking Transparency for advertising (App Review 5.1.2).
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

    /// Minimum seconds between interstitials (free tier).
    static let interstitialCooldown: TimeInterval = 10 * 60

    /// Show a load interstitial every N game launches (free tier).
    static var gameLoadFrequency: Int {
        #if DEBUG
        1
        #else
        3
        #endif
    }

    /// AdMob request that opts out of personalized advertising / IDFA use.
    static func nonPersonalizedRequest() -> GADRequest {
        let request = GADRequest()
        let extras = GADExtras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        return request
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
