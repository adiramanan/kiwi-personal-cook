import Foundation

struct Ingredient: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let name: String
    let category: String?
    let confidence: Double
}
