import Foundation

struct QuotaInfo: Codable {
    let remaining: Int
    let limit: Int
    let resetsAt: Date
}
