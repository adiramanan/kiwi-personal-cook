import SwiftUI

@Observable
final class GroceriesViewModel {
    var ingredients: [Ingredient] = []
    var newItemName: String = ""

    func addItem() {
        let name = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let ingredient = Ingredient(
            id: UUID().uuidString,
            name: name,
            category: nil,
            confidence: 1.0
        )
        ingredients.insert(ingredient, at: 0)
        newItemName = ""
    }

    func removeItem(_ ingredient: Ingredient) {
        ingredients.removeAll { $0.id == ingredient.id }
    }

    func removeItems(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }

    func addDetectedIngredients(_ detected: [Ingredient]) {
        let existingNames = Set(ingredients.map { $0.name.lowercased() })
        let newItems = detected.filter { !existingNames.contains($0.name.lowercased()) }
        ingredients.append(contentsOf: newItems)
    }
}
