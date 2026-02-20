import SwiftUI

struct RecipeDetailView: View {
    @State private var viewModel: RecipeDetailViewModel

    init(recipe: Recipe, detectedIngredients: [Ingredient]) {
        _viewModel = State(initialValue: RecipeDetailViewModel(
            recipe: recipe,
            detectedIngredients: detectedIngredients
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KiwiSpacing.xl) {
                header
                ingredientsSection
                stepsSection

                if let tip = viewModel.recipe.makeItFasterTip {
                    tipCard(tip)
                }
            }
            .padding(KiwiSpacing.lg)
        }
        .navigationTitle(viewModel.recipe.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: KiwiSpacing.sm) {
            Text(viewModel.recipe.summary)
                .font(KiwiTypography.body)
                .foregroundStyle(.secondary)

            HStack(spacing: KiwiSpacing.lg) {
                Label("\(viewModel.recipe.cookTimeMinutes) min", systemImage: "clock")
                Label(
                    viewModel.recipe.difficulty.rawValue.capitalized,
                    systemImage: viewModel.recipe.difficulty == .easy ? "gauge.low" : "gauge.medium"
                )
            }
            .font(KiwiTypography.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: KiwiSpacing.md) {
            Text("Ingredients")
                .font(KiwiTypography.title3)
                .fontWeight(.semibold)

            if !viewModel.availableIngredients.isEmpty {
                ForEach(viewModel.availableIngredients) { ingredient in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.kiwiGreen)
                        Text(ingredient.name)
                            .font(KiwiTypography.body)
                        Spacer()
                        Text("Available")
                            .font(KiwiTypography.caption)
                            .foregroundStyle(.kiwiGreen)
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            if !viewModel.missingIngredients.isEmpty {
                ForEach(viewModel.missingIngredients) { ingredient in
                    VStack(alignment: .leading, spacing: KiwiSpacing.xs) {
                        HStack {
                            Image(systemName: "circle.dashed")
                                .foregroundStyle(.kiwiOrange)
                            Text(ingredient.name)
                                .font(KiwiTypography.body)
                            Spacer()
                            Text("Missing")
                                .font(KiwiTypography.caption)
                                .foregroundStyle(.kiwiOrange)
                        }

                        if let sub = ingredient.substitution {
                            Text("Substitute: \(sub)")
                                .font(KiwiTypography.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 28)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: KiwiSpacing.md) {
            Text("Steps")
                .font(KiwiTypography.title3)
                .fontWeight(.semibold)

            ForEach(Array(viewModel.recipe.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: KiwiSpacing.md) {
                    Text("\(index + 1)")
                        .font(KiwiTypography.headline)
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.kiwiGreen)
                        .clipShape(Circle())

                    Text(step)
                        .font(KiwiTypography.body)
                }
                .padding(KiwiSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func tipCard(_ tip: String) -> some View {
        VStack(alignment: .leading, spacing: KiwiSpacing.sm) {
            Label("Make It Faster", systemImage: "bolt.fill")
                .font(KiwiTypography.headline)
                .foregroundStyle(.kiwiOrange)

            Text(tip)
                .font(KiwiTypography.body)
        }
        .padding(KiwiSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.kiwiOrange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
