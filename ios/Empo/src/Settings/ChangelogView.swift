import SwiftUI

/// User-facing release notes. Add a section when shipping a new version.
enum AppChangelog {
    struct Release: Identifiable {
        let id: String
        let version: String
        let date: String
        let notes: [String]
    }

    static let releases: [Release] = [
        Release(
            id: "1.0.0",
            version: "1.0.0",
            date: "August 2026",
            notes: [
                "First XP Pocket release — RPG Maker XP, VX, VX Ace, and mkxp-z on iPhone and iPad.",
                "Import games from folders, ZIP, 7z, RAR, and JoiPlay (.jgp) archives.",
                "Customizable touch controls with per-game layout profiles.",
                "Library with grid/list views, search, and sort.",
                "Optional Sign in with Apple, XP Pocket Pro, cloud save, and AdMob for free users.",
                "Pause and resume with a hero zoom back to the library.",
            ]
        ),
    ]
}

struct ChangelogView: View {
    var body: some View {
        List {
            ForEach(AppChangelog.releases) { release in
                Section {
                    ForEach(release.notes, id: \.self) { note in
                        HStack(alignment: .top, spacing: Spacing.md) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 5))
                                .foregroundStyle(.brand)
                                .padding(.top, 7)
                            Text(note)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } header: {
                    Text("Version \(release.version)")
                } footer: {
                    Text(release.date)
                }
            }
        }
        .navigationTitle("Changelog")
        .navigationBarTitleDisplayMode(.inline)
    }
}
