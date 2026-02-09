import XCTest
@testable import Kiwi

final class RecipeModelTests: XCTestCase {
    func testRecipeEquatable() {
        let ingredient = RecipeIngredient(id: "1", name: "Eggs", isDetected: true, substitution: nil)
        let recipe = Recipe(
            id: "1",
            name: "Omelette",
            summary: "Quick and easy",
            cookTimeMinutes: 10,
            difficulty: .easy,
            ingredients: [ingredient],
            steps: ["Whisk eggs"],
            makeItFasterTip: nil
        )
        XCTAssertEqual(recipe, recipe)
    }
}
