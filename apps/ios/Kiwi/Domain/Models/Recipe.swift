import Foundation

struct Recipe: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let summary: String
    let cookTimeMinutes: Int
    let difficulty: Difficulty
    let ingredients: [RecipeIngredient]
    let steps: [String]
    let makeItFasterTip: String?

    enum Difficulty: String, Codable, Hashable, Sendable {
        case easy, medium
    }
}

struct RecipeIngredient: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let isDetected: Bool
    let substitution: String?
}
