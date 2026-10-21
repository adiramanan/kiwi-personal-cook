#if DEBUG
import Foundation

/// Deterministic, network-free fixtures used only by previews and UI tests.
@MainActor final class KitchenFixtureService: KitchenServing {
    var accountIdentifier = "ui-test-account"
    var generationError: APIError?
    var inventoryError: APIError?
    var items = ["egg", "spinach", "rice", "olive oil", "salt"].map { FridgeItem(name: $0) }
    var family: [FamilyMember] = {
        var maya = FamilyMember(); maya.name = "Maya"; maya.diet = "vegetarian"; maya.goal = "muscleGain"; maya.calorieTarget = 650; maya.proteinTarget = 35; maya.cuisines = ["Indian"]
        var arjun = FamilyMember(); arjun.name = "Arjun"; arjun.goal = "weightManagement"; arjun.allergies = ["peanut"]; arjun.calorieTarget = 450
        return [maya, arjun]
    }()
    func identity() async throws -> String { accountIdentifier }
    func inventory() async throws -> [FridgeItem] { items }
    func members() async throws -> [FamilyMember] { family }
    func quota() async throws -> KitchenQuota { KitchenQuota(remaining: 4, limit: 4, generationRemaining: 4, generationLimit: 4) }
    func updateInventory(_ upserts: [FridgeItem], removing ids: [String]) async throws -> [FridgeItem] {
        if let inventoryError { throw inventoryError }
        items.removeAll { ids.contains($0.id) }
        for item in upserts {
            items.removeAll { $0.id == item.id }
            if !items.contains(where: { KitchenStore.normalize($0.name) == KitchenStore.normalize(item.name) }) { items.append(item) }
        }
        return items
    }
    func saveMember(_ member: FamilyMember, creating: Bool) async throws -> FamilyMember {
        family.removeAll { $0.id == member.id }; family.append(member)
        return member
    }
    func deleteMember(_ id: String) async throws { family.removeAll { $0.id == id } }
    func recognize(_ images: [Data]) async throws -> [FridgeItem] { [FridgeItem(name: "tomato"), FridgeItem(name: "spinach")] }
    func generate() async throws -> MealSuggestions {
        if let generationError { throw generationError }
        if ProcessInfo.processInfo.arguments.contains("--generation-fails") { throw APIError.networkError(URLError(.notConnectedToInternet)) }
        if ProcessInfo.processInfo.arguments.contains("--generation-limited") { throw APIError.rateLimited(retryAfter: nil) }
        let nutrition = NutritionEstimate(calories: 420, protein: 22, carbs: 48, fat: 15)
        let ingredients = [MealIngredient(name: "egg", quantity: "4 eggs", nutrition: NutritionEstimate(calories: 288, protein: 24, carbs: 2, fat: 20), isAvailable: true),
                           MealIngredient(name: "spinach", quantity: "150 g", nutrition: NutritionEstimate(calories: 35, protein: 4, carbs: 5, fat: 0), isAvailable: true),
                           MealIngredient(name: "rice", quantity: "140 g dry", nutrition: NutritionEstimate(calories: 517, protein: 16, carbs: 89, fat: 10), isAvailable: true)]
        let portions = family.map { member in
            MemberPortion(memberId: member.id, memberName: member.name, multiplier: 1, additions: [], nutrition: nutrition,
                          targetSummary: member.calorieTarget.map { "420 of \($0) kcal target" } ?? "A balanced portion", calorieDifference: member.calorieTarget.map { 420 - $0 }, proteinShortfall: member.proteinTarget.map { max(0, $0 - 22) })
        }
        func meal(missing: Bool) -> CookingMeal {
            CookingMeal(id: missing ? "shopping-meal" : "available-meal", name: missing ? "Lemony spinach rice" : "Spinach & egg rice", summary: "A comforting skillet of greens, soft eggs, and fluffy rice.", cookTimeMinutes: 20, difficulty: "easy", servings: 2,
                        ingredients: ingredients + (missing ? [MealIngredient(name: "lemon", quantity: "1 lemon", nutrition: NutritionEstimate(calories: 10, protein: 0, carbs: 3, fat: 0), isAvailable: false)] : []),
                        steps: ["Cook the rice in water until tender.", "Wilt the spinach in a warm skillet, then fold through the rice.", "Add the eggs and stir gently until cooked through. Divide into the suggested portions."], makeItFasterTip: "Use leftover cooked rice to save time.", goalExplanation: "Eggs provide protein while spinach adds variety. Adjust portions to suit each person's target.", portions: portions, nutrition: nutrition, missingIngredients: missing ? ["lemon"] : [])
        }
        return MealSuggestions(cookNow: [meal(missing: false)], shopping: [meal(missing: true)], profileSnapshot: family, inventorySnapshot: items, generatedAt: "2026-10-21T00:00:00Z")
    }
}
#endif
