import GoogleMobileAds
import SwiftUI

/// Anchored adaptive banner of the library, for free users. Google sizes it
/// for the screen width. It fills more requests and pays more than the
/// fixed 320x50 banner.
struct AdBannerView: View {
    @Environment(\.accountSession) private var session
    @State private var width: CGFloat = 0

    private var adSize: GADAdSize {
        width > 0 ? GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width) : GADAdSizeBanner
    }

    var body: some View {
        if !session.hasPro, AdsConfig.isConfigured {
            AdBannerRepresentable(adSize: adSize)
                .frame(height: adSize.size.height)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .onGeometryChange(for: CGFloat.self, of: { $0.size.width.rounded() }) { width = $0 }
                .onAppear { AdCoordinator.shared.prepare() }
        }
    }
}

private struct AdBannerRepresentable: UIViewRepresentable {
    let adSize: GADAdSize

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: adSize)
        banner.adUnitID = AdsConfig.bannerUnitID
        banner.delegate = context.coordinator
        context.coordinator.attach(banner)
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // Only re-point the presenter. A new presenter (sheet, scene change)
        // must not trigger a new ad request: AdMob refreshes a loaded banner
        // on its own schedule.
        if let presenter = AppWindow.topViewController, uiView.rootViewController !== presenter {
            uiView.rootViewController = presenter
        }
        // A new width (rotation, split view) needs a banner of the new
        // size. Changing it on a loaded banner makes the SDK load again.
        if !GADAdSizeEqualToSize(uiView.adSize, adSize) {
            uiView.adSize = adSize
        }
        context.coordinator.requestLoadIfNeeded()
    }

    @MainActor
    final class Coordinator: NSObject, GADBannerViewDelegate {
        private weak var banner: GADBannerView?
        private var inFlight = false
        private var hasAd = false
        private var failures = 0
        private var retryTask: Task<Void, Never>?
        private var readyObserver: NSObjectProtocol?

        func attach(_ banner: GADBannerView) {
            self.banner = banner
            readyObserver = NotificationCenter.default.addObserver(
                forName: AdCoordinator.didBecomeReadyNotification, object: nil, queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.requestLoadIfNeeded() }
            }
        }

        deinit {
            retryTask?.cancel()
            if let readyObserver { NotificationCenter.default.removeObserver(readyObserver) }
        }

        func requestLoadIfNeeded() {
            guard let banner, !inFlight, !hasAd, retryTask == nil,
                AdCoordinator.shared.canRequestAds,
                banner.rootViewController != nil
            else { return }
            inFlight = true
            banner.load(AdsConfig.adRequest())
        }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            NSLog("AdCoordinator: banner loaded")
            inFlight = false
            hasAd = true
            failures = 0
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            NSLog("AdCoordinator: banner failed: \(error.localizedDescription)")
            inFlight = false
            failures += 1
            // Exponential backoff: 15 s, 30 s, … capped at 10 min.
            let delay = min(15 * pow(2, Double(failures - 1)), 600)
            retryTask?.cancel()
            retryTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                self?.retryTask = nil
                self?.requestLoadIfNeeded()
            }
        }
    }
}
