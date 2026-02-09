import Foundation

struct ScanResponse: Codable {
    let ingredients: [Ingredient]
    let recipes: [Recipe]
}
