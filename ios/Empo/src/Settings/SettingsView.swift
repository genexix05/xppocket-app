import SwiftUI

struct SettingsView: View {
    @Environment(\.appSettings) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var showBuildInfo = false
    @State private var showWhatsNew = false

    // We deleted the ExperimentalFeature toggles and the
    // ConfirmSheet/InfoSheet when gamePause/cheats graduated. See
    // the ExperimentalFeature comment block in AppSettings.swift
    // for how to bring opt-in toggles back.

    var body: some View {
        @Bindable var settings = settings
        return NavigationStack {
            Form {
                settingsHeader

                AccountSettingsSection()

                Section {
                    SettingsPicker(
                        title: "Theme",
                        selection: $settings.theme,
                        description: "System follows your device's appearance setting."
                    ) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.label).tag(theme)
                        }
                    }

                    SettingsPicker(
                        title: "Layout",
                        selection: $settings.libraryDisplayMode,
                        description: "Show games as a grid of cards or a compact list."
                    ) {
                        ForEach(LibraryDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }

                    // Title position only affects grid cards. The
                    // list layout always puts the title next to the
                    // artwork. Hide the row when it would be a no-op.
                    if settings.libraryDisplayMode == .grid {
                        SettingsPicker(
                            title: "Title position",
                            selection: $settings.titlePosition,
                            description: "Where game titles show up on your library cards."
                        ) {
                            ForEach(TitlePosition.allCases, id: \.self) { position in
                                Text(position.label).tag(position)
                            }
                        }
                    }

                    SettingsToggle(
                        title: "Interface haptics",
                        isOn: $settings.interfaceHaptics,
                        description:
                            "Feel a gentle tap when you press buttons and switches."
                    )

                    SettingsToggle(
                        title: "Continue playing",
                        isOn: $settings.showContinuePlaying,
                        description:
                            "Shows a card at the top of your library for your last game."
                    )
                } header: {
                    Text("Appearance")
                }

                Section {
                    SettingsNavigationRow(
                        title: "Layout profiles",
                        description:
                            "Create and edit saved layouts for the on-screen controls and the game screen."
                    ) {
                        LayoutProfilesSettingsView()
                    }

                    SettingsNavigationRow(
                        title: "Community layouts",
                        description:
                            "Browse and install touch-control layouts shared by the XP Pocket community."
                    ) {
                        CommunityLayoutsView()
                    }

                    SettingsToggle(
                        title: "Controller haptics",
                        isOn: $settings.controllerHaptics,
                        description: "Vibration feedback on the on-screen game controls while you play."
                    )
                } header: {
                    Text("Gameplay")
                }

                Section {
                    SettingsToggle(
                        title: "Diagnostics overlay",
                        isOn: $settings.diagnosticsOverlay,
                        description:
                            "Adds a toolbar button that shows frame rate, memory use, and details about the game engine while you play."
                    )

                    SettingsToggle(
                        title: "Fill unused screen area",
                        isOn: $settings.showViewportBounds,
                        description:
                            "Fill the screen area outside the game picture with a color you choose."
                    )

                    if settings.showViewportBounds {
                        NavigationLink {
                            ViewportBoundsColorPicker(color: $settings.viewportBoundsColor)
                        } label: {
                            HStack {
                                Text("Fill color")
                                Spacer()
                                RoundedRectangle(cornerRadius: Radius.xs)
                                    .fill(settings.viewportBoundsColor)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }

                    SettingsToggle(
                        title: "Show touch area",
                        isOn: $settings.showTouchZone,
                        description:
                            "Outlines where your taps and drags control the game's cursor."
                    )

                    SettingsToggle(
                        title: "Delete broken imports",
                        isOn: $settings.cleanupInvalidGames,
                        description:
                            "Deletes games that failed to import the next time you open \(AppInfo.name). You can't undo this."
                    )

                    SettingsToggle(
                        title: "Debug logs",
                        isOn: $settings.debugLogs,
                        description:
                            "Saves a log for each play session. Find them in Files, under \(AppInfo.name) › Games › the game's name › Logs."
                    )

                    if settings.debugLogs {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Stepper(
                                "Keep last \(settings.maxLogFiles) logs per game",
                                value: $settings.maxLogFiles, in: 5...100, step: 5)
                            Text("\(AppInfo.name) deletes older logs each time you start a game.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, Spacing.xxs)
                    }
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("These options are for debugging and troubleshooting.")
                }

                Section {
                    Button {
                        showWhatsNew = true
                    } label: {
                        Label("What's new", systemImage: "sparkles")
                    }
                    .tint(.primary)

                    NavigationLink {
                        GameCoresView()
                    } label: {
                        Label("Game cores", systemImage: "cpu")
                    }

                    NavigationLink {
                        ChangelogView()
                    } label: {
                        Label("Changelog", systemImage: "list.bullet.rectangle")
                    }

                    NavigationLink {
                        CreditsView()
                    } label: {
                        Label("Credits", systemImage: "person.2")
                    }

                    NavigationLink {
                        LicensesView()
                    } label: {
                        Label("Open-source licenses", systemImage: "doc.text")
                    }

                    externalLink(
                        title: "Privacy Policy",
                        systemImage: "hand.raised",
                        url: AppInfo.privacyURL)

                    externalLink(
                        title: "Terms of Use",
                        systemImage: "doc.plaintext",
                        url: AppInfo.termsURL)

                    externalLink(
                        title: "Source code (GPL)",
                        systemImage: "chevron.left.forwardslash.chevron.right",
                        url: AppInfo.sourceCodeURL)

                    FeedbackShareButton(
                        label: "Send feedback",
                        systemImage: "exclamationmark.bubble",
                        formRowStyle: true
                    )

                    externalLink(
                        title: "Website",
                        systemImage: "globe",
                        url: AppInfo.websiteURL)
                } header: {
                    Text("About")
                } footer: {
                    Text("\(AppInfo.name) is free software. You can redistribute and modify it under the terms of the GNU General Public License.")
                }
            }
            .sheet(isPresented: $showBuildInfo) {
                BuildInfoSheet()
            }
            .sheet(isPresented: $showWhatsNew) {
                WhatsNewSheet(items: WhatsNew.items(after: WhatsNew.version - 1)) {
                    showWhatsNew = false
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(.brand)
    }

    @ViewBuilder
    private func externalLink(title: String, systemImage: String, url: URL) -> some View {
        Link(destination: url) {
            Label {
                HStack {
                    Text(title)
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: systemImage)
            }
        }
        .tint(.primary)
    }

    private var buildVersionButton: some View {
        Button {
            showBuildInfo = true
        } label: {
            Text("v\(AppInfo.version)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Version \(AppInfo.version)")
        .accessibilityHint("Shows build details")
    }

    private var settingsHeader: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Image(.pocketMark)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(AppInfo.name)
                    .font(.headline.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
            }

            buildVersionButton
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .environment(\.headerProminence, .standard)
    }
}


/// A sheet that appears when the user taps the version label in the
/// settings header. Shows build details as a grouped list styled to
/// match GameInfoView. The sheet includes the branch row only when
/// the current branch differs from the default, so release builds on
/// `main` stay minimal.
///
/// Uses the same navigation-stack-with-inline-title pattern as
/// SettingsView / GameInfoView / GameSettingsView so the toolbar reads
/// as native chrome (centered inline title, trailing Done button).
private struct BuildInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// A detail row shown in the list. `value` is the copyable string.
    /// The optional `annotation` renders next to it but stays out of
    /// the text-selection range. Users can then long-press to copy only
    /// the canonical value (e.g. the commit hash without the
    /// "(uncommitted changes)" suffix).
    private struct Row: Identifiable {
        let label: String
        let value: String
        var annotation: String?
        var id: String { label }
    }

    private var rows: [Row] {
        var r: [Row] = []
        r.append(Row(label: "Version", value: AppInfo.version))
        r.append(Row(label: "Build", value: AppInfo.build))
        r.append(
            Row(
                label: "Commit",
                value: GitInfo.commit,
                annotation: GitInfo.dirty ? "(uncommitted changes)" : nil
            ))
        if !GitInfo.branch.isEmpty, GitInfo.branch != GitInfo.defaultBranch {
            r.append(Row(label: "Branch", value: GitInfo.branch))
        }
        return r
    }

    var body: some View {
        StandardSheet(
            title: "Build info",
            chromeAllowance: AppSize.libraryHeader,
            trailingButton: SheetBarAction("Done") { dismiss() }
        ) {
            SheetCard {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 {
                        Divider().padding(.leading, Spacing.xl)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                        Text(row.label)
                        Spacer(minLength: Spacing.md)
                        // RootView applies `.fontDesign(.rounded)`
                        // to the whole app tree. Environment
                        // resolution lets it override any
                        // `.font(design: .monospaced)` set here.
                        // Set `.monospaced` again explicitly so the
                        // value's font reads as fixed-width.
                        Text(row.value)
                            .font(.system(size: 15))
                            .fontDesign(.monospaced)
                            .textSelection(.enabled)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        if let annotation = row.annotation {
                            Text(annotation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.lg)
                }
            }
        }
    }
}

private struct ViewportBoundsColorPicker: View {
    @Binding var color: Color

    var body: some View {
        Form {
            Section {
                ColorPicker("Fill color", selection: $color, supportsOpacity: true)
            }

            Section {
                HStack(spacing: Spacing._2xl) {
                    Spacer()
                    DevicePreview(color: color, isLandscape: false)
                    DevicePreview(color: color, isLandscape: true)
                    Spacer()
                }
                .padding(.vertical, Spacing.xl)
                .listRowBackground(Color.clear)
            } header: {
                Text("Preview")
            }
        }
        .navigationTitle("Fill color")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Miniature device mockup showing the game viewport and fill color.
private struct DevicePreview: View {
    let color: Color
    let isLandscape: Bool

    // Device proportions (roughly iPhone-like)
    private let portraitW: CGFloat = 70
    private let portraitH: CGFloat = 150
    private let cornerRadius: CGFloat = Radius.md
    private let bezelWidth: CGFloat = 2
    private let notchHeight: CGFloat = 8

    private var deviceW: CGFloat { isLandscape ? portraitH : portraitW }
    private var deviceH: CGFloat { isLandscape ? portraitW : portraitH }

    var body: some View {
        ZStack {
            // Device bezel
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.secondary.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.secondary.opacity(Alpha.indicatorStroke), lineWidth: 1)
                )

            // Screen area
            let screenInset = bezelWidth + 2
            let screenW = deviceW - screenInset * 2
            let screenH = deviceH - screenInset * 2

            RoundedRectangle(cornerRadius: cornerRadius - 3)
                .fill(color)
                .padding(screenInset)

            // Game viewport
            let gameRect = gameViewportRect(screenW: screenW, screenH: screenH)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black)
                .frame(width: gameRect.width, height: gameRect.height)
                .offset(x: gameRect.offsetX, y: gameRect.offsetY)

            // Notch indicator
            notchView
        }
        .frame(width: deviceW, height: deviceH)
    }

    private var notchView: some View {
        Group {
            if isLandscape {
                // Notch on the left
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 4,
                    topTrailingRadius: 4
                )
                .fill(.secondary.opacity(Alpha.indicatorFill))
                .frame(width: notchHeight, height: 20)
                .offset(x: -(deviceW / 2 - notchHeight / 2))
            } else {
                // Notch on top
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 4,
                    bottomTrailingRadius: 4,
                    topTrailingRadius: 0
                )
                .fill(.secondary.opacity(Alpha.indicatorFill))
                .frame(width: 28, height: notchHeight)
                .offset(y: -(deviceH / 2 - notchHeight / 2))
            }
        }
    }

    private struct GameRect {
        let width: CGFloat
        let height: CGFloat
        let offsetX: CGFloat
        let offsetY: CGFloat
    }

    private func gameViewportRect(screenW: CGFloat, screenH: CGFloat) -> GameRect {
        // Simulate a 4:3 game aspect ratio
        let gameAspect: CGFloat = 4.0 / 3.0
        let safeTopInset: CGFloat = notchHeight + 2

        if isLandscape {
            // Landscape: game centered, safe insets on left
            let safeLeftInset: CGFloat = notchHeight + 2
            let availW = screenW - safeLeftInset
            let availH = screenH
            var gameW = availW
            var gameH = gameW / gameAspect
            if gameH > availH {
                gameH = availH
                gameW = gameH * gameAspect
            }
            let offsetX = (safeLeftInset - 0) / 2
            return GameRect(width: gameW, height: gameH, offsetX: offsetX, offsetY: 0)
        } else {
            // Portrait: game top-center aligned within safe area
            let availW = screenW
            let availH = screenH - safeTopInset
            var gameW = availW
            var gameH = gameW / gameAspect
            if gameH > availH * 0.6 {
                gameH = availH * 0.6
                gameW = gameH * gameAspect
            }
            // Top-center: between top and center
            let topY = -(screenH / 2 - safeTopInset - gameH / 2 - 2)
            let centerY: CGFloat = 0
            let offsetY = (topY + centerY) / 2
            return GameRect(width: gameW, height: gameH, offsetX: 0, offsetY: offsetY)
        }
    }
}
