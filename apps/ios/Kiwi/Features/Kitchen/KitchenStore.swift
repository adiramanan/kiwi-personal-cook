import SwiftUI

@MainActor @Observable
final class KitchenStore {
    var inventory: [FridgeItem] = []
    var members: [FamilyMember] = []
    var suggestions: MealSuggestions?
    var shopping: [ShoppingItem] = []
    var quota: KitchenQuota?
    var isLoading = false
    var isGenerating = false
    var error: String?
    private(set) var requiresSignIn = false
    private(set) var accountID: String?
    private let service: any KitchenServing
    private let defaults: UserDefaults

    init(service: (any KitchenServing)? = nil, defaults: UserDefaults = .standard) {
        self.service = service ?? KitchenService()
        self.defaults = defaults
    }

    static func makeDefault() -> KitchenStore {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--kitchen-ui-tests") {
            return KitchenStore(service: KitchenFixtureService(), defaults: UserDefaults(suiteName: "kiwi-ui-tests")!)
        }
#endif
        return KitchenStore()
    }

    var resultsAreStale: Bool {
        guard let suggestions else { return false }
        return Set(suggestions.profileSnapshot) != Set(members) || Set(suggestions.inventorySnapshot) != Set(inventory)
    }
    var goalSummary: String {
        let goals = Set(members.map(\.goalLabel))
        return goals.isEmpty ? "Good food, made from what you have." : goals.sorted().joined(separator: " · ")
    }

    func refresh() async {
        guard !isLoading, !requiresSignIn else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let identity = try await service.identity()
            async let fridge = service.inventory()
            async let family = service.members()
            let (newInventory, newMembers) = try await (fridge, family)
            try Task.checkCancellation()
            if accountID != identity { accountID = identity; loadShopping() }
            inventory = newInventory
            members = newMembers
            quota = try? await service.quota()
        } catch { report(error) }
    }
    func saveInventory(_ items: [FridgeItem], removing ids: [String] = []) async -> Bool {
        error = nil
        do {
            let updated = try await service.updateInventory(items, removing: ids)
            inventory = updated
            return true
        } catch { report(error); return false }
    }
    func saveMember(_ member: FamilyMember, creating: Bool) async -> Bool {
        error = nil
        do {
            let saved = try await service.saveMember(member, creating: creating)
            members.removeAll { $0.id == saved.id }
            members.append(saved)
            return true
        } catch { report(error); return false }
    }
    func deleteMember(_ member: FamilyMember) async {
        error = nil
        do {
            try await service.deleteMember(member.id)
            members.removeAll { $0.id == member.id }
        } catch { report(error) }
    }
    func recognize(_ images: [Data]) async throws -> [FridgeItem] {
        error = nil
        do {
            let items = try await service.recognize(images)
            quota = try? await service.quota()
            return items
        } catch { report(error); throw error }
    }
    func generate() async {
        guard !isGenerating, !inventory.isEmpty else { return }
        error = nil
        isGenerating = true
        defer { isGenerating = false }
        do {
            let response = try await service.generate()
            try Task.checkCancellation()
            suggestions = response
            quota = try? await service.quota()
        } catch { report(error) }
    }
    func addShopping(_ names: [String]) {
        guard accountID != nil else { return }
        for name in names {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if let index = shopping.firstIndex(where: { Self.normalize($0.name) == Self.normalize(trimmed) }) {
                shopping[index].checked = false
            } else { shopping.append(ShoppingItem(name: trimmed)) }
        }
        persistShopping()
    }
    func toggleShopping(_ id: String) {
        guard let index = shopping.firstIndex(where: { $0.id == id }) else { return }
        shopping[index].checked.toggle()
        persistShopping()
    }
    func removeShopping(_ id: String) {
        shopping.removeAll { $0.id == id }; persistShopping()
    }
    private func loadShopping() {
        guard let accountID else { return }
        let key = "com.kiwi.shopping.\(accountID)"
        shopping = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode([ShoppingItem].self, from: $0) } ?? []
        // Preserve the old checklist, importing it for the first account only.
        if !defaults.bool(forKey: "com.kiwi.shopping.legacyImported"),
           let data = defaults.data(forKey: "com.kiwi.groceries"),
           let legacy = try? JSONDecoder().decode([Ingredient].self, from: data) {
            addShopping(legacy.map(\.name))
            defaults.set(true, forKey: "com.kiwi.shopping.legacyImported")
        }
    }
    private func persistShopping() {
        guard let accountID, let data = try? JSONEncoder().encode(shopping) else { return }
        defaults.set(data, forKey: "com.kiwi.shopping.\(accountID)")
    }
    func clearLocalAccountData() {
        if let accountID { defaults.removeObject(forKey: "com.kiwi.shopping.\(accountID)") }
        inventory = []; members = []; shopping = []; suggestions = nil; quota = nil
        accountID = nil
    }
    private func report(_ error: Error) {
        guard !Task.isCancelled, !(error is CancellationError) else { return }
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                requiresSignIn = true
                self.error = nil
            case .rateLimited: self.error = "You've reached today's allowance. Your fridge and profiles are saved. Try again tomorrow."
            case .serverError(_, let message): self.error = message ?? apiError.userMessage
            default: self.error = apiError.userMessage
            }
        } else { self.error = "Couldn't finish that. Your changes are still here—please try again." }
    }
    static func normalize(_ value: String) -> String {
        value.precomposedStringWithCompatibilityMapping.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
