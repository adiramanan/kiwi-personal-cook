import UIKit

@Observable
final class ResultsViewModel {
    var ingredients: [Ingredient] = []
    var recipes: [Recipe] = []
    var isLoading: Bool = false
    var error: APIError?

    private let image: UIImage
    private let scanUseCase: ScanFridgeUseCase

    init(image: UIImage, scanUseCase: ScanFridgeUseCase = .init()) {
        self.image = image
        self.scanUseCase = scanUseCase
    }

    func scan() async {
        isLoading = true
        error = nil

        do {
            let response = try await scanUseCase.execute(image: image)
            ingredients = response.ingredients
            recipes = response.recipes
        } catch let apiError as APIError {
            error = apiError
        } catch {
            self.error = .unknown
        }

        isLoading = false
    }

    func removeIngredient(_ id: String) {
        ingredients.removeAll { $0.id == id }
    }
}
