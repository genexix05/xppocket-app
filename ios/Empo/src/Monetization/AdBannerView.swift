import GoogleMobileAds
import SwiftUI

/// Fixed library banner for free users.
struct AdBannerView: View {
    @Environment(\.accountSession) private var session

    var body: some View {
        if !session.hasPro, AdsConfig.isConfigured {
            AdBannerRepresentable()
                .frame(height: 50)
                .background(Color(.secondarySystemBackground))
                .onAppear { AdCoordinator.shared.prepare() }
        }
    }
}

private struct AdBannerRepresentable: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
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
            banner.load(AdsConfig.nonPersonalizedRequest())
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
