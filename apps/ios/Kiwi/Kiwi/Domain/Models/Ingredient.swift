import Foundation

struct Ingredient: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let category: String?
    let confidence: Double
}
