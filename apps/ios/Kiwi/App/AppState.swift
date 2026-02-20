import SwiftUI
import AuthenticationServices

@Observable
final class AppState {
    var isAuthenticated: Bool = false
    var sessionToken: String?

    init() {
        if let token = KeychainHelper.getToken() {
            sessionToken = token
            isAuthenticated = true
        }
    }

    func signIn(identityToken: Data) async throws {
        let authService = AuthService()
        let session = try await authService.authenticate(identityToken: identityToken)
        KeychainHelper.save(token: session.sessionToken)
        sessionToken = session.sessionToken
        isAuthenticated = true
    }

    func signOut() {
        KeychainHelper.deleteToken()
        sessionToken = nil
        isAuthenticated = false
    }
}
