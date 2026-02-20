import Foundation

final class APIClient: Sendable {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: URL = Config.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        urlRequest.httpMethod = endpoint.method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        AuthInterceptor.apply(to: &urlRequest)

        return try await perform(urlRequest)
    }

    /// Fire-and-forget request that only checks for a success status code.
    func requestVoid(_ endpoint: Endpoint) async throws {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        urlRequest.httpMethod = endpoint.method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        AuthInterceptor.apply(to: &urlRequest)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: urlRequest)
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
            return
        case 401:
            throw APIError.unauthorized
        case 429:
            let retryDate = parseRetryAfter(from: httpResponse)
            throw APIError.rateLimited(retryAfter: retryDate)
        default:
            let message = try? decoder.decode(ErrorBody.self, from: data).message
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    func upload<T: Decodable>(_ endpoint: Endpoint, imageData: Data) async throws -> T {
        let boundary = UUID().uuidString
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        urlRequest.httpMethod = endpoint.method
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        AuthInterceptor.apply(to: &urlRequest)

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"fridge.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

        return try await perform(urlRequest)
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
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
            throw APIError.unauthorized
        case 429:
            let retryDate = parseRetryAfter(from: httpResponse)
            throw APIError.rateLimited(retryAfter: retryDate)
        default:
            let message = try? decoder.decode(ErrorBody.self, from: data).message
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    private func parseRetryAfter(from response: HTTPURLResponse) -> Date? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After"),
              let seconds = TimeInterval(value) else { return nil }
        return Date().addingTimeInterval(seconds)
    }
}

private struct ErrorBody: Codable {
    let error: String?
    let message: String?
}

enum Config {
    static let apiBaseURL: URL = {
        if let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           let url = URL(string: urlString) {
            return url
        }
        return URL(string: "https://api.kiwi.example.com")!
    }()
}
