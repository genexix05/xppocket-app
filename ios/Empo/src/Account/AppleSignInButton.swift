import AuthenticationServices
import SwiftUI

struct AppleSignInButton: View {
    let onToken: (String) -> Void
    let onFailure: (Error) -> Void

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.email]
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                guard
                    let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                    let tokenData = credential.identityToken,
                    let token = String(data: tokenData, encoding: .utf8)
                else {
                    onFailure(SignInError.missingToken)
                    return
                }
                onToken(token)
            case .failure(let error):
                if (error as NSError).code == ASAuthorizationError.canceled.rawValue { return }
                onFailure(error)
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .clipShape(.rect(cornerRadius: Radius.sm))
    }

    enum SignInError: LocalizedError {
        case missingToken

        var errorDescription: String? {
            switch self {
            case .missingToken: String(localized: "Apple did not return a sign-in token.")
            }
        }
    }
}
