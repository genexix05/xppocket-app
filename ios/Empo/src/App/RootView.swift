import SwiftUI

struct RootView: View {
    @Environment(\.appState) private var appState
    @Environment(\.engineState) private var engineState
    @Environment(\.controlsLayout) private var layout
    @Namespace private var hero
    /// The library stays mounted through the loading→playing fade.
    /// It then unmounts, so Ken Burns / NavigationStack stop
    /// compositing over the embedded game view.
    @State private var libraryMounted = true

    @State private var showLaunchProSheet = false
    @Environment(\.accountSession) private var accountSession
    @Environment(\.gameLibrary) private var library

    var body: some View {
        ZStack {
            // Opaque in library; clear only while playing so SDL shows
            // through the overlay chrome.
            Group {
                if appState.phase == .playing {
                    Color.clear
                } else {
                    Color(.systemBackground)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                AppWindow.revealSwiftUIShell()
            }

            // Fade the library out on play (loading banner handoff).
            // Then unmount after the spring, so Ken Burns /
            // NavigationStack do not keep running over the embedded
            // game view. Remounts on pause/return. GameLibraryView
            // clears the path.
            if libraryMounted {
                GameLibraryView(heroNamespace: hero)
                    .opacity(appState.phase == .playing ? 0 : 1)
                    .allowsHitTesting(appState.phase != .playing)
                    .transition(.identity)
            }

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
                // Slightly longer than GameLoadingView's handoff spring
                // (0.15–0.30s) so the fade finishes before unmount.
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(400))
                    guard appState.phase == .playing else { return }
                    libraryMounted = false
                }
            } else {
                libraryMounted = true
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
            (engineHung || appState.phase != nil) ? "Restart \(AppInfo.name)" : "Something went wrong",
            isPresented: showErrorAlert
        ) {
            Button("OK") {
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
                    "\(appState.errorMessage ?? "An error occurred.") Close \(AppInfo.name) from the app switcher and reopen it to continue."
                )
            } else {
                Text(appState.errorMessage ?? "")
            }
        }
        .alert(
            infoAlertTitle,
            isPresented: showInfoAlert
        ) {
            Button("OK") {
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

    /// Unblocks any engine thread waiting in `mkxp_presentErrorAndWait()`.
    private func dismissErrorAlert() {
        mkxp_signalErrorDismissed()
        appState.errorMessage = nil
    }

    private var showInfoAlert: Binding<Bool> {
        Binding(
            get: { appState.infoMessage != nil },
            set: { if !$0 { dismissInfoAlert() } }
        )
    }

    /// The game speaks in its own name. Title the alert after the
    /// running game, so the notice does not read as an Empo message.
    private var infoAlertTitle: String {
        appState.selectedGame?.title
            ?? PauseManager.shared.pausedGame?.title
            ?? "Message"
    }

    /// Unblocks the engine thread that waits in `mkxp_presentInfoAndWait()`.
    /// The game resumes right where it called `msgbox`.
    private func dismissInfoAlert() {
        mkxp_signalInfoDismissed()
        appState.infoMessage = nil
    }

    /// True when the RGSS thread did not ack a termination request in
    /// time. Ruby is then in an unrecoverable state. The single-thread
    /// engine architecture cannot respawn the VM in place, so the only
    /// way out is for the user to close and reopen the app manually.
    /// We do not call `exit()`, per App Store guideline 2.5.1.
    private var engineHung: Bool {
        mkxp_isEngineHung() != 0
    }
}
