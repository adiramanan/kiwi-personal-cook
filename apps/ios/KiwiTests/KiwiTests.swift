import Testing
@testable import Kiwi
import Foundation

// MARK: - Domain Model Tests

@Suite("Ingredient Model")
struct IngredientTests {
    @Test func decodesFromJSON() throws {
        let json = """
        {"id":"abc-123","name":"Eggs","category":"Protein","confidence":0.95}
        """.data(using: .utf8)!

        let ingredient = try JSONDecoder().decode(Ingredient.self, from: json)
        #expect(ingredient.id == "abc-123")
        #expect(ingredient.name == "Eggs")
        #expect(ingredient.category == "Protein")
        #expect(ingredient.confidence == 0.95)
    }

    @Test func decodesWithNullCategory() throws {
        let json = """
        {"id":"abc-123","name":"Mystery Item","category":null,"confidence":0.5}
        """.data(using: .utf8)!

        let ingredient = try JSONDecoder().decode(Ingredient.self, from: json)
        #expect(ingredient.category == nil)
    }
}

@Suite("Recipe Model")
struct RecipeTests {
    @Test func decodesFullRecipe() throws {
        let json = """
        {
          "id": "recipe-1",
          "name": "Quick Omelette",
          "summary": "Fast and easy",
          "cookTimeMinutes": 10,
          "difficulty": "easy",
          "ingredients": [
            {"id": "i1", "name": "Eggs", "isDetected": true, "substitution": null}
          ],
          "steps": ["Crack eggs", "Cook"],
          "makeItFasterTip": "Microwave it"
        }
        """.data(using: .utf8)!

        let recipe = try JSONDecoder().decode(Recipe.self, from: json)
        #expect(recipe.name == "Quick Omelette")
        #expect(recipe.difficulty == .easy)
        #expect(recipe.ingredients.count == 1)
        #expect(recipe.steps.count == 2)
        #expect(recipe.makeItFasterTip == "Microwave it")
    }

    @Test func decodesWithNullTip() throws {
        let json = """
        {
          "id": "recipe-2",
          "name": "Salad",
          "summary": "Fresh salad",
          "cookTimeMinutes": 5,
          "difficulty": "easy",
          "ingredients": [
            {"id": "i1", "name": "Lettuce", "isDetected": true, "substitution": null}
          ],
          "steps": ["Wash", "Serve"],
          "makeItFasterTip": null
        }
        """.data(using: .utf8)!

        let recipe = try JSONDecoder().decode(Recipe.self, from: json)
        #expect(recipe.makeItFasterTip == nil)
    }
}

@Suite("ScanResponse Model")
struct ScanResponseTests {
    @Test func decodesFullResponse() throws {
        let json = """
        {
          "ingredients": [
            {"id": "i1", "name": "Milk", "category": "Dairy", "confidence": 0.9}
          ],
          "recipes": [
            {
              "id": "r1",
              "name": "Smoothie",
              "summary": "Quick smoothie",
              "cookTimeMinutes": 3,
              "difficulty": "easy",
              "ingredients": [
                {"id": "ri1", "name": "Milk", "isDetected": true, "substitution": null}
              ],
              "steps": ["Blend"],
              "makeItFasterTip": null
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ScanResponse.self, from: json)
        #expect(response.ingredients.count == 1)
        #expect(response.recipes.count == 1)
    }
}

@Suite("QuotaInfo Model")
struct QuotaInfoTests {
    @Test func decodesWithISO8601Date() throws {
        let json = """
        {"remaining":3,"limit":4,"resetsAt":"2026-02-21T00:00:00Z"}
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let quota = try decoder.decode(QuotaInfo.self, from: json)
        #expect(quota.remaining == 3)
        #expect(quota.limit == 4)
    }
}

// MARK: - ClientRateLimiter Tests

@Suite("ClientRateLimiter")
struct ClientRateLimiterTests {
    @Test func startsWithFullQuota() {
        UserDefaults.standard.removeObject(forKey: "com.kiwi.scanTimestamps")
        let limiter = ClientRateLimiter()
        #expect(limiter.canScan() == true)
        #expect(limiter.remaining() == 4)
    }

    @Test func decreasesAfterRecording() {
        UserDefaults.standard.removeObject(forKey: "com.kiwi.scanTimestamps")
        let limiter = ClientRateLimiter()
        limiter.recordScan()
        #expect(limiter.remaining() == 3)
    }

    @Test func blocksAfterFourScans() {
        UserDefaults.standard.removeObject(forKey: "com.kiwi.scanTimestamps")
        let limiter = ClientRateLimiter()
        for _ in 0..<4 { limiter.recordScan() }
        #expect(limiter.canScan() == false)
        #expect(limiter.remaining() == 0)
    }
}

// MARK: - ViewModel Tests

@Suite("ResultsViewModel")
struct ResultsViewModelTests {
    @Test func removeIngredientFromList() {
        let vm = ResultsViewModel(image: UIImage())
        vm.ingredients = [
            Ingredient(id: "1", name: "Eggs", category: "Protein", confidence: 0.9),
            Ingredient(id: "2", name: "Milk", category: "Dairy", confidence: 0.8),
        ]

        vm.removeIngredient("1")
        #expect(vm.ingredients.count == 1)
        #expect(vm.ingredients[0].name == "Milk")
    }
}

@Suite("RecipeDetailViewModel")
struct RecipeDetailViewModelTests {
    @Test func splitsAvailableAndMissing() {
        let recipe = Recipe(
            id: "r1",
            name: "Test",
            summary: "Test recipe",
            cookTimeMinutes: 10,
            difficulty: .easy,
            ingredients: [
                RecipeIngredient(id: "1", name: "Eggs", isDetected: true, substitution: nil),
                RecipeIngredient(id: "2", name: "Butter", isDetected: false, substitution: "Use oil"),
            ],
            steps: ["Cook"],
            makeItFasterTip: nil
        )

        let detected = [Ingredient(id: "i1", name: "Eggs", category: "Protein", confidence: 0.9)]
        let vm = RecipeDetailViewModel(recipe: recipe, detectedIngredients: detected)

        #expect(vm.availableIngredients.count == 1)
        #expect(vm.missingIngredients.count == 1)
        #expect(vm.missingIngredients[0].substitution == "Use oil")
    }
}

@Suite("GroceriesViewModel")
struct GroceriesViewModelTests {
    @Test func addsAndRemovesItems() {
        let vm = GroceriesViewModel()
        vm.newItemName = "Carrots"
        vm.addItem()
        #expect(vm.ingredients.count == 1)
        #expect(vm.ingredients[0].name == "Carrots")

        vm.removeItem(vm.ingredients[0])
        #expect(vm.ingredients.isEmpty)
    }

    @Test func ignoresEmptyInput() {
        let vm = GroceriesViewModel()
        vm.newItemName = "   "
        vm.addItem()
        #expect(vm.ingredients.isEmpty)
    }

    @Test func addDetectedIngredientsDeduplicated() {
        let vm = GroceriesViewModel()
        vm.newItemName = "Eggs"
        vm.addItem()

        let detected = [
            Ingredient(id: "1", name: "Eggs", category: "Protein", confidence: 0.9),
            Ingredient(id: "2", name: "Milk", category: "Dairy", confidence: 0.8),
        ]
        vm.addDetectedIngredients(detected)

        #expect(vm.ingredients.count == 2)
    }
}
