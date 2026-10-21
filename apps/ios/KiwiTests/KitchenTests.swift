import Testing
import Foundation
@testable import Kiwi

@MainActor @Suite("Saved kitchen and dietary goals")
struct KitchenTests {
    private func defaults() -> UserDefaults { UserDefaults(suiteName: UUID().uuidString)! }

    @Test func rejectedSessionRequestsSignInInsteadOfRepeatingAnAlert() async {
        let service = KitchenFixtureService()
        service.identityError = .unauthorized
        let kitchen = KitchenStore(service: service, defaults: defaults())
        await kitchen.refresh()
        #expect(kitchen.requiresSignIn)
        #expect(kitchen.error == nil)
        #expect(kitchen.accountID == nil)
        // Foreground refresh must not resume loading data with this rejected session.
        service.identityError = nil
        await kitchen.refresh()
        #expect(kitchen.accountID == nil)
        #expect(kitchen.inventory.isEmpty)
    }

    @Test func networkFailureDoesNotExpireTheSession() async {
        let service = KitchenFixtureService()
        let kitchen = KitchenStore(service: service, defaults: defaults())
        await kitchen.refresh()
        let savedInventory = kitchen.inventory
        service.identityError = .networkError(URLError(.timedOut))
        await kitchen.refresh()
        #expect(!kitchen.requiresSignIn)
        #expect(kitchen.error != nil)
        #expect(kitchen.inventory == savedInventory)
        service.identityError = nil
        await kitchen.refresh()
        #expect(!kitchen.requiresSignIn)
    }

    @Test func rejectedSessionDuringGenerationRequestsSignIn() async {
        let service = KitchenFixtureService()
        let kitchen = KitchenStore(service: service, defaults: defaults())
        await kitchen.refresh()
        service.generationError = .unauthorized
        await kitchen.generate()
        #expect(kitchen.requiresSignIn)
        #expect(kitchen.error == nil)
        #expect(!kitchen.isGenerating)
    }

    @Test func savesIngredientsForLaterCooking() async {
        let service = KitchenFixtureService()
        let kitchen = KitchenStore(service: service, defaults: defaults())
        await kitchen.refresh()
        #expect(kitchen.suggestions == nil)
        let count = kitchen.inventory.count
        #expect(await kitchen.saveInventory([FridgeItem(name: "tomato")]))
        #expect(kitchen.inventory.count == count + 1)
        let reopened = KitchenStore(service: service, defaults: defaults())
        await reopened.refresh()
        #expect(reopened.inventory.contains { $0.name == "tomato" })
        #expect(reopened.suggestions == nil)
    }
    @Test func profileChangesInvalidatePreviousSuggestionsWithoutRewritingThem() async {
        let service = KitchenFixtureService()
        let kitchen = KitchenStore(service: service, defaults: defaults())
        await kitchen.refresh(); await kitchen.generate()
        #expect(!kitchen.resultsAreStale)
        var updated = kitchen.members[0]
        let oldGoal = updated.goal
        updated.goal = "balanced"
        #expect(await kitchen.saveMember(updated, creating: false))
        #expect(kitchen.resultsAreStale)
        #expect(kitchen.suggestions?.profileSnapshot.first?.goal == oldGoal)
        await kitchen.generate()
        #expect(!kitchen.resultsAreStale)
    }
    @Test func inventoryCorrectionsInvalidateSuggestions() async {
        let kitchen = KitchenStore(service: KitchenFixtureService(), defaults: defaults())
        await kitchen.refresh(); await kitchen.generate()
        #expect(await kitchen.saveInventory([], removing: [kitchen.inventory[0].id]))
        #expect(kitchen.resultsAreStale)
    }
    @Test func shoppingIsSeparateDeduplicatedAndPersistsForTheAccount() async {
        let service = KitchenFixtureService(), storage = defaults()
        let kitchen = KitchenStore(service: service, defaults: storage)
        await kitchen.refresh()
        kitchen.addShopping(["lemon", " Lemon ", ""])
        #expect(kitchen.shopping.count == 1)
        #expect(!kitchen.inventory.contains { $0.name == "lemon" })
        kitchen.toggleShopping(kitchen.shopping[0].id)
        let reopened = KitchenStore(service: service, defaults: storage)
        await reopened.refresh()
        #expect(reopened.shopping.first?.checked == true)
        reopened.addShopping(["lemon"])
        #expect(reopened.shopping.first?.checked == false)
        reopened.clearLocalAccountData()
        #expect(reopened.shopping.isEmpty && reopened.members.isEmpty && reopened.inventory.isEmpty)
    }
    @Test func migratesLegacyGroceriesWithoutDeletingThem() async throws {
        let storage = defaults()
        let legacy = [Ingredient(id: "legacy", name: "Bread", category: nil, confidence: 1)]
        storage.set(try JSONEncoder().encode(legacy), forKey: "com.kiwi.groceries")
        let kitchen = KitchenStore(service: KitchenFixtureService(), defaults: storage)
        await kitchen.refresh()
        #expect(kitchen.shopping.first?.name == "Bread")
        #expect(storage.data(forKey: "com.kiwi.groceries") != nil)
    }
    @Test func failedGenerationRetainsPreviousMealsAndCanRetry() async {
        let service = KitchenFixtureService()
        let kitchen = KitchenStore(service: service, defaults: defaults())
        await kitchen.refresh(); await kitchen.generate()
        service.generationError = .networkError(URLError(.notConnectedToInternet))
        await kitchen.generate()
        #expect(!kitchen.isGenerating)
        #expect(kitchen.error != nil)
        #expect(kitchen.suggestions?.cookNow.isEmpty == false)
        service.generationError = nil
        await kitchen.generate()
        #expect(!kitchen.isGenerating)
        #expect(kitchen.error == nil)
    }
    @Test func failedInventorySaveDoesNotDiscardExistingIngredients() async {
        let service = KitchenFixtureService()
        let kitchen = KitchenStore(service: service, defaults: defaults())
        await kitchen.refresh()
        let original = kitchen.inventory
        service.inventoryError = .networkError(URLError(.notConnectedToInternet))
        #expect(await kitchen.saveInventory([FridgeItem(name: "tomato")]) == false)
        #expect(kitchen.inventory == original)
        #expect(kitchen.error != nil)
    }
    @Test func shoppingDoesNotLeakBetweenAccounts() async {
        let storage = defaults()
        let firstService = KitchenFixtureService()
        let first = KitchenStore(service: firstService, defaults: storage)
        await first.refresh(); first.addShopping(["lemon"])
        let secondService = KitchenFixtureService(); secondService.accountIdentifier = "another-account"
        let second = KitchenStore(service: secondService, defaults: storage)
        await second.refresh()
        #expect(second.shopping.isEmpty)
    }
    @Test func profilesDoNotRequireNumericBudgets() throws {
        let data = Data("""
        {"id":"123","name":"Ada","diet":"vegan","allergies":[],"restrictions":[],"likes":["tofu"],"dislikes":[],"cuisines":[],"spice":"mild","goal":"muscleGain"}
        """.utf8)
        let member = try JSONDecoder().decode(FamilyMember.self, from: data)
        #expect(member.calorieTarget == nil && member.proteinTarget == nil)
        #expect(member.goalLabel == "Muscle gain")
    }
}
