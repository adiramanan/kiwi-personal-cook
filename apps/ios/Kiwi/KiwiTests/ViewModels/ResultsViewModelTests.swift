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
        let payload = try! JSONEncoder().encode(Self.sampleResponse())
        let session = makeTestSession { request in
            XCTAssertEqual(request.httpMethod, "POST")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, payload)
        }
        let useCase = ScanFridgeUseCase(apiClient: APIClient(session: session))

        let viewModel = ResultsViewModel(image: UIImage(systemName: "leaf")!, scanUseCase: useCase)
        await viewModel.scan()

        XCTAssertEqual(viewModel.ingredients.count, 2)
        XCTAssertEqual(viewModel.recipes.count, 1)
        XCTAssertNil(viewModel.error)
    }

    func testScanRateLimitedSetsError() async {
        let session = makeTestSession { request in
            XCTAssertEqual(request.httpMethod, "POST")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: ["Retry-After": "60"]
            )!
            return (response, Data())
        }
        let useCase = ScanFridgeUseCase(apiClient: APIClient(session: session))

        let viewModel = ResultsViewModel(image: UIImage(systemName: "leaf")!, scanUseCase: useCase)
        await viewModel.scan()

        if case .rateLimited = viewModel.error {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected rate limited error")
        }
    }

    func testRemoveIngredientRemovesById() {
        let payload = try! JSONEncoder().encode(Self.sampleResponse())
        let session = makeTestSession { request in
            XCTAssertEqual(request.httpMethod, "POST")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, payload)
        }
        let useCase = ScanFridgeUseCase(apiClient: APIClient(session: session))
        let viewModel = ResultsViewModel(image: UIImage(systemName: "leaf")!, scanUseCase: useCase)

        viewModel.ingredients = Self.sampleResponse().ingredients
        viewModel.removeIngredient("1")

        XCTAssertEqual(viewModel.ingredients.count, 1)
        XCTAssertEqual(viewModel.ingredients.first?.id, "2")
    }
}
