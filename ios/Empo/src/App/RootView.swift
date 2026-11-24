// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Mateo M. Additional terms apply: see ADDITIONAL-TERMS.md.

import SwiftUI

struct RootView: View {
    @Environment(\.appState) private var appState
    @Environment(\.engineState) private var engineState
    @Environment(\.controlsLayout) private var layout
    @Environment(\.gameLibrary) private var library
    @Environment(\.accountSession) private var accountSession
    @Namespace private var hero
    @State private var showLaunchProSheet = false
    @MainActor private static var didRunLaunchTask = false
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
    /// The report that the share sheet sends, after an alert's Share
    /// Report button.
    @State private var sharedReport: GameReport?


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
                        appState.shownError == nil && appState.infoMessage == nil
                    )
            }
        }
        .fontDesign(.rounded)
        .tint(.brand)
        .task { BackupLaunchGate.shared.open() }
        // One count of play time for each stretch of play. It restarts
        // when the game resumes from a pause.
        .task(id: appState.phase == .playing) {
            guard appState.phase == .playing else { return }
            await AdCoordinator.shared.trackPlayTime(of: appState)
        }
        .onChange(of: appState.phase) { _, phase in
            if phase == .playing {
                // GameLoadingView flips the phase inside a spring of
                // 0.15–0.30s. This change runs after that
                // transaction, so it needs a spring of its own.
                withAnimation(.spring(duration: 0.3, bounce: 0)) {
                    libraryFaded = true
                } completion: {
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
            // A full-screen ad over the root makes this view appear again,
            // and the launch work (and its Pro promo) must run once only.
            guard !Self.didRunLaunchTask else { return }
            Self.didRunLaunchTask = true
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
            errorAlertTitle,
            isPresented: showErrorAlert
        ) {
            Button("Got it") {
                closeErrorAlert()
            }
            if let report = GameReport.last, report.isShareable {
                Button("Share Report") {
                    closeErrorAlert()
                    sharedReport = report
                }
            }
        } message: {
            if appState.engineHung {
                Text(
                    appState.canEndStuckGame
                        ? "It stopped responding and will close. Progress you haven't saved will be lost."
                        : "The game stopped responding. Close XP Pocket from the app switcher, then reopen it."
                )
            } else if appState.phase != nil {
                Text(
                    appState.canEndStuckGame
                        ? appState.shownError?.message
                            ?? String(localized: "Something went wrong while it was running.")
                        : "\(appState.shownError?.message ?? String(localized: "The game stopped."))\n\nClose XP Pocket from the app switcher, then reopen it."
                )
            } else {
                Text(appState.shownError?.message ?? "")
            }
        }
        .sheet(item: $sharedReport) { report in
            ReportShareSheet(report: report)
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
                    appState.clearCrashMarker()
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
                appState.restoreCrashMarker()
            }
            appState.resumeSessionTimingAfterBackground()
        }
        .onChange(of: appState.shownError) { _, error in
            if error != nil {
                AppWindow.claimKey(.alert)
            } else {
                AppWindow.releaseKey(.alert)
            }
        }
        .onChange(of: appState.infoMessage) { _, message in
            if message != nil {
                AppWindow.claimKey(.info)
            } else {
                AppWindow.releaseKey(.info)
            }
        }
    }

    private var errorAlertTitle: Text {
        if appState.shownError?.gameDidNotStart == true { return Text("Can't start the game") }
        guard appState.engineHung || appState.phase != nil else { return Text("Last session ended early") }
        return appState.canEndStuckGame ? Text("The game stopped") : Text("Restart XP Pocket")
    }

    private func closeErrorAlert() {
        let hung = appState.engineHung
        dismissErrorAlert()
        if hung { appState.endStuckGame() }
    }

    private var showErrorAlert: Binding<Bool> {
        Binding(
            get: { appState.shownError != nil },
            set: { if !$0 { dismissErrorAlert() } }
        )
    }

    /// Unblocks a core that waits for the error alert to close.
    private func dismissErrorAlert() {
        appState.shownError = nil
        appState.restoreCrashMarker()
        if EmpoCoreIsOpen() != 0 { gamecore_signalErrorDismissed() }
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
            ?? String(
                localized: "Game message",
                comment: "Title of an alert that shows a message from the running game.")
    }

    /// Unblocks the core that waits for the info alert to close.
    /// The game resumes right where it called `msgbox`.
    private func dismissInfoAlert() {
        appState.infoMessage = nil
        appState.restoreCrashMarker()
        if EmpoCoreIsOpen() != 0 { gamecore_signalInfoDismissed() }
    }
}

/// The system share sheet for a game report.
private struct ReportShareSheet: UIViewControllerRepresentable {
    let report: GameReport

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [ReportItemProvider(report: report, header: report.header())],
            applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// The share sheet reads `item` on a background thread, after the person
/// picks where to send the report. The log can be large.
private final class ReportItemProvider: UIActivityItemProvider, @unchecked Sendable {
    private let report: GameReport
    private let header: String

    init(report: GameReport, header: String) {
        self.report = report
        self.header = header
        super.init(
            placeholderItem: FileManager.default.temporaryDirectory.appendingPathComponent("report.txt"))
    }

    override var item: Any {
        do {
            return try report.write(header: header)
        } catch {
            // The placeholder is a file, so some share targets take only a file.
            let text = "\(header)\nThe report file could not be written: \(error.localizedDescription)\n"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("report.txt")
            return (try? Data(text.utf8).write(to: url)) != nil ? url : text
        }
    }
}
