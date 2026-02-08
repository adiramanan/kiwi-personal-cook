import Foundation

struct Recipe: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let summary: String
    let cookTimeMinutes: Int
    let difficulty: Difficulty
    let ingredients: [RecipeIngredient]
    let steps: [String]
    let makeItFasterTip: String?

    enum Difficulty: String, Codable {
        case easy, medium
    }
}

struct RecipeIngredient: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let isDetected: Bool             // true if found in fridge
    let substitution: String?        // suggestion if missing
}
