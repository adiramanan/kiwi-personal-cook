import Foundation
import Observation

@Observable
final class RecipeDetailViewModel {
    let recipe: Recipe

    init(recipe: Recipe) {
        self.recipe = recipe
    }

    var availableIngredients: [RecipeIngredient] {
        recipe.ingredients.filter { $0.isDetected }
    }

    var missingIngredients: [RecipeIngredient] {
        recipe.ingredients.filter { !$0.isDetected }
    }
}
