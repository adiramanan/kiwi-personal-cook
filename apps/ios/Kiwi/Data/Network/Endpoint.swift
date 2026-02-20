import Foundation

enum Endpoint: Sendable {
    case scan
    case quota
    case deleteAccount
    case authApple

    var path: String {
        switch self {
        case .scan: "/v1/scan"
        case .quota: "/v1/quota"
        case .deleteAccount: "/v1/account"
        case .authApple: "/v1/auth/apple"
        }
    }

    var method: String {
        switch self {
        case .scan: "POST"
        case .quota: "GET"
        case .deleteAccount: "DELETE"
        case .authApple: "POST"
        }
    }
}
