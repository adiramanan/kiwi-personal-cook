import SwiftUI

struct ResultsView: View {
    @State private var viewModel: ResultsViewModel

    init(image: UIImage) {
        _viewModel = State(initialValue: ResultsViewModel(image: image))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    LoadingView(label: "Identifying ingredients...")
                } else if let error = viewModel.error {
                    ErrorView(title: "Something went wrong", message: error.message, retryTitle: "Try Again") {
                        Task { await viewModel.scan() }
                    }
                } else {
                    Text("Detected Ingredients")
                        .font(.kiwiHeadline)
                    ForEach(viewModel.ingredients) { ingredient in
                        IngredientRow(ingredient: ingredient) {
                            viewModel.removeIngredient(ingredient.id)
                        }
                    }

                    Text("Recipes")
                        .font(.kiwiHeadline)
                        .padding(.top, 8)
                    ForEach(viewModel.recipes) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeCard(recipe: recipe)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailView(recipe: recipe)
        }
        .task {
            await viewModel.scan()
        }
    }
}

private struct RecipeCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.name)
                .font(.kiwiHeadline)
            Text(recipe.summary)
                .font(.kiwiBody)
                .foregroundStyle(.secondary)
            HStack {
                Label("\(recipe.cookTimeMinutes) min", systemImage: "clock")
                Label(recipe.difficulty.rawValue.capitalized, systemImage: "bolt.fill")
            }
            .font(.kiwiCaption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }
}
