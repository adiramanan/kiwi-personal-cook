import Foundation

final class AuthInterceptor {
    private let keychainHelper: KeychainHelper
    private weak var onUnauthorized: AppState?

    init(keychainHelper: KeychainHelper, appState: AppState? = nil) {
        self.keychainHelper = keychainHelper
        self.onUnauthorized = appState
    }

    func intercept(request: inout URLRequest) {
        if let token = keychainHelper.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    func handleUnauthorized() {
        Task { @MainActor in
            onUnauthorized?.signOut()
        }
    }
}
