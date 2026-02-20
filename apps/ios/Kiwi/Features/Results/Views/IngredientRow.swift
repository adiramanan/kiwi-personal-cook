import SwiftUI

struct IngredientRow: View {
    let ingredient: Ingredient
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.kiwiGreen)
                .accessibilityHidden(true)

            Text(ingredient.name)
                .font(KiwiTypography.body)

            if let category = ingredient.category {
                Text(category)
                    .font(KiwiTypography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, KiwiSpacing.sm)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }

            Spacer()

            Button(role: .destructive) {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Remove \(ingredient.name)")
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.vertical, KiwiSpacing.xs)
    }
}

#Preview {
    IngredientRow(
        ingredient: Ingredient(id: "1", name: "Eggs", category: "Protein", confidence: 0.95)
    ) {}
}
