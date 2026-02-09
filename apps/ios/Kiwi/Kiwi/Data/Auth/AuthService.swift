import Foundation

struct AuthSession {
    let token: String
    let expiresAt: Date
}

struct AuthService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func signIn(identityToken: Data) async throws -> AuthSession {
        var request = URLRequest(url: Config.baseURL.appendingPathComponent("/v1/auth/apple"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = ["identityToken": identityToken.base64EncodedString()]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.unauthorized
        }
        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
        KeychainHelper.shared.save(token: decoded.sessionToken)
        return AuthSession(token: decoded.sessionToken, expiresAt: decoded.expiresAt)
    }
}

private struct AuthResponse: Decodable {
    let sessionToken: String
    let expiresAt: Date
}
