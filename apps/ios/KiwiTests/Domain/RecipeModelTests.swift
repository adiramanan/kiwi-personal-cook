import XCTest
@testable import Kiwi

final class RecipeModelTests: XCTestCase {

    func testRecipeDecodingFromJSON() throws {
        let json = """
        {
            "id": "recipe-1",
            "name": "Quick Omelette",
            "summary": "A fast protein-rich meal.",
            "cookTimeMinutes": 10,
            "difficulty": "easy",
            "ingredients": [
                {
                    "id": "ing-1",
                    "name": "Eggs",
                    "isDetected": true,
                    "substitution": null
                },
                {
                    "id": "ing-2",
                    "name": "Bell Pepper",
                    "isDetected": false,
                    "substitution": "Use any vegetable"
                }
            ],
            "steps": [
                "Crack eggs into a bowl",
                "Cook in pan"
            ],
            "makeItFasterTip": "Pre-chop veggies the night before"
        }
        """.data(using: .utf8)!

        let recipe = try JSONDecoder().decode(Recipe.self, from: json)

        XCTAssertEqual(recipe.id, "recipe-1")
        XCTAssertEqual(recipe.name, "Quick Omelette")
        XCTAssertEqual(recipe.summary, "A fast protein-rich meal.")
        XCTAssertEqual(recipe.cookTimeMinutes, 10)
        XCTAssertEqual(recipe.difficulty, .easy)
        XCTAssertEqual(recipe.ingredients.count, 2)
        XCTAssertTrue(recipe.ingredients[0].isDetected)
        XCTAssertFalse(recipe.ingredients[1].isDetected)
        XCTAssertEqual(recipe.ingredients[1].substitution, "Use any vegetable")
        XCTAssertEqual(recipe.steps.count, 2)
        XCTAssertEqual(recipe.makeItFasterTip, "Pre-chop veggies the night before")
    }

    func testIngredientDecodingFromJSON() throws {
        let json = """
        {
            "id": "ing-1",
            "name": "Eggs",
            "category": "Protein",
            "confidence": 0.95
        }
        """.data(using: .utf8)!

        let ingredient = try JSONDecoder().decode(Ingredient.self, from: json)

        XCTAssertEqual(ingredient.id, "ing-1")
        XCTAssertEqual(ingredient.name, "Eggs")
        XCTAssertEqual(ingredient.category, "Protein")
        XCTAssertEqual(ingredient.confidence, 0.95, accuracy: 0.001)
    }

    func testScanResponseDecoding() throws {
        let json = """
        {
            "ingredients": [
                {"id": "1", "name": "Eggs", "category": "Protein", "confidence": 0.95}
            ],
            "recipes": [
                {
                    "id": "r1",
                    "name": "Omelette",
                    "summary": "Quick meal",
                    "cookTimeMinutes": 10,
                    "difficulty": "easy",
                    "ingredients": [{"id": "ri1", "name": "Eggs", "isDetected": true, "substitution": null}],
                    "steps": ["Cook"],
                    "makeItFasterTip": null
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ScanResponse.self, from: json)

        XCTAssertEqual(response.ingredients.count, 1)
        XCTAssertEqual(response.recipes.count, 1)
    }

    func testQuotaInfoDecoding() throws {
        let json = """
        {
            "remaining": 3,
            "limit": 4,
            "resetsAt": "2026-02-09T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let quota = try decoder.decode(QuotaInfo.self, from: json)

        XCTAssertEqual(quota.remaining, 3)
        XCTAssertEqual(quota.limit, 4)
    }

    func testRecipeEquatable() {
        let recipe1 = Recipe(
            id: "1", name: "Test", summary: "Summary",
            cookTimeMinutes: 10, difficulty: .easy,
            ingredients: [], steps: ["Step 1"],
            makeItFasterTip: nil
        )

        let recipe2 = Recipe(
            id: "1", name: "Test", summary: "Summary",
            cookTimeMinutes: 10, difficulty: .easy,
            ingredients: [], steps: ["Step 1"],
            makeItFasterTip: nil
        )

        XCTAssertEqual(recipe1, recipe2)
    }
}
