import Foundation

struct AuthSession: Codable, Sendable {
    let sessionToken: String
    let expiresAt: String
}

struct AuthService: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func authenticate(identityToken: Data) async throws -> AuthSession {
        guard let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw APIError.invalidResponse
        }
        let body = AuthRequest(identityToken: tokenString)

        var request = URLRequest(url: Config.apiBaseURL.appendingPathComponent(Endpoint.authApple.path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.unauthorized
        }

        let decoder = JSONDecoder()
        return try decoder.decode(AuthSession.self, from: data)
    }
}

private struct AuthRequest: Codable {
    let identityToken: String
}
