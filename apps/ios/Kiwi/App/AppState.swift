import Foundation
import Observation

@Observable
final class AppState {
    var isAuthenticated: Bool = false
    var sessionToken: String?

    private let keychainHelper: KeychainHelper

    init(keychainHelper: KeychainHelper = KeychainHelper()) {
        self.keychainHelper = keychainHelper
        checkExistingSession()
    }

    func signIn(identityToken: Data) async throws {
        let authService = AuthService(
            apiClient: AppDependencies.shared.apiClient,
            keychainHelper: keychainHelper
        )

        let token = try await authService.signIn(identityToken: identityToken)

        await MainActor.run {
            self.sessionToken = token
            self.isAuthenticated = true
        }
    }

    func signOut() {
        keychainHelper.deleteToken()
        sessionToken = nil
        isAuthenticated = false
    }

    private func checkExistingSession() {
        if let token = keychainHelper.getToken() {
            sessionToken = token
            isAuthenticated = true
        }
    }
}

/// Centralized dependency container for the app.
final class AppDependencies {
    static let shared = AppDependencies()

    let keychainHelper: KeychainHelper
    let authInterceptor: AuthInterceptor
    let apiClient: APIClient
    let rateLimiter: ClientRateLimiter

    private init() {
        keychainHelper = KeychainHelper()
        authInterceptor = AuthInterceptor(keychainHelper: keychainHelper)

        // Load base URL from config; fallback to placeholder
        let baseURLString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
            ?? "https://api.kiwi.example.com"
        let baseURL = URL(string: baseURLString)!

        apiClient = APIClient(baseURL: baseURL, authInterceptor: authInterceptor)
        rateLimiter = ClientRateLimiter()
    }
}
