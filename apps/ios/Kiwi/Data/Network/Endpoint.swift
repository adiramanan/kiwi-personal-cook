import Foundation

enum Endpoint: Sendable {
    case scan
    case quota
    case deleteAccount
    case authApple
    case kitchen(String, String)

    var path: String {
        switch self {
        case .scan: "/v1/scan"
        case .quota: "/v1/quota"
        case .deleteAccount: "/v1/account"
        case .authApple: "/v1/auth/apple"
        case .kitchen(let resource, _): "/v1/kitchen/\(resource)"
        }
    }

    var method: String {
        switch self {
        case .scan: "POST"
        case .quota: "GET"
        case .deleteAccount: "DELETE"
        case .authApple: "POST"
        case .kitchen(_, let method): method
        }
    }
}
