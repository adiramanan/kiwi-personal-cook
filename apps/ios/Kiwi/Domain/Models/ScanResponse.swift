import Foundation

struct ScanResponse: Codable, Sendable {
    let ingredients: [Ingredient]
    let recipes: [Recipe]
}
