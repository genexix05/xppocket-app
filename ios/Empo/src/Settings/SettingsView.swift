// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Mateo M. Additional terms apply: see ADDITIONAL-TERMS.md.

import GameProbe
import SwiftUI

enum SettingsSection: String, Decodable {
    case experimental

    var isShown: Bool {
        switch self {
        case .experimental: AppSettings.gameProcessIsInBuild
        }
    }
}

struct SettingsView: View {
    @Environment(\.appSettings) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var showBuildInfo = false
    @State private var showWhatsNew = false
    @State var scrollTarget: SettingsSection?

    var body: some View {
        @Bindable var settings = settings
        return NavigationStack {
            ScrollViewReader { proxy in
                Form {
                    settingsHeader

                    AccountSettingsSection()

                    Section {
                        LanguagePicker()

                        SettingsPicker(
                            title: "Theme",
                            selection: $settings.theme,
                            description: Text("System follows your device's appearance setting.")
                        ) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(theme.label).tag(theme)
                            }
                        }

                        SettingsPicker(
                            title: "Layout",
                            selection: $settings.libraryDisplayMode,
                            description: Text("Show games as a grid of cards or a compact list.")
                        ) {
                            ForEach(LibraryDisplayMode.allCases, id: \.self) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }

                        if settings.libraryDisplayMode == .grid {
                            SettingsPicker(
                                title: "Title position",
                                selection: $settings.titlePosition,
                                description: Text("Where game titles show up on your library cards.")
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
                            title: Text("Layout profiles"),
                            description:
                                "Create and edit saved layouts for the on-screen controls and the game screen."
                        ) {
                            LayoutProfilesSettingsView()
                        }

                        SettingsNavigationRow(
                            title: Text("Community layouts"),
                            description:
                                "Browse and install touch-control layouts shared by the XP Pocket community."
                        ) {
                            CommunityLayoutsView()
                        }

                        SettingsToggle(
                            title: "On-screen control haptics",
                            isOn: $settings.controllerHaptics,
                            description:
                                "Feel a gentle tap when you press the on-screen controls while you play."
                        )

                        SettingsToggle(
                            title: "Respect silent mode",
                            isOn: $settings.respectsSilentMode,
                            description:
                                "Mutes games when your device is in silent mode."
                        )
                    } header: {
                        Text("Gameplay")
                    }

                    Section {
                        MidiSoundSetRow()
                    } header: {
                        Text("Music")
                    }

                    Section {
                        SettingsNavigationRow(
                            title: Text("Backups"),
                            description:
                                "Keep copies of your saves in iCloud Drive, Dropbox, Google Drive, or on your own server."
                        ) {
                            BackupsScreen()
                        }
                    }

                    Section {
                        Button {
                            if let url = DataDirectory.filesAppURL(for: DataDirectory.documentsRootURL.path) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label {
                                HStack {
                                    Text("Show in Files")
                                    Spacer()
                                    Image(systemName: "arrow.up.forward")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "folder")
                            }
                        }
                        .tint(.primary)
                    } header: {
                        Text("Files")
                    } footer: {
                        if DataDirectory.isInAppGroup {
                            Text(
                                "Your games, saves, and logs are in the Files app. If Files doesn't show XP Pocket, tap Browse › ⋯ › Edit and turn on XP Pocket."
                            )
                        } else {
                            Text("Your games, saves, and logs are in the Files app.")
                        }
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
                            title: "Send error reports",
                            isOn: $settings.errorReports,
                            description:
                                "When a game shows an error or crashes, \(AppInfo.name) sends the error and the game's log to me, so I can fix it."
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
                                SettingsDescription(
                                    Text("\(AppInfo.name) deletes older logs each time you start a game."))
                            }
                            .padding(.vertical, Spacing.xxs)
                        }
                    } header: {
                        Text("Advanced")
                    } footer: {
                        Text("Use these if a game misbehaves or you want to report a bug.")
                    }

                    if SettingsSection.experimental.isShown {
                        ExperimentalSection()
                            .id(SettingsSection.experimental)
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
                            title: String(localized: "Privacy Policy"),
                            systemImage: "hand.raised",
                            url: AppInfo.privacyURL)

                        if AdCoordinator.shared.shouldShowAds, AdCoordinator.shared.isPrivacyOptionsRequired {
                            Button {
                                Task { await AdCoordinator.shared.presentPrivacyOptions() }
                            } label: {
                                Label("Privacy choices", systemImage: "checkmark.shield")
                            }
                        }

                        externalLink(
                            title: String(localized: "Terms of Use"),
                            systemImage: "doc.plaintext",
                            url: AppInfo.termsURL)

                        externalLink(
                            title: String(localized: "Source code (GPL)"),
                            systemImage: "chevron.left.forwardslash.chevron.right",
                            url: AppInfo.sourceCodeURL)

                        FeedbackShareButton(
                            label: String(localized: "Send feedback"),
                            systemImage: "exclamationmark.bubble",
                            formRowStyle: true
                        )

                        externalLink(
                            title: String(localized: "Website"),
                            systemImage: "globe",
                            url: AppInfo.websiteURL)
                    } header: {
                        Text("About")
                    } footer: {
                        Text("\(AppInfo.name) is free software. You can redistribute and modify it under the terms of the GNU General Public License.")
                    }
                }
                .onChange(of: scrollTarget, initial: true) {
                    guard let scrollTarget else { return }
                    withAnimation { proxy.scrollTo(scrollTarget, anchor: .center) }
                    self.scrollTarget = nil
                }
            }
            .sheet(isPresented: $showBuildInfo) {
                BuildInfoSheet()
            }
            .sheet(isPresented: $showWhatsNew) {
                WhatsNewSheet(
                    items: WhatsNew.items(after: WhatsNew.version - 1),
                    onOpenSettings: { section in
                        showWhatsNew = false
                        scrollTarget = section
                    },
                    onContinue: { showWhatsNew = false }
                )
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetBarButton.done { dismiss() }
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
            Text(verbatim: "v\(AppInfo.version)")
                .font(.caption)
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

private struct BuildInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// `annotation` stays outside the text selection, so a long press
    /// copies only `value`.
    private struct Row {
        let label: LocalizedStringResource
        let value: String
        var annotation: LocalizedStringResource?
    }

    private var rows: [Row] {
        var r: [Row] = []
        r.append(Row(label: "Version", value: AppInfo.version))
        r.append(
            Row(
                label: LocalizedStringResource(
                    "Build", comment: "Build info sheet: the app build number row."), value: AppInfo.build))
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
            barAction: SheetBarAction("Close") { dismiss() }
        ) {
            SheetCard {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    if index > 0 {
                        Divider().padding(.leading, Spacing.xl)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                        Text(row.label)
                        Spacer(minLength: Spacing.md)
                        // RootView's `.fontDesign(.rounded)` overrides
                        // `.font(design: .monospaced)`. Only
                        // `.fontDesign(.monospaced)` keeps a fixed width.
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

private struct DevicePreview: View {
    let color: Color
    let isLandscape: Bool

    private let portraitW: CGFloat = 70
    private let portraitH: CGFloat = 150
    private let cornerRadius: CGFloat = Radius.md
    private let bezelWidth: CGFloat = 2
    private let notchHeight: CGFloat = 8

    private var deviceW: CGFloat { isLandscape ? portraitH : portraitW }
    private var deviceH: CGFloat { isLandscape ? portraitW : portraitH }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.secondary.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.secondary.opacity(Alpha.indicatorStroke), lineWidth: 1)
                )

            let screenInset = bezelWidth + 2
            let screenW = deviceW - screenInset * 2
            let screenH = deviceH - screenInset * 2

            RoundedRectangle(cornerRadius: cornerRadius - 3)
                .fill(color)
                .padding(screenInset)

            let gameRect = gameViewportRect(screenW: screenW, screenH: screenH)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black)
                .frame(width: gameRect.width, height: gameRect.height)
                .offset(x: gameRect.offsetX, y: gameRect.offsetY)

            notchView
        }
        .frame(width: deviceW, height: deviceH)
    }

    private var notchView: some View {
        Group {
            if isLandscape {
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
        let safeTopInset: CGFloat = notchHeight + 2

        if isLandscape {
            let safeLeftInset: CGFloat = notchHeight + 2
            let availW = screenW - safeLeftInset
            let game = GameAspect.fit(width: availW, height: screenH)
            let offsetX = (safeLeftInset - 0) / 2
            return GameRect(width: game.width, height: game.height, offsetX: offsetX, offsetY: 0)
        } else {
            let game = GameAspect.fit(width: screenW, height: (screenH - safeTopInset) * 0.6)
            let topY = -(screenH / 2 - safeTopInset - game.height / 2 - 2)
            let centerY: CGFloat = 0
            let offsetY = (topY + centerY) / 2
            return GameRect(width: game.width, height: game.height, offsetX: 0, offsetY: offsetY)
        }
    }
}
