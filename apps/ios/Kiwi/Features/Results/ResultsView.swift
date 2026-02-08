import SwiftUI

struct ResultsView: View {
    @Bindable var viewModel: ResultsViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView("Identifying ingredients...")
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    Task { await viewModel.scan() }
                }
            } else {
                resultsContent
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.scan()
        }
    }

    private var resultsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Detected Ingredients Section
                ingredientsSection

                // Recipes Section
                recipesSection
            }
            .padding(.vertical, 16)
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Ingredients")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 16)

            if viewModel.ingredients.isEmpty {
                emptyIngredientsView
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.ingredients) { ingredient in
                        IngredientRow(ingredient: ingredient) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.removeIngredient(ingredient.id)
                            }
                        }
                        Divider()
                            .padding(.leading, 48)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                )
                .padding(.horizontal, 16)
            }
        }
    }

    private var emptyIngredientsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "carrot")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No ingredients detected")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var recipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipes")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 16)

            if viewModel.recipes.isEmpty {
                emptyRecipesView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(viewModel.recipes.enumerated()), id: \.element.id) { index, recipe in
                        NavigationLink(destination: RecipeDetailView(
                            viewModel: RecipeDetailViewModel(
                                recipe: recipe,
                                detectedIngredients: viewModel.ingredients
                            )
                        )) {
                            RecipeCard(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1),
                            value: viewModel.recipes.count
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var emptyRecipesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No recipes available")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Recipe Card

struct RecipeCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(recipe.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Text(recipe.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 16) {
                Label("\(recipe.cookTimeMinutes) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                difficultyBadge
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name), \(recipe.cookTimeMinutes) minutes, \(recipe.difficulty.rawValue)")
        .accessibilityHint("Tap to view recipe details")
    }

    private var difficultyBadge: some View {
        Text(recipe.difficulty.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(recipe.difficulty == .easy ? Color.kiwiGreen.opacity(0.15) : Color.kiwiOrange.opacity(0.15))
            )
            .foregroundStyle(recipe.difficulty == .easy ? Color.kiwiGreen : Color.kiwiOrange)
    }
}
