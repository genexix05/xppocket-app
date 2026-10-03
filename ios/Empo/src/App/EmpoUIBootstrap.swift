import UIKit

/// Ensures the SwiftUI shell appears above SDL's blank launch window.
@objc(EmpoUIBootstrap)
final class EmpoUIBootstrap: NSObject {
    private static var launchObserver: CFRunLoopObserver?
    private static var shellReady = false

    @objc static func ensureAppWindowInstalled() {
        dispatchPrecondition(condition: .onQueue(.main))
        registerLaunchObserverIfNeeded()
        AppWindow.install()
        dismissSDLLaunchScreenIfShellReady()
    }

    @objc static func dismissSDLLaunchScreen() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { dismissSDLLaunchScreen() }
            return
        }
        dismissSDLLaunchScreenIfShellReady()
    }

    /// Called on every mkxp_waitForGamePath run-loop pump so SwiftUI can
    /// layout and draw while SDL_main blocks the main thread.
    @objc static func pumpWhileWaiting() {
        registerLaunchObserverIfNeeded()
        AppWindow.install()
        AppWindow.pumpShellWhileWaiting()
        dismissSDLLaunchScreenIfShellReady()
    }

    /// Called once the SwiftUI root has appeared and can paint content.
    @objc static func markSwiftUIShellReady() {
        shellReady = true
        dismissSDLLaunchScreenIfShellReady()
    }

    /// Only peel SDL's blank launch window away after our overlay exists
    /// and has a non-zero layout. Hiding it too early (common under Xcode
    /// Play timing) leaves a blank screen with nothing underneath.
    @objc static func dismissSDLLaunchScreenIfShellReady() {
        guard AppWindow.isInstalled else { return }

        if
            let delegate = UIApplication.shared.delegate,
            delegate.responds(to: #selector(SDLLaunchScreenDismissable.hideLaunchScreen))
        {
            _ = delegate.perform(#selector(SDLLaunchScreenDismissable.hideLaunchScreen))
        }
    }

    private static func registerLaunchObserverIfNeeded() {
        guard launchObserver == nil else { return }

        var context = CFRunLoopObserverContext(
            version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        let observer = CFRunLoopObserverCreate(
            kCFAllocatorDefault,
            CFRunLoopActivity.beforeWaiting.rawValue | CFRunLoopActivity.exit.rawValue,
            true,
            0,
            { _, _, _ in
                EmpoUIBootstrap.ensureAppWindowInstalled()
            },
            &context
        )
        launchObserver = observer
        if let observer {
            CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
        }
    }
}

/// SDL's app delegate exposes `-hideLaunchScreen` but not in a public header.
@objc protocol SDLLaunchScreenDismissable {
    func hideLaunchScreen()
}
