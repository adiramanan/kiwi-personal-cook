import Foundation

enum AppError: Error, Equatable {
    case network
    case server(message: String?)
    case rateLimited(resetsAt: Date?)
    case invalidResponse
    case unauthorized
    case unknown

    var message: String {
        switch self {
        case .network:
            return "We couldn't connect. Please check your internet connection."
        case .server:
            return "Something went wrong on our end. Please try again."
        case .rateLimited:
            return "You've used all your scans for today. Come back tomorrow!"
        case .invalidResponse:
            return "We couldn't read the results. Please try again."
        case .unauthorized:
            return "Please sign in again to continue."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
