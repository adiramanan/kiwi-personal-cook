import Foundation

enum APIError: Error, Equatable {
    case unauthorized
    case rateLimited(retryAfter: Date?)
    case serverError(statusCode: Int, message: String?)
    case networkError(URLError)
    case decodingError
    case invalidResponse
    case unknown

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized):
            return true
        case (.rateLimited(let lDate), .rateLimited(let rDate)):
            return lDate == rDate
        case (.serverError(let lCode, let lMsg), .serverError(let rCode, let rMsg)):
            return lCode == rCode && lMsg == rMsg
        case (.networkError(let lErr), .networkError(let rErr)):
            return lErr.code == rErr.code
        case (.decodingError, .decodingError):
            return true
        case (.invalidResponse, .invalidResponse):
            return true
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}

/// User-facing error type that wraps API errors with friendly messages.
enum AppError: Error, Equatable {
    case network
    case server
    case rateLimited
    case unauthorized
    case invalidData
    case unknown

    var title: String {
        switch self {
        case .network:
            return "No Connection"
        case .server:
            return "Something Went Wrong"
        case .rateLimited:
            return "Daily Limit Reached"
        case .unauthorized:
            return "Session Expired"
        case .invalidData:
            return "Something Went Wrong"
        case .unknown:
            return "Something Went Wrong"
        }
    }

    var message: String {
        switch self {
        case .network:
            return "Please check your internet connection and try again."
        case .server:
            return "We're having trouble right now. Please try again in a moment."
        case .rateLimited:
            return "You've used all your scans for today. Come back tomorrow!"
        case .unauthorized:
            return "Please sign in again to continue."
        case .invalidData:
            return "We received unexpected data. Please try again."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .network, .server, .invalidData, .unknown:
            return true
        case .rateLimited, .unauthorized:
            return false
        }
    }

    static func from(_ apiError: APIError) -> AppError {
        switch apiError {
        case .unauthorized:
            return .unauthorized
        case .rateLimited:
            return .rateLimited
        case .serverError:
            return .server
        case .networkError:
            return .network
        case .decodingError, .invalidResponse:
            return .invalidData
        case .unknown:
            return .unknown
        }
    }
}
