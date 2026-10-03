import AuthenticationServices
import SwiftUI

/// Sign-in UI shared by Settings and Game Settings.
struct AccountSignInControls: View {
    @Environment(\.accountSession) private var session
    let onError: (String) -> Void

    var body: some View {
        AppleSignInButton { token in
            Task {
                do {
                    try await session.signIn(identityToken: token)
                } catch {
                    onError(error.localizedDescription)
                }
            }
        } onFailure: { error in
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue { return }
            onError(error.localizedDescription)
        }
        .disabled(session.isBusy)
    }
}
