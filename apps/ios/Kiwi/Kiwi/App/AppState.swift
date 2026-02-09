import Foundation
import Observation

@Observable
final class AppState {
    var isAuthenticated: Bool = false
    var sessionToken: String?

    private let authService: AuthService

    init(authService: AuthService = AuthService()) {
        self.authService = authService
        self.sessionToken = KeychainHelper.shared.getToken()
        self.isAuthenticated = sessionToken != nil
    }

    func signIn(identityToken: Data) async throws {
        let session = try await authService.signIn(identityToken: identityToken)
        sessionToken = session.token
        isAuthenticated = true
    }

    func signOut() {
        KeychainHelper.shared.deleteToken()
        sessionToken = nil
        isAuthenticated = false
    }
}
