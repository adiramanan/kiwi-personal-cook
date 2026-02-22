import Foundation

enum APIError: Error, Equatable, Sendable {
    case unauthorized
    case rateLimited(retryAfter: Date?)
    case serverError(statusCode: Int, message: String?)
    case networkError(URLError)
    case imageProcessingInvalid
    case imageProcessingTooLarge
    case imageProcessingCompressionFailed
    case decodingError
    case invalidResponse
    case unknown

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized): true
        case (.rateLimited, .rateLimited): true
        case let (.serverError(l, _), .serverError(r, _)): l == r
        case let (.networkError(l), .networkError(r)): l.code == r.code
        case (.imageProcessingInvalid, .imageProcessingInvalid): true
        case (.imageProcessingTooLarge, .imageProcessingTooLarge): true
        case (.imageProcessingCompressionFailed, .imageProcessingCompressionFailed): true
        case (.decodingError, .decodingError): true
        case (.invalidResponse, .invalidResponse): true
        case (.unknown, .unknown): true
        default: false
        }
    }

    var userMessage: String {
        switch self {
        case .unauthorized:
            "Your session has expired. Please sign in again."
        case .rateLimited:
            "You've used all your scans for today. Come back tomorrow!"
        case .serverError:
            "Something went wrong on our end. Please try again."
        case .networkError:
            "No internet connection. Check your network and try again."
        case .imageProcessingInvalid:
            "We couldn't process this image. Try taking another photo."
        case .imageProcessingTooLarge:
            "This image is too large to scan. Try a smaller or lower-resolution photo."
        case .imageProcessingCompressionFailed:
            "Image processing failed. Please try again with a different photo."
        case .decodingError, .invalidResponse:
            "We got an unexpected response. Please try again."
        case .unknown:
            "Something went wrong. Please try again."
        }
    }
}
