import Foundation

struct AuthInterceptor {
    func attachAuthHeaders(to request: inout URLRequest) {
        if let token = KeychainHelper.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}
