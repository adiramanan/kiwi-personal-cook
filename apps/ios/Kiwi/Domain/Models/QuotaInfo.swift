import Foundation

struct QuotaInfo: Codable, Sendable {
    let remaining: Int
    let limit: Int
    let resetsAt: Date
}
