import Foundation

enum AuthInterceptor {
    static func apply(to request: inout URLRequest) {
        if let token = KeychainHelper.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}
