import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @Environment(AppState.self) private var appState
    @State private var error: AppError?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.kiwiPrimary)
                .accessibilityHidden(true)
            Text("Cook smarter with what you have")
                .font(.kiwiHeadline)
                .multilineTextAlignment(.center)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.email]
            } onCompletion: { result in
                Task { @MainActor in
                    switch result {
                    case .success(let auth):
                        if let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                           let token = credential.identityToken {
                            do {
                                try await appState.signIn(identityToken: token)
                            } catch {
                                self.error = .unauthorized
                            }
                        }
                    case .failure:
                        self.error = .unauthorized
                    }
                }
            }
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("We never store your fridge photos. Images are processed and immediately deleted.")
                .font(.kiwiCaption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if let error {
                Text(error.message)
                    .font(.kiwiCaption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }
}
