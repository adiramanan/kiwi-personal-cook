import SwiftUI

struct RecipeDetailView: View {
    let viewModel: RecipeDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                // Ingredients
                ingredientsSection

                // Steps
                stepsSection

                // Make it faster tip
                if let tip = viewModel.recipe.makeItFasterTip {
                    makeItFasterSection(tip: tip)
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle(viewModel.recipe.name)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            Label("\(viewModel.recipe.cookTimeMinutes) min", systemImage: "clock")
                .font(.callout)
                .foregroundStyle(.secondary)

            difficultyBadge
        }
        .padding(.horizontal, 16)
    }

    private var difficultyBadge: some View {
        Text(viewModel.recipe.difficulty.rawValue.capitalized)
            .font(.callout)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(viewModel.recipe.difficulty == .easy ?
                          Color.kiwiGreen.opacity(0.15) :
                          Color.kiwiOrange.opacity(0.15))
            )
            .foregroundStyle(viewModel.recipe.difficulty == .easy ?
                             Color.kiwiGreen : Color.kiwiOrange)
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                if !viewModel.availableIngredients.isEmpty {
                    ForEach(viewModel.availableIngredients) { ingredient in
                        ingredientRow(ingredient: ingredient, isAvailable: true)
                        if ingredient.id != viewModel.availableIngredients.last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
                }

                if !viewModel.missingIngredients.isEmpty {
                    if !viewModel.availableIngredients.isEmpty {
                        Divider()
                    }
                    ForEach(viewModel.missingIngredients) { ingredient in
                        ingredientRow(ingredient: ingredient, isAvailable: false)
                        if ingredient.id != viewModel.missingIngredients.last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, 16)
        }
    }

    private func ingredientRow(ingredient: RecipeIngredient, isAvailable: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(isAvailable ? .kiwiGreen : .kiwiOrange)
                .font(.title3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(ingredient.name)
                        .font(.body)

                    if isAvailable {
                        Text("Available")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(Color.kiwiGreen.opacity(0.15))
                            )
                            .foregroundStyle(.kiwiGreen)
                    } else {
                        Text("Missing")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(Color.kiwiOrange.opacity(0.15))
                            )
                            .foregroundStyle(.kiwiOrange)
                    }
                }

                if !isAvailable, let substitution = ingredient.substitution {
                    Text("Substitute: \(substitution)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(ingredient.name), \(isAvailable ? "available" : "missing")")
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Steps")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                ForEach(Array(viewModel.recipe.steps.enumerated()), id: \.offset) { index, step in
                    stepCard(number: index + 1, text: step)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func stepCard(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.kiwiGreen))
                .accessibilityLabel("Step \(number)")

            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Make it Faster

    private func makeItFasterSection(tip: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Make It Faster", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundStyle(.kiwiOrange)

            Text(tip)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.kiwiOrange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.kiwiOrange.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Make it faster tip: \(tip)")
    }
}
