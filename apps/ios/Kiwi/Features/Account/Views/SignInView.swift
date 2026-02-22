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

            if let errorMessage = appState.signInError {
                Text(errorMessage)
                    .font(KiwiTypography.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KiwiSpacing.xxl)
                    .transition(.opacity)
            }

            if appState.isSigningIn {
                ProgressView()
                    .frame(height: 50)
            } else {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email]
                } onCompletion: { result in
                    handleSignIn(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal, KiwiSpacing.xxl)
                .accessibilityLabel("Sign in with Apple")
            }

            Text("We never store your fridge photos. Images are processed and immediately deleted.")
                .font(KiwiTypography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KiwiSpacing.xxl)

            Spacer()
                .frame(height: KiwiSpacing.xxl)
        }
        .animation(.default, value: appState.signInError)
        .animation(.default, value: appState.isSigningIn)
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken else {
                appState.signInError = "Could not retrieve credentials. Please try again."
                return
            }
            Task {
                await appState.signIn(identityToken: identityToken)
            }
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return
            }
            appState.signInError = "Sign in with Apple failed. Please try again."
        }
    }
}

#Preview {
    SignInView()
        .environment(AppState())
}
