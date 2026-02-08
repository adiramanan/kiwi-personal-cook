import Foundation
import Observation

@Observable
final class RecipeDetailViewModel {
    let recipe: Recipe
    private let detectedIngredients: [Ingredient]

    init(recipe: Recipe, detectedIngredients: [Ingredient]) {
        self.recipe = recipe
        self.detectedIngredients = detectedIngredients
    }

    var availableIngredients: [RecipeIngredient] {
        recipe.ingredients.filter { $0.isDetected }
    }

    var missingIngredients: [RecipeIngredient] {
        recipe.ingredients.filter { !$0.isDetected }
    }
}
