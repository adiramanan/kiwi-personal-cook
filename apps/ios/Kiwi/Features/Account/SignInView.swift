import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo and tagline
            VStack(spacing: 20) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.kiwiGreen)
                    .accessibilityLabel("Kiwi app icon")

                VStack(spacing: 8) {
                    Text("Kiwi")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Cook smarter with what you have")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // Sign in button
            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email]
                } onCompletion: { result in
                    handleSignInResult(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityLabel("Sign in with Apple")
                .accessibilityHint("Creates or signs into your Kiwi account using Apple ID")

                // Privacy disclosure
                Text("We never store your fridge photos. Images are processed and immediately deleted.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.horizontal, 24)

            Spacer()
                .frame(height: 48)
        }
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let identityToken = credential.identityToken {
                Task {
                    try await appState.signIn(identityToken: identityToken)
                }
            }
        case .failure:
            // Sign in was cancelled or failed — no action needed
            break
        }
    }
}

#Preview {
    SignInView()
        .environment(AppState())
}
