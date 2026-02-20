import SwiftUI

struct GroceriesView: View {
    @State private var viewModel = GroceriesViewModel()

    var body: some View {
        List {
            Section {
                HStack(spacing: KiwiSpacing.md) {
                    TextField("Add ingredient...", text: $viewModel.newItemName)
                        .textFieldStyle(.plain)
                        .submitLabel(.done)
                        .onSubmit { viewModel.addItem() }

                    Button {
                        viewModel.addItem()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.kiwiGreen)
                    }
                    .disabled(viewModel.newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Add ingredient")
                }
            }

            if viewModel.ingredients.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Groceries Yet",
                        systemImage: "carrot",
                        description: Text("Add ingredients manually or scan your fridge to populate this list.")
                    )
                }
            } else {
                Section("Your Ingredients") {
                    ForEach(viewModel.ingredients) { ingredient in
                        GroceryRow(ingredient: ingredient)
                    }
                    .onDelete { offsets in
                        viewModel.removeItems(at: offsets)
                    }
                }
            }
        }
        .navigationTitle("Groceries")
        .animation(.default, value: viewModel.ingredients.count)
    }
}

private struct GroceryRow: View {
    let ingredient: Ingredient

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: KiwiSpacing.xs) {
                Text(ingredient.name)
                    .font(KiwiTypography.body)

                if let category = ingredient.category {
                    Text(category)
                        .font(KiwiTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if ingredient.confidence < 1.0 {
                Text("\(Int(ingredient.confidence * 100))%")
                    .font(KiwiTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        GroceriesView()
    }
}
