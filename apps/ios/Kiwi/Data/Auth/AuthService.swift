import AuthenticationServices
import Foundation

struct AuthResponse: Codable {
    let sessionToken: String
    let expiresAt: String
}

struct AuthRequestBody: Codable {
    let identityToken: String
}

final class AuthService {
    private let apiClient: APIClient
    private let keychainHelper: KeychainHelper

    init(apiClient: APIClient, keychainHelper: KeychainHelper) {
        self.apiClient = apiClient
        self.keychainHelper = keychainHelper
    }

    func signIn(identityToken: Data) async throws -> String {
        let tokenString = identityToken.base64EncodedString()
        let body = AuthRequestBody(identityToken: tokenString)

        let response: AuthResponse = try await apiClient.requestWithBody(.authApple, body: body)

        // Store the session token securely
        keychainHelper.save(token: response.sessionToken)

        return response.sessionToken
    }

    func signOut() {
        keychainHelper.deleteToken()
    }

    func hasExistingSession() -> Bool {
        return keychainHelper.getToken() != nil
    }
}
