import SwiftUI

struct ResultsView: View {
    @State private var viewModel: ResultsViewModel

    init(image: UIImage) {
        _viewModel = State(initialValue: ResultsViewModel(image: image))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView("Identifying ingredients...")
            } else if let error = viewModel.error {
                ErrorView(
                    message: error.userMessage,
                    systemImage: errorIcon(for: error)
                ) {
                    Task { await viewModel.scan() }
                }
            } else {
                resultsList
            }
        }
        .navigationTitle("Results")
        .task { await viewModel.scan() }
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: KiwiSpacing.xl) {
                if !viewModel.ingredients.isEmpty {
                    ingredientsSection
                }

                if !viewModel.recipes.isEmpty {
                    recipesSection
                }
            }
            .padding(KiwiSpacing.lg)
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: KiwiSpacing.md) {
            Text("Detected Ingredients")
                .font(KiwiTypography.title3)
                .fontWeight(.semibold)

            ForEach(viewModel.ingredients) { ingredient in
                IngredientRow(ingredient: ingredient) {
                    withAnimation { viewModel.removeIngredient(ingredient.id) }
                }
            }
        }
    }

    private var recipesSection: some View {
        VStack(alignment: .leading, spacing: KiwiSpacing.md) {
            Text("Suggested Recipes")
                .font(KiwiTypography.title3)
                .fontWeight(.semibold)

            ForEach(viewModel.recipes) { recipe in
                NavigationLink(value: recipe) {
                    RecipeCard(recipe: recipe)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailView(
                recipe: recipe,
                detectedIngredients: viewModel.ingredients
            )
        }
    }

    private func errorIcon(for error: APIError) -> String {
        switch error {
        case .rateLimited: "clock"
        case .networkError: "wifi.slash"
        default: "exclamationmark.triangle"
        }
    }
}

private struct RecipeCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: KiwiSpacing.sm) {
            Text(recipe.name)
                .font(KiwiTypography.headline)
                .foregroundStyle(.primary)

            Text(recipe.summary)
                .font(KiwiTypography.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: KiwiSpacing.md) {
                Label("\(recipe.cookTimeMinutes) min", systemImage: "clock")
                    .font(KiwiTypography.caption)

                Text(recipe.difficulty.rawValue.capitalized)
                    .font(KiwiTypography.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, KiwiSpacing.sm)
                    .padding(.vertical, KiwiSpacing.xs)
                    .background(recipe.difficulty == .easy ? Color.kiwiGreen.opacity(0.15) : Color.kiwiOrange.opacity(0.15))
                    .clipShape(Capsule())
            }
            .foregroundStyle(.secondary)
        }
        .padding(KiwiSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Tap to view recipe details")
    }
}
