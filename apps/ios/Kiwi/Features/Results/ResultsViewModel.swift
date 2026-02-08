import SwiftUI
import Observation

@Observable
final class ResultsViewModel {
    var ingredients: [Ingredient] = []
    var recipes: [Recipe] = []
    var isLoading: Bool = false
    var error: AppError?

    private let image: UIImage
    private let scanFridgeUseCase: ScanFridgeUseCase

    init(image: UIImage, scanFridgeUseCase: ScanFridgeUseCase) {
        self.image = image
        self.scanFridgeUseCase = scanFridgeUseCase
    }

    func scan() async {
        isLoading = true
        error = nil

        do {
            let response = try await scanFridgeUseCase.execute(image: image)
            ingredients = response.ingredients
            recipes = response.recipes
        } catch let apiError as APIError {
            error = AppError.from(apiError)
        } catch {
            self.error = .unknown
        }

        isLoading = false
    }

    func removeIngredient(_ id: String) {
        ingredients.removeAll { $0.id == id }
    }
}
