import SwiftUI

struct CookHomeView: View {
    @Environment(KitchenStore.self) private var kitchen
    @State private var showScan = false
    @State private var showShopping = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                KitchenHeading(eyebrow: "Your personal cook", title: "Good food.\nYour goals.", subtitle: "A little inspiration from what's already in your fridge.")
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        Image(systemName: "leaf.circle.fill").font(.largeTitle).foregroundStyle(.kitchenGreen).accessibilityHidden(true)
                        Spacer()
                        KitchenBadge(text: "\(kitchen.inventory.count) ingredients")
                    }
                    Text(kitchen.goalSummary).font(.title3.weight(.medium))
                    Text(kitchen.members.isEmpty ? "Add your family's tastes and goals for meals that feel like you." : "One shared meal. Portions that work for each of you.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    if kitchen.inventory.isEmpty {
                        KitchenAction(title: "Add what's in your fridge", icon: "camera") { showScan = true }
                    } else {
                        KitchenAction(title: kitchen.isGenerating ? "Finding your next meal…" : "Find recipes", busy: kitchen.isGenerating) {
                            Task { await kitchen.generate() }
                        }
                        .disabled(kitchen.quota?.generationRemaining == 0 || kitchen.isLoading)
                    }
                    if let quota = kitchen.quota {
                        Text("\(quota.generationRemaining) recipe requests left today").font(.caption).foregroundStyle(.secondary)
                    }
                }.kitchenSurface()

                if kitchen.isLoading && kitchen.inventory.isEmpty {
                    ProgressView("Opening your kitchen…").frame(maxWidth: .infinity)
                }
                if kitchen.resultsAreStale {
                    Label("Your fridge or profiles changed. Find recipes again to use the latest details.", systemImage: "arrow.clockwise")
                        .font(.subheadline).foregroundStyle(.secondary).kitchenSurface()
                }
                if let suggestions = kitchen.suggestions {
                    if suggestions.cookNow.isEmpty && suggestions.shopping.isEmpty {
                        ContentUnavailableView("Let's try a different mix", systemImage: "carrot", description: Text("No suitable meals matched your ingredients and restrictions. Update your fridge or preferences, then try again."))
                    }
                    mealSection("Cook now", subtitle: "Made with what you have", meals: suggestions.cookNow)
                    mealSection("Just a little shopping", subtitle: "A couple of extras open up more possibilities", meals: suggestions.shopping)
                    Text("Nutrition is estimated. Check ingredient labels and suitability for allergies before cooking.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else if !kitchen.inventory.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your ingredients, more possibilities.").font(.title2.weight(.semibold)).fontDesign(.serif)
                        Text("Find meals you can cook now, plus a few ideas that need just one or two extras.")
                            .foregroundStyle(.secondary)
                    }
                }
            }.padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Kiwi").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showScan = true } label: { Image(systemName: "camera") }.accessibilityLabel("Scan your fridge")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showShopping = true } label: { Image(systemName: "basket") }.accessibilityLabel("Shopping list")
            }
        }
        .refreshable { await kitchen.refresh() }
        .sheet(isPresented: $showScan) { NavigationStack { FridgeCaptureView() } }
        .sheet(isPresented: $showShopping) { NavigationStack { ShoppingListView() } }
    }
    @ViewBuilder private func mealSection(_ title: String, subtitle: String, meals: [CookingMeal]) -> some View {
        if !meals.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text(title).font(.title2.weight(.semibold)).fontDesign(.serif)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                ForEach(meals) { meal in
                    NavigationLink { CookingMealDetailView(meal: meal) } label: { CookingMealCard(meal: meal) }
                        .buttonStyle(.plain)
                }
            }
        }
    }
}

struct CookingMealCard: View {
    let meal: CookingMeal
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("\(meal.cookTimeMinutes) min", systemImage: "clock")
                Spacer()
                Text(meal.difficulty.capitalized)
            }.font(.caption).foregroundStyle(.secondary)
            Text(meal.name).font(.title2.weight(.semibold)).fontDesign(.serif).foregroundStyle(.primary)
            Text(meal.summary).font(.subheadline).foregroundStyle(.secondary)
            ViewThatFits(in: .horizontal) {
                HStack {
                    KitchenBadge(text: "≈ \(Int(meal.nutrition.calories)) kcal / serving")
                    KitchenBadge(text: "\(Int(meal.nutrition.protein)) g protein")
                }
                VStack(alignment: .leading) {
                    KitchenBadge(text: "≈ \(Int(meal.nutrition.calories)) kcal / serving")
                    KitchenBadge(text: "\(Int(meal.nutrition.protein)) g protein")
                }
            }
            if !meal.missingIngredients.isEmpty {
                Label("Buy: \(meal.missingIngredients.joined(separator: ", "))", systemImage: "basket").font(.caption).foregroundStyle(.secondary)
            }
        }.kitchenSurface()
        .accessibilityElement(children: .combine)
    }
}
