import SwiftUI

struct CookingMealDetailView: View {
    @Environment(KitchenStore.self) private var kitchen
    let meal: CookingMeal
    @State private var addedToList = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                KitchenHeading(eyebrow: "\(meal.cookTimeMinutes) minutes · \(meal.difficulty) · \(meal.servings) base servings", title: meal.name, subtitle: meal.summary)
                Label(meal.goalExplanation, systemImage: "leaf").font(.subheadline).kitchenSurface()
                nutrition(meal.nutrition, title: "Estimated per base serving")
                if !meal.portions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("For everyone at the table").font(.title2.weight(.semibold)).fontDesign(.serif)
                        ForEach(meal.portions) { portion in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(portion.memberName).font(.headline)
                                Text("\(portion.multiplier.formatted()) × base serving").font(.subheadline)
                                Text(portion.targetSummary).font(.caption).foregroundStyle(.secondary)
                                if let difference = portion.calorieDifference, abs(difference) > 0 {
                                    Text("≈ \(abs(difference)) kcal \(difference > 0 ? "above" : "below") your meal target").font(.caption).foregroundStyle(.secondary)
                                }
                                if let shortfall = portion.proteinShortfall, shortfall > 0 {
                                    Text("≈ \(shortfall.formatted()) g below your protein target").font(.caption).foregroundStyle(.secondary)
                                }
                                ForEach(Array(portion.additions.enumerated()), id: \.offset) { _, addition in
                                    Text("Add \(addition.quantity) \(addition.name)").font(.subheadline)
                                }
                                nutritionLine(portion.nutrition)
                            }.kitchenSurface()
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 16) {
                    Text("Ingredients").font(.title2.weight(.semibold)).fontDesign(.serif)
                    Text("Quantities below make \(meal.servings) base servings. Each person's additions are listed above.").font(.footnote).foregroundStyle(.secondary)
                    ForEach(Array(meal.ingredients.enumerated()), id: \.offset) { _, ingredient in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: ingredient.isAvailable == true ? "checkmark.circle.fill" : "basket").foregroundStyle(.kitchenGreen)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ingredient.name).font(.headline)
                                Text(ingredient.quantity).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(ingredient.isAvailable == true ? "In fridge" : "To buy").font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 6).accessibilityElement(children: .combine)
                    }
                }.kitchenSurface()
                if let swaps = meal.substitutions, !swaps.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("A swap from your fridge").font(.headline)
                        ForEach(Array(swaps.enumerated()), id: \.offset) { _, swap in
                            Text("Instead of \(swap.replaces), use \(swap.alternative.quantity) \(swap.alternative.name).")
                        }
                        Text("Nutrition and target comparisons above use the original recipe ingredients.").font(.footnote).foregroundStyle(.secondary)
                    }.kitchenSurface()
                }
                if !meal.missingIngredients.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("A little shopping").font(.headline)
                        Text(meal.missingIngredients.joined(separator: ", ")).font(.subheadline)
                        KitchenAction(title: addedToList ? "Added to shopping list" : "Add missing items to shopping list", icon: addedToList ? "checkmark" : "basket") {
                            kitchen.addShopping(meal.missingIngredients); addedToList = true
                        }.disabled(kitchen.accountID == nil)
                    }.kitchenSurface()
                }
                VStack(alignment: .leading, spacing: 20) {
                    Text("Let's cook").font(.title2.weight(.semibold)).fontDesign(.serif)
                    ForEach(Array(meal.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 16) {
                            Text(String(index + 1)).font(.headline).frame(width: 32, height: 32).background(Color.kitchenGreen.opacity(0.1), in: Circle())
                            Text(step).font(.body).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                if let tip = meal.makeItFasterTip { Label(tip, systemImage: "bolt").font(.subheadline).kitchenSurface() }
                Text("Nutrition values are estimates, not verified measurements. These recipes use the fridge and family profiles saved when they were generated. Check food labels, allergies, and ingredient suitability before cooking.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(24)
        }.background(Color(.systemGroupedBackground))
        .navigationTitle("Recipe").navigationBarTitleDisplayMode(.inline)
    }
    private func nutrition(_ values: NutritionEstimate, title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) { Text(title).font(.headline); nutritionLine(values) }.kitchenSurface()
    }
    private func nutritionLine(_ values: NutritionEstimate) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 18) { nutritionValues(values) }
            VStack(alignment: .leading, spacing: 8) { nutritionValues(values) }
        }.font(.subheadline)
    }
    @ViewBuilder private func nutritionValues(_ values: NutritionEstimate) -> some View {
        Text("≈ \(Int(values.calories)) kcal")
        Text("\(values.protein.formatted()) g protein")
        Text("\(values.carbs.formatted()) g carbs")
        Text("\(values.fat.formatted()) g fat")
    }
}

struct ShoppingListView: View {
    @Environment(KitchenStore.self) private var kitchen
    @Environment(\.dismiss) private var dismiss
    @State private var newItem = ""
    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Add something to buy", text: $newItem).onSubmit { add() }
                    Button { add() } label: { Image(systemName: "plus").frame(width: 44, height: 44) }.accessibilityLabel("Add shopping item")
                        .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || kitchen.accountID == nil)
                }
            }
            if kitchen.shopping.isEmpty {
                ContentUnavailableView("Nothing to pick up", systemImage: "basket", description: Text("Add missing recipe ingredients here. They stay separate from what's in your fridge."))
            }
            ForEach(kitchen.shopping) { item in
                HStack {
                    Button { kitchen.toggleShopping(item.id) } label: {
                        Image(systemName: item.checked ? "checkmark.circle.fill" : "circle").frame(width: 44, height: 44)
                    }.buttonStyle(.plain).accessibilityLabel("\(item.checked ? "Uncheck" : "Check") \(item.name)")
                    Text(item.name).strikethrough(item.checked).foregroundStyle(item.checked ? .secondary : .primary)
                    Spacer()
                    if item.checked {
                        Button("In fridge") {
                            Task {
                                if await kitchen.saveInventory([FridgeItem(name: item.name)]) { kitchen.removeShopping(item.id) }
                            }
                        }.font(.caption).buttonStyle(.bordered).accessibilityLabel("Add \(item.name) to fridge")
                    }
                }
            }.onDelete { offsets in
                let ids = offsets.map { kitchen.shopping[$0].id }; ids.forEach { kitchen.removeShopping($0) }
            }
            Section { Text("Check off what you bought, then tap In fridge to make it available for recipes.").font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle("Shopping list").navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Done") { dismiss() } }
    }
    private func add() {
        kitchen.addShopping([newItem]); newItem = ""
    }
}
