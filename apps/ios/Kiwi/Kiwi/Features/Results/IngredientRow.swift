import SwiftUI

struct IngredientRow: View {
    let ingredient: Ingredient
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Text(ingredient.name)
                .font(.kiwiBody)
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Remove \(ingredient.name)")
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }
}
