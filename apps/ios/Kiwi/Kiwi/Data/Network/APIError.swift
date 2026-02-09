import Foundation

enum APIError: Error, Equatable {
    case unauthorized
    case rateLimited(retryAfter: Date?)
    case serverError(statusCode: Int, message: String?)
    case networkError(URLError)
    case decodingError
    case invalidResponse
    case unknown
}
