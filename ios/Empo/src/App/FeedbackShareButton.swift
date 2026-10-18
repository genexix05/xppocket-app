import SwiftUI

/// Presents feedback export: tries the XP Pocket API first, then
/// falls back to the system share sheet (Mail, Files, etc.).
struct FeedbackShareButton: View {
    let label: String
    let systemImage: String
    var context: FeedbackReporter.Context = FeedbackReporter.Context()
    /// When true, lay out like a Settings form row instead of a standalone button.
    var formRowStyle = false
    /// When true, use a prominent filled button (e.g. on the loading error screen).
    var prominentStyle = false

    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isSending = false
    @State private var statusMessage: String?

    var body: some View {
        Button {
            Task { await sendFeedback() }
        } label: {
            if formRowStyle {
                Label {
                    HStack {
                        Text(label)
                        Spacer()
                        if isSending {
                            ProgressView()
                        }
                    }
                } icon: {
                    Image(systemName: systemImage)
                }
            } else {
                Label(label, systemImage: systemImage)
            }
        }
        .disabled(isSending)
        .modifier(FeedbackButtonStyle(formRowStyle: formRowStyle, prominentStyle: prominentStyle))
        .tint(formRowStyle ? .primary : .brand)
        .sheet(isPresented: $showShareSheet) {
            ActivityShareSheet(items: shareItems)
        }
        .alert("Feedback", isPresented: Binding(
            get: { statusMessage != nil },
            set: { if !$0 { statusMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(statusMessage ?? "")
        }
    }

    @MainActor
    private func sendFeedback() async {
        isSending = true
        defer { isSending = false }

        do {
            try await FeedbackReporter.submit(context)
            statusMessage = String(localized: "Thanks — we received your report.")
            return
        } catch {
            do {
                shareItems = try FeedbackReporter.shareItems(for: context)
                showShareSheet = true
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }
}

private struct FeedbackButtonStyle: ViewModifier {
    let formRowStyle: Bool
    let prominentStyle: Bool

    func body(content: Content) -> some View {
        if formRowStyle {
            content.buttonStyle(.plain)
        } else if prominentStyle {
            content.buttonStyle(.borderedProminent)
        } else {
            content.buttonStyle(.automatic)
        }
    }
}
