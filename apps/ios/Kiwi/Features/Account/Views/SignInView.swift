import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: KiwiSpacing.xl) {
            Spacer()

            Image(systemName: "leaf.fill")
                .font(.system(size: 80))
                .foregroundStyle(.kiwiGreen)
                .accessibilityHidden(true)

            Text("Kiwi")
                .font(.system(size: 44, weight: .bold, design: .rounded))

            Text("Cook smarter with what you have")
                .font(KiwiTypography.title3)
                .foregroundStyle(.secondary)

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.email]
            } onCompletion: { result in
                handleSignIn(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, KiwiSpacing.xxl)
            .accessibilityLabel("Sign in with Apple")

            Text("We never store your fridge photos. Images are processed and immediately deleted.")
                .font(KiwiTypography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KiwiSpacing.xxl)

            Spacer()
                .frame(height: KiwiSpacing.xxl)
        }
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let authorization) = result,
              let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken else {
            return
        }

        Task {
            try? await appState.signIn(identityToken: identityToken)
        }
    }
}

#Preview {
    SignInView()
        .environment(AppState())
}
