import XCTest
@testable import Kiwi

final class ResultsViewModelTests: XCTestCase {

    func testInitialState() {
        let image = createTestImage()
        let keychainHelper = KeychainHelper()
        let interceptor = AuthInterceptor(keychainHelper: keychainHelper)
        let client = APIClient(
            baseURL: URL(string: "https://test.example.com")!,
            authInterceptor: interceptor
        )

        let viewModel = ResultsViewModel(
            image: image,
            scanFridgeUseCase: ScanFridgeUseCase(apiClient: client)
        )

        XCTAssertTrue(viewModel.ingredients.isEmpty)
        XCTAssertTrue(viewModel.recipes.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testRemoveIngredient() {
        let image = createTestImage()
        let keychainHelper = KeychainHelper()
        let interceptor = AuthInterceptor(keychainHelper: keychainHelper)
        let client = APIClient(
            baseURL: URL(string: "https://test.example.com")!,
            authInterceptor: interceptor
        )

        let viewModel = ResultsViewModel(
            image: image,
            scanFridgeUseCase: ScanFridgeUseCase(apiClient: client)
        )

        // Manually set ingredients to test removal
        viewModel.ingredients = [
            Ingredient(id: "1", name: "Eggs", category: "Protein", confidence: 0.95),
            Ingredient(id: "2", name: "Milk", category: "Dairy", confidence: 0.88),
        ]

        viewModel.removeIngredient("1")

        XCTAssertEqual(viewModel.ingredients.count, 1)
        XCTAssertEqual(viewModel.ingredients[0].name, "Milk")
    }

    func testRemoveIngredientWithInvalidIdDoesNothing() {
        let image = createTestImage()
        let keychainHelper = KeychainHelper()
        let interceptor = AuthInterceptor(keychainHelper: keychainHelper)
        let client = APIClient(
            baseURL: URL(string: "https://test.example.com")!,
            authInterceptor: interceptor
        )

        let viewModel = ResultsViewModel(
            image: image,
            scanFridgeUseCase: ScanFridgeUseCase(apiClient: client)
        )

        viewModel.ingredients = [
            Ingredient(id: "1", name: "Eggs", category: "Protein", confidence: 0.95),
        ]

        viewModel.removeIngredient("nonexistent")

        XCTAssertEqual(viewModel.ingredients.count, 1)
    }

    // MARK: - Helpers

    private func createTestImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 50, height: 50))
        return renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))
        }
    }
}
