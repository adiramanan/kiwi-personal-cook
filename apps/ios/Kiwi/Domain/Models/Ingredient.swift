import Foundation

struct Ingredient: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let category: String?       // e.g., "Dairy", "Vegetable", "Protein"
    let confidence: Double       // 0.0–1.0 from the LLM
}
