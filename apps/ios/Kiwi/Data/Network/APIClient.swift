import Foundation

final class APIClient {
    private let baseURL: URL
    private let authInterceptor: AuthInterceptor
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: URL, authInterceptor: AuthInterceptor, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.authInterceptor = authInterceptor
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        authInterceptor.intercept(request: &request)

        return try await perform(request: request)
    }

    func upload<T: Decodable>(_ endpoint: Endpoint, imageData: Data) async throws -> T {
        let boundary = UUID().uuidString
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = endpoint.method
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        authInterceptor.intercept(request: &request)

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"fridge.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        return try await perform(request: request)
    }

    func requestWithBody<T: Decodable, B: Encodable>(_ endpoint: Endpoint, body: B) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        // Don't add auth for auth endpoints
        if endpoint.path != Endpoint.authApple.path {
            authInterceptor.intercept(request: &request)
        }

        return try await perform(request: request)
    }

    // MARK: - Private

    private func perform<T: Decodable>(request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw APIError.networkError(error)
        } catch {
            throw APIError.unknown
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError
            }

        case 401:
            authInterceptor.handleUnauthorized()
            throw APIError.unauthorized

        case 429:
            let retryAfterString = httpResponse.value(forHTTPHeaderField: "Retry-After")
            let retryAfter = retryAfterString.flatMap { ISO8601DateFormatter().date(from: $0) }
            throw APIError.rateLimited(retryAfter: retryAfter)

        default:
            let message = try? JSONDecoder().decode([String: String].self, from: data)["message"]
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}
