import Foundation

@Observable
final class RecipeDetailViewModel {
    let recipe: Recipe
    let availableIngredients: [RecipeIngredient]
    let missingIngredients: [RecipeIngredient]

    init(recipe: Recipe, detectedIngredients: [Ingredient]) {
        self.recipe = recipe

        let detectedNames = Set(detectedIngredients.map { $0.name.lowercased() })

        self.availableIngredients = recipe.ingredients.filter { ingredient in
            ingredient.isDetected || detectedNames.contains(ingredient.name.lowercased())
        }
        self.missingIngredients = recipe.ingredients.filter { ingredient in
            !ingredient.isDetected && !detectedNames.contains(ingredient.name.lowercased())
        }
    }
}
