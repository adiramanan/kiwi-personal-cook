import Foundation

enum Endpoint {
    case scan
    case quota
    case deleteAccount

    var path: String {
        switch self {
        case .scan:
            return "/v1/scan"
        case .quota:
            return "/v1/quota"
        case .deleteAccount:
            return "/v1/account"
        }
    }

    var method: String {
        switch self {
        case .scan:
            return "POST"
        case .quota:
            return "GET"
        case .deleteAccount:
            return "DELETE"
        }
    }
}
