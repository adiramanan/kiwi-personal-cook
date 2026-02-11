import XCTest
import UIKit
@testable import Kiwi

@MainActor
final class ResultsViewModelTests: XCTestCase {
    nonisolated private static func sampleResponse() -> ScanResponse {
        ScanResponse(
            ingredients: [
                Ingredient(id: "1", name: "Eggs", category: "Protein", confidence: 0.9),
                Ingredient(id: "2", name: "Milk", category: "Dairy", confidence: 0.8)
            ],
            recipes: [
                Recipe(
                    id: "r1",
                    name: "Omelette",
                    summary: "Fast",
                    cookTimeMinutes: 10,
                    difficulty: .easy,
                    ingredients: [
                        RecipeIngredient(id: "ri1", name: "Eggs", isDetected: true, substitution: nil)
                    ],
                    steps: ["Cook"],
                    makeItFasterTip: "Use pre-cut veggies"
                )
            ]
        )
    }

    func testScanPopulatesIngredientsAndRecipes() async {
        let useCase = ScanFridgeUseCase(executeImpl: { _ in
            Self.sampleResponse()
        })

        let viewModel = ResultsViewModel(image: UIImage(systemName: "leaf")!, scanUseCase: useCase)
        await viewModel.scan()

        XCTAssertEqual(viewModel.ingredients.count, 2)
        XCTAssertEqual(viewModel.recipes.count, 1)
        XCTAssertNil(viewModel.error)
    }

    func testScanRateLimitedSetsError() async {
        let useCase = ScanFridgeUseCase(executeImpl: { _ in
            throw APIError.rateLimited(retryAfter: Date())
        })

        let viewModel = ResultsViewModel(image: UIImage(systemName: "leaf")!, scanUseCase: useCase)
        await viewModel.scan()

        if case .rateLimited = viewModel.error {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected rate limited error")
        }
    }

    func testRemoveIngredientRemovesById() {
        let useCase = ScanFridgeUseCase(executeImpl: { _ in Self.sampleResponse() })
        let viewModel = ResultsViewModel(image: UIImage(systemName: "leaf")!, scanUseCase: useCase)

        viewModel.ingredients = Self.sampleResponse().ingredients
        viewModel.removeIngredient("1")

        XCTAssertEqual(viewModel.ingredients.count, 1)
        XCTAssertEqual(viewModel.ingredients.first?.id, "2")
    }
}
