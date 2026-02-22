import SwiftUI
import AuthenticationServices

@Observable
final class AppState {
    var isAuthenticated: Bool = false
    var sessionToken: String?
    var signInError: String?
    var isSigningIn: Bool = false

    init() {
        if let token = KeychainHelper.getToken() {
            sessionToken = token
            isAuthenticated = true
        }
    }

    func signIn(identityToken: Data) async {
        signInError = nil
        isSigningIn = true
        defer { isSigningIn = false }

        do {
            let authService = AuthService()
            let session = try await authService.authenticate(identityToken: identityToken)
            KeychainHelper.save(token: session.sessionToken)
            sessionToken = session.sessionToken
            isAuthenticated = true
        } catch let error as APIError {
            signInError = error.userMessage
        } catch {
            signInError = "Sign in failed. Please try again."
        }
    }

    func signOut() {
        KeychainHelper.deleteToken()
        sessionToken = nil
        isAuthenticated = false
        signInError = nil
    }
}
