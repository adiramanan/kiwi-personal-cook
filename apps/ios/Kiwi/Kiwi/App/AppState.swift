import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var isAuthenticated: Bool = false
    var sessionToken: String?

    private let authService: AuthService

    init(authService: AuthService = AuthService()) {
        self.authService = authService
        if ProcessInfo.processInfo.arguments.contains("UITEST_AUTHENTICATED") {
            self.sessionToken = "ui-test-token"
            self.isAuthenticated = true
        } else {
            self.sessionToken = KeychainHelper.shared.getToken()
            self.isAuthenticated = sessionToken != nil
        }
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
