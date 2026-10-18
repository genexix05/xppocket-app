import SwiftUI

struct RootView: View {
    @Environment(\.appState) private var appState
    @Environment(\.engineState) private var engineState
    @Environment(\.controlsLayout) private var layout
    @Environment(\.gameLibrary) private var library
    @Environment(\.accountSession) private var accountSession
    @Namespace private var hero
    @State private var showLaunchProSheet = false
    /// The library goes quiet after the loading→playing fade. It
    /// stays mounted and keeps its navigation stack, but the pushed
    /// loading view renders nothing, so Ken Burns and the container
    /// fill stop compositing over the embedded game view.
    ///
    /// An earlier version took the whole library out of the tree
    /// instead. That threw the navigation path away, so the library
    /// came back at the root and the pause showed no reverse zoom.
    /// Putting the path back by hand was not enough either: a
    /// rebuilt stack keeps no record of the push, so the zoom went
    /// to the middle of the screen instead of to the card.
    @State private var libraryDormant = false
    /// Drives the handoff fade. It is a state of its own, not a read
    /// of the phase, so the way back can snap. `AppWindow` paints the
    /// root background for the zoom transition, and a fade in over
    /// that colour reads as a white flash.
    @State private var libraryFaded = false


    var body: some View {
        ZStack {
            // Explicit transparent base. Without this, SwiftUI can
            // default the UIHostingController backdrop to
            // systemBackground, which occludes the SDL window on
            // device even when every child view is "clear".
            Color.clear.ignoresSafeArea()

            // Fade the library out on play (loading banner
            // handoff). It then goes dormant after the spring, so
            // Ken Burns does not keep running over the embedded game
            // view. It never leaves the tree: the pause pops the
            // pushed game, and that pop needs the same navigation
            // stack the push used.
            GameLibraryView(
                heroNamespace: hero,
                dormant: libraryDormant
            )
            // Flatten first. Without this, the fade applies to
            // each layer on its own, so the loading banner turns
            // see-through over the grid and the library shows for a
            // moment before the game does.
            .compositingGroup()
            .opacity(libraryFaded ? 0 : 1)
            .allowsHitTesting(appState.phase != .playing)

            // Instant appear: the library fades out underneath without
            // a cross-fade dim on the controls.
            if appState.phase == .playing {
                PlayerView(appState: appState, engineState: engineState, layout: layout)
                    .transition(.identity)
                    .allowsHitTesting(
                        appState.errorMessage == nil && appState.infoMessage == nil
                    )
            }
        }
        .fontDesign(.rounded)
        .tint(.brand)
        .onChange(of: appState.phase) { _, phase in
            if phase == .playing {
                // GameLoadingView flips the phase inside a spring of
                // 0.15–0.30s. This change runs after that
                // transaction, so it needs a spring of its own.
                withAnimation(.spring(duration: 0.3, bounce: 0)) {
                    libraryFaded = true
                }
                // Slightly longer than GameLoadingView's handoff spring
                // (0.15–0.30s) so the fade finishes first.
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(400))
                    guard appState.phase == .playing else { return }
                    libraryDormant = true
                }
            } else {
                // No fade on the way back. The pause plays the zoom
                // in reverse, and the library must be there in full
                // for it, not dissolving in over the root colour.
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) {
                    libraryFaded = false
                    libraryDormant = false
                }
            }
        }
        .task {
            if appState.pendingCrashRecovery {
                appState.consumeCrashRecovery()
            }
            // Defer AdMob until after the first frame so scene-create
            // is not competing with SDK init on cold launch.
            Task {
                try? await Task.sleep(for: .milliseconds(800))
                AdCoordinator.shared.prepare()
            }
            Task {
                await AccountSession.shared.refreshOnLaunch()
                await SubscriptionManager.shared.loadProducts()
                await SubscriptionManager.shared.refreshLocalEntitlements()
            }
            guard !accountSession.hasPro else { return }
            while !library.initialScanCompleted {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
            }
            try? await Task.sleep(for: .milliseconds(400))
            guard !accountSession.hasPro else { return }
            showLaunchProSheet = true
        }
        .sheet(isPresented: $showLaunchProSheet) {
            ProPaywallView(isLaunchPromo: true)
        }
        .onChange(of: accountSession.hasPro) { _, hasPro in
            if hasPro { showLaunchProSheet = false }
        }
        .alert(
            (engineHung || appState.phase != nil) ? String(localized: "Restart \(AppInfo.name)") : String(localized: "Last session ended early"),
            isPresented: showErrorAlert
        ) {
            Button("Got it") {
                dismissErrorAlert()
                if engineHung {
                    return
                }
                if appState.phase != nil {
                    return
                }
                appState.dismissCrashRecovery()
            }
        } message: {
            if engineHung {
                Text("The game stopped responding. Close \(AppInfo.name) and reopen it.")
            } else if appState.phase != nil {
                Text(
                    "\(appState.errorMessage ?? "The game stopped.")\n\nClose \(AppInfo.name) from the app switcher, then reopen it."
                )
            } else {
                Text(appState.errorMessage ?? "")
            }
        }
        .alert(
            infoAlertTitle,
            isPresented: showInfoAlert
        ) {
            Button("Continue") {
                dismissInfoAlert()
            }
        } message: {
            Text(appState.infoMessage ?? "")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) {
            _ in
            if appState.phase == .playing {
                engineState.requestBackgroundPause()
                // If the engine rendered at least one frame, this was a
                // healthy session. Remove the crash marker, so a
                // force-kill from the app switcher does not trigger a
                // false crash alert. Black-screen crashes leave
                // engineReady false, so the marker persists and the
                // alert still fires.
                if appState.engineReady {
                    appState.clearCrashMarkerForBackground()
                }
            }
            // Persist play time when the app backgrounds, so a
            // force-kill from the switcher does not lose the session.
            // No-op when the timer already flushed (e.g. the user
            // paused to the library).
            appState.flushSessionPlayTimeForBackground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) {
            _ in
            if appState.phase == .playing {
                engineState.resumeFromBackground()
                // Re-create the crash marker, so the next launch still
                // detects a crash after resume.
                appState.restoreCrashMarkerForForeground()
                appState.resumeSessionTimingAfterBackground()
            }
        }
        .onChange(of: appState.errorMessage) { _, message in
            if message != nil {
                AppWindow.setAllowKeyWindow(true)
            } else if appState.phase == .playing, appState.infoMessage == nil {
                AppWindow.setAllowKeyWindow(false)
            } else if appState.phase != .playing, appState.infoMessage == nil {
                AppWindow.setAllowKeyWindow(false)
            }
        }
        .onChange(of: appState.infoMessage) { _, message in
            if message != nil {
                AppWindow.setAllowKeyWindow(true)
            } else if appState.phase == .playing, appState.errorMessage == nil {
                AppWindow.setAllowKeyWindow(false)
            } else if appState.phase != .playing, appState.errorMessage == nil {
                AppWindow.setAllowKeyWindow(false)
            }
        }
    }

    private var showErrorAlert: Binding<Bool> {
        Binding(
            get: { appState.errorMessage != nil },
            set: { if !$0 { dismissErrorAlert() } }
        )
    }

    /// Unblocks a core that waits for the error alert to close.
    private func dismissErrorAlert() {
        if EmpoCoreIsOpen() != 0 { gamecore_signalErrorDismissed() }
        appState.errorMessage = nil
    }

    private var showInfoAlert: Binding<Bool> {
        Binding(
            get: { appState.infoMessage != nil },
            set: { if !$0 { dismissInfoAlert() } }
        )
    }

    /// The game speaks in its own name. Title the alert after the
    /// running game, so the notice does not read as an app message.
    private var infoAlertTitle: String {
        appState.selectedGame?.title
            ?? PauseManager.shared.pausedGame?.title
            ?? "Game message"
    }

    /// Unblocks the core that waits for the info alert to close.
    /// The game resumes right where it called `msgbox`.
    private func dismissInfoAlert() {
        if EmpoCoreIsOpen() != 0 { gamecore_signalInfoDismissed() }
        appState.infoMessage = nil
    }

    /// True when the RGSS thread did not ack a termination request in
    /// time. Ruby is then in an unrecoverable state. The single-thread
    /// engine architecture cannot respawn the VM in place, so the only
    /// way out is for the user to close and reopen the app manually.
    /// We do not call `exit()`, per App Store guideline 2.5.1.
    private var engineHung: Bool {
        EmpoCoreIsOpen() != 0 && gamecore_isEngineHung() != 0
    }
}
