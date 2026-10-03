import SwiftUI

/// Third-party and upstream credits shown under Settings → About.
struct CreditsView: View {
    var body: some View {
        List {
            Section {
                creditRow(
                    title: AppInfo.name,
                    subtitle: "iOS player for RPG Maker XP, VX, and mkxp-z games.",
                    detail:
                        "\(AppInfo.name) is free software licensed under the GNU General Public License v2 or later. Source code is available at xppocket.app."
                )
            } header: {
                Text("This app")
            }

            Section {
                creditRow(
                    title: "mkxp-z",
                    subtitle: "RGSS game engine",
                    detail:
                        "Copyright © Splendide Imaginarius, Jonas Kulla, and contributors. Licensed under GPL-2.0. Powers Ruby scripts, graphics, and audio at runtime."
                )
                creditRow(
                    title: "Empo",
                    subtitle: "Upstream project",
                    detail:
                        "\(AppInfo.name) is derived from Empo, an open-source RPG Maker player for iOS. Empo and mkxp-z contributors made this app possible."
                )
            } header: {
                Text("Engine & upstream")
            } footer: {
                Text("Full license texts are under Settings → Licenses.")
            }

            Section {
                creditRow(
                    title: "Smallbits",
                    subtitle: "Icon pack (splash pattern)",
                    detail: "Designed by Minor Adventures. Used under the Smallbits license."
                )
            } header: {
                Text("Assets")
            }
        }
        .navigationTitle("Credits")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func creditRow(title: String, subtitle: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, Spacing.xxs)
        }
        .padding(.vertical, Spacing.xxs)
    }
}
