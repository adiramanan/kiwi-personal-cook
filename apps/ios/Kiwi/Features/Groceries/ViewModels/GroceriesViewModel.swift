import SwiftUI

@Observable
final class GroceriesViewModel {
    private static let defaultStorageKey = "com.kiwi.groceries"

    var ingredients: [Ingredient]
    var newItemName: String = ""

    private let userDefaults: UserDefaults
    private let storageKey: String
    private let encoder = JSONEncoder()

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = GroceriesViewModel.defaultStorageKey
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.ingredients = Self.loadIngredients(
            from: userDefaults,
            storageKey: storageKey
        )
    }

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
        persistIngredients()
    }

    func removeItem(_ ingredient: Ingredient) {
        ingredients.removeAll { $0.id == ingredient.id }
        persistIngredients()
    }

    func removeItems(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
        persistIngredients()
    }

    func addDetectedIngredients(_ detected: [Ingredient]) {
        let existingNames = Set(ingredients.map { $0.name.lowercased() })
        let newItems = detected.filter { !existingNames.contains($0.name.lowercased()) }
        ingredients.append(contentsOf: newItems)
        if !newItems.isEmpty {
            persistIngredients()
        }
    }

    private static func loadIngredients(
        from userDefaults: UserDefaults,
        storageKey: String
    ) -> [Ingredient] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode([Ingredient].self, from: data) else {
            return []
        }
        return decoded
    }

    private func persistIngredients() {
        guard let data = try? encoder.encode(ingredients) else {
            return
        }
        userDefaults.set(data, forKey: storageKey)
    }
}
