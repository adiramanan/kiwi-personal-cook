import Foundation
import Observation
import UIKit

@Observable
final class ResultsViewModel {
    private let scanUseCase: ScanFridgeUseCase
    private let image: UIImage

    var ingredients: [Ingredient] = []
    var recipes: [Recipe] = []
    var isLoading = false
    var error: AppError?

    init(image: UIImage, scanUseCase: ScanFridgeUseCase = ScanFridgeUseCase()) {
        self.image = image
        self.scanUseCase = scanUseCase
    }

    @MainActor
    func scan() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await scanUseCase.execute(image: image)
            ingredients = response.ingredients
            recipes = response.recipes
        } catch let error as APIError {
            switch error {
            case .rateLimited:
                self.error = .rateLimited(resetsAt: nil)
            case .unauthorized:
                self.error = .unauthorized
            case .networkError:
                self.error = .network
            default:
                self.error = .server(message: nil)
            }
        } catch {
            self.error = .unknown
        }
    }

    func removeIngredient(_ id: String) {
        ingredients.removeAll { $0.id == id }
    }
}
