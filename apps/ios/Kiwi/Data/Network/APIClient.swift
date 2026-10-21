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
        urlRequest.timeoutInterval = 90
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        AuthInterceptor.apply(to: &urlRequest)

        return try await perform(urlRequest)
    }

    /// Fire-and-forget request that only checks for a success status code.
    func requestVoid(_ endpoint: Endpoint) async throws {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        urlRequest.httpMethod = endpoint.method
        urlRequest.timeoutInterval = 90
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        AuthInterceptor.apply(to: &urlRequest)
        debugLog("Request start \(endpoint.method) \(urlRequest.url?.absoluteString ?? "<nil>")")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let error as URLError {
            debugLog("Transport error for requestVoid. code=\(error.code.rawValue) description=\(error.localizedDescription)")
            throw APIError.networkError(error)
        } catch {
            debugLogUnexpectedError(stage: "Unexpected transport failure in requestVoid", error: error)
            throw APIError.unknown
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            debugLog("Invalid response type for requestVoid.")
            throw APIError.invalidResponse
        }
        debugLog("Request finished status=\(httpResponse.statusCode) path=\(urlRequest.url?.path ?? "<nil>")")

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
            debugLog(
                "Server error status=\(httpResponse.statusCode) " +
                "message=\(message ?? "<none>") bodyPreview=\(debugBodySnippet(data))"
            )
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    func upload<T: Decodable>(_ endpoint: Endpoint, imageData: Data) async throws -> T {
        let boundary = UUID().uuidString
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        urlRequest.httpMethod = endpoint.method
        urlRequest.timeoutInterval = 90
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        AuthInterceptor.apply(to: &urlRequest)

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"fridge.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body
        debugLog(
            "Upload prepared method=\(endpoint.method) " +
            "url=\(urlRequest.url?.absoluteString ?? "<nil>") bytes=\(imageData.count)"
        )

        return try await perform(urlRequest)
    }

    func send<T: Decodable, Body: Encodable>(_ endpoint: Endpoint, body: Body) async throws -> T {
        try await sendData(endpoint, body: JSONEncoder().encode(body))
    }

    func sendData<T: Decodable>(_ endpoint: Endpoint, body: Data) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 90
        AuthInterceptor.apply(to: &request)
        return try await perform(request)
    }

    func uploadImages<T: Decodable>(_ images: [Data]) async throws -> T {
        let boundary = UUID().uuidString
        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/kitchen/recognize"))
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        AuthInterceptor.apply(to: &request)
        var body = Data()
        for (index, data) in images.enumerated() {
            body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"images\"; filename=\"fridge-\(index).jpg\"\r\nContent-Type: image/jpeg\r\n\r\n".utf8))
            body.append(data)
            body.append(Data("\r\n".utf8))
        }
        body.append(Data("--\(boundary)--\r\n".utf8))
        request.httpBody = body
        return try await perform(request)
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        debugLog("Request start \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "<nil>")")
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            debugLog("Transport error. code=\(error.code.rawValue) description=\(error.localizedDescription)")
            throw APIError.networkError(error)
        } catch {
            debugLogUnexpectedError(stage: "Unexpected transport failure", error: error)
            throw APIError.unknown
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            debugLog("Invalid response type.")
            throw APIError.invalidResponse
        }
        debugLog("Request finished status=\(httpResponse.statusCode) path=\(request.url?.path ?? "<nil>")")

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                debugLog(
                    "Decoding failed for status=\(httpResponse.statusCode) " +
                    "bodyPreview=\(debugBodySnippet(data))"
                )
                throw APIError.decodingError
            }
        case 401:
            throw APIError.unauthorized
        case 429:
            let retryDate = parseRetryAfter(from: httpResponse)
            throw APIError.rateLimited(retryAfter: retryDate)
        default:
            let message = try? decoder.decode(ErrorBody.self, from: data).message
            debugLog(
                "Server error status=\(httpResponse.statusCode) " +
                "message=\(message ?? "<none>") bodyPreview=\(debugBodySnippet(data))"
            )
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    private func parseRetryAfter(from response: HTTPURLResponse) -> Date? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After"),
              let seconds = TimeInterval(value) else { return nil }
        return Date().addingTimeInterval(seconds)
    }

    private func debugBodySnippet(_ data: Data) -> String { "<redacted>" }

    private func debugLogUnexpectedError(stage: String, error: Error) {
#if DEBUG
        let nsError = error as NSError
        print(
            "[APIClient] \(stage). " +
            "type=\(String(reflecting: type(of: error))) " +
            "domain=\(nsError.domain) code=\(nsError.code) " +
            "description=\(nsError.localizedDescription)"
        )
#endif
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[APIClient] \(message)")
#endif
    }
}

private struct ErrorBody: Codable {
    let error: String?
    let message: String?
}

enum Config {
    private enum APIBaseURLSource {
        case infoPlist
        case debugFallback
        case releaseFallback
    }

    private static let resolvedBaseURL: (url: URL, source: APIBaseURLSource) = {
        if let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            return (url, .infoPlist)
        }
        #if DEBUG
        return (URL(string: "http://MacBook-Air.local:3000")!, .debugFallback)
        #else
        return (URL(string: "https://kiwi-personal-cook-production.up.railway.app")!, .releaseFallback)
        #endif
    }()

    static let apiBaseURL: URL = resolvedBaseURL.url

    static func logResolvedBaseURLIfNeeded() {
#if DEBUG
        switch resolvedBaseURL.source {
        case .infoPlist:
            print("[Config] API_BASE_URL resolved from Info.plist: \(resolvedBaseURL.url.absoluteString)")
        case .debugFallback:
            print(
                "[Config][Warning] API_BASE_URL missing/invalid in Info.plist. " +
                "Using fallback: \(resolvedBaseURL.url.absoluteString)"
            )
        case .releaseFallback:
            print("[Config][Warning] API_BASE_URL fallback active in non-debug build.")
        }
#endif
    }
}
