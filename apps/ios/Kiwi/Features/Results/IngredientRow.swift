import SwiftUI

struct IngredientRow: View {
    let ingredient: Ingredient
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.kiwiGreen)
                .font(.title3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.body)

                if let category = ingredient.category {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Remove \(ingredient.name)")
            .accessibilityHint("Removes this ingredient from the detected list")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    IngredientRow(
        ingredient: Ingredient(id: "1", name: "Eggs", category: "Protein", confidence: 0.95)
    ) {
        print("Remove tapped")
    }
}
