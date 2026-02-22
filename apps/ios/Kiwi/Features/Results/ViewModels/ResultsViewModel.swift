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
            debugLog("Scan failed with APIError=\(apiError)")
            error = apiError
        } catch {
            debugLogUnexpectedError(error)
            self.error = .unknown
        }

        isLoading = false
    }

    func removeIngredient(_ id: String) {
        ingredients.removeAll { $0.id == id }
    }

    private func debugLogUnexpectedError(_ error: Error) {
#if DEBUG
        let nsError = error as NSError
        print(
            "[ResultsViewModel] Unexpected scan error. " +
            "type=\(String(reflecting: type(of: error))) " +
            "domain=\(nsError.domain) code=\(nsError.code) " +
            "description=\(nsError.localizedDescription)"
        )
#endif
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[ResultsViewModel] \(message)")
#endif
    }
}
