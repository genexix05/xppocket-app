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
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
        guard let presenter = AppWindow.topViewController else { return }
        if uiView.rootViewController !== presenter {
            uiView.rootViewController = presenter
            context.coordinator.didRequestLoad = false
        }
        guard !context.coordinator.didRequestLoad else { return }
        context.coordinator.didRequestLoad = true
        uiView.load(AdsConfig.nonPersonalizedRequest())
    }

    final class Coordinator: NSObject, GADBannerViewDelegate {
        var didRequestLoad = false

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            NSLog("AdCoordinator: banner loaded")
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            NSLog("AdCoordinator: banner failed: \(error.localizedDescription)")
            didRequestLoad = false
        }
    }
}
