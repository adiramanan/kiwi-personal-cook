import Foundation

struct Config {
    static let baseURL: URL = {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        return URL(string: urlString ?? "https://api.kiwi.example.com")!
    }()
}
