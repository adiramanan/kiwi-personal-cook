import Foundation

struct APIClient {
    private let session: URLSession
    private let interceptor: AuthInterceptor

    init(session: URLSession = .shared, interceptor: AuthInterceptor = AuthInterceptor()) {
        self.session = session
        self.interceptor = interceptor
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var request = URLRequest(url: Config.baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = endpoint.method
        interceptor.attachAuthHeaders(to: &request)
        return try await perform(request: request)
    }

    func upload<T: Decodable>(_ endpoint: Endpoint, imageData: Data) async throws -> T {
        var request = URLRequest(url: Config.baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = endpoint.method
        interceptor.attachAuthHeaders(to: &request)
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildMultipartBody(boundary: boundary, imageData: imageData)
        return try await perform(request: request)
    }

    private func perform<T: Decodable>(request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError
                }
            case 401:
                throw APIError.unauthorized
            case 429:
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap { Double($0) }
                throw APIError.rateLimited(retryAfter: retryAfter.map { Date().addingTimeInterval($0) })
            case 500...599:
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: nil)
            default:
                throw APIError.unknown
            }
        } catch let error as URLError {
            throw APIError.networkError(error)
        }
    }

    private func buildMultipartBody(boundary: String, imageData: Data) -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"fridge.jpg\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(imageData)
        body.append(lineBreak.data(using: .utf8)!)
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
        return body
    }
}
