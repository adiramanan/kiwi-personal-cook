import Foundation

struct FamilyMember: Identifiable, Codable, Hashable, Sendable {
    var id = UUID().uuidString
    var name = ""
    var diet = "unrestricted"
    var allergies: [String] = []
    var restrictions: [String] = []
    var likes: [String] = []
    var dislikes: [String] = []
    var cuisines: [String] = []
    var spice = "mild"
    var goal = "balanced"
    var calorieTarget: Int?
    var proteinTarget: Double?

    var goalLabel: String {
        switch goal {
        case "weightManagement": "Weight management"
        case "muscleGain": "Muscle gain"
        default: "Balanced eating"
        }
    }
    var dietLabel: String { diet == "unrestricted" ? "No dietary restriction" : diet.capitalized }
}

struct FridgeItem: Identifiable, Codable, Hashable, Sendable {
    var id = UUID().uuidString
    var name: String
}
struct NutritionEstimate: Codable, Hashable, Sendable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
}
struct MealIngredient: Codable, Hashable, Sendable {
    let name: String
    let quantity: String
    let nutrition: NutritionEstimate
    let isAvailable: Bool?
}
struct MemberPortion: Codable, Hashable, Identifiable, Sendable {
    var id: String { memberId }
    let memberId: String
    let memberName: String
    let multiplier: Double
    let additions: [MealIngredient]
    let nutrition: NutritionEstimate
    let targetSummary: String
    let calorieDifference: Int?
    let proteinShortfall: Double?
}
struct MealSubstitution: Codable, Hashable, Sendable {
    let replaces: String
    let alternative: MealIngredient
}
struct CookingMeal: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let summary: String
    let cookTimeMinutes: Int
    let difficulty: String
    let servings: Int
    let ingredients: [MealIngredient]
    let steps: [String]
    let makeItFasterTip: String?
    let goalExplanation: String
    let portions: [MemberPortion]
    let nutrition: NutritionEstimate
    let missingIngredients: [String]
    var substitutions: [MealSubstitution]? = nil
}
struct MealSuggestions: Codable, Sendable {
    let cookNow: [CookingMeal]
    let shopping: [CookingMeal]
    let profileSnapshot: [FamilyMember]
    let inventorySnapshot: [FridgeItem]
    let generatedAt: String
}
struct ShoppingItem: Identifiable, Codable, Hashable {
    var id = UUID().uuidString
    var name: String
    var checked = false
}
struct KitchenQuota: Decodable {
    let remaining: Int
    let limit: Int
    let generationRemaining: Int
    let generationLimit: Int
}
struct InventoryEnvelope: Codable { let ingredients: [FridgeItem] }
struct FamilyEnvelope: Codable { let members: [FamilyMember] }
struct InventoryMutation: Encodable { let upserts: [FridgeItem]; let removedIDs: [String] }
struct DeleteEnvelope: Decodable { let deleted: Bool }
struct IdentityEnvelope: Decodable { let accountID: String }

protocol KitchenServing {
    func identity() async throws -> String
    func inventory() async throws -> [FridgeItem]
    func members() async throws -> [FamilyMember]
    func quota() async throws -> KitchenQuota
    func updateInventory(_ items: [FridgeItem], removing ids: [String]) async throws -> [FridgeItem]
    func saveMember(_ member: FamilyMember, creating: Bool) async throws -> FamilyMember
    func deleteMember(_ id: String) async throws
    func recognize(_ images: [Data]) async throws -> [FridgeItem]
    func generate() async throws -> MealSuggestions
}

struct KitchenService: KitchenServing {
    let client: APIClient
    init(client: APIClient = .shared) { self.client = client }
    func identity() async throws -> String {
        let result: IdentityEnvelope = try await client.request(.kitchen("identity", "GET"))
        return result.accountID
    }
    func inventory() async throws -> [FridgeItem] {
        let result: InventoryEnvelope = try await client.request(.kitchen("inventory", "GET"))
        return result.ingredients
    }
    func members() async throws -> [FamilyMember] {
        let result: FamilyEnvelope = try await client.request(.kitchen("family", "GET"))
        return result.members
    }
    func quota() async throws -> KitchenQuota { try await client.request(.kitchen("quota", "GET")) }
    func updateInventory(_ items: [FridgeItem], removing ids: [String]) async throws -> [FridgeItem] {
        let result: InventoryEnvelope = try await client.send(.kitchen("inventory", "PATCH"), body: InventoryMutation(upserts: items, removedIDs: ids))
        return result.ingredients
    }
    func saveMember(_ member: FamilyMember, creating: Bool) async throws -> FamilyMember {
        // IDs are server-owned on creation and are not part of profile input.
        let encoded = try JSONEncoder().encode(member)
        var object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any] ?? [:]
        object.removeValue(forKey: "id")
        return try await client.sendData(.kitchen(creating ? "family" : "family/\(member.id)", creating ? "POST" : "PUT"), body: JSONSerialization.data(withJSONObject: object))
    }
    func deleteMember(_ id: String) async throws {
        let _: DeleteEnvelope = try await client.request(.kitchen("family/\(id)", "DELETE"))
    }
    func recognize(_ images: [Data]) async throws -> [FridgeItem] {
        let response: InventoryEnvelope = try await client.uploadImages(images)
        return response.ingredients
    }
    func generate() async throws -> MealSuggestions { try await client.request(.kitchen("recipes", "POST")) }
}
