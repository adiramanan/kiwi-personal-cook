import SwiftUI

struct RecipeDetailView: View {
    @State private var viewModel: RecipeDetailViewModel

    init(recipe: Recipe) {
        _viewModel = State(initialValue: RecipeDetailViewModel(recipe: recipe))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.recipe.name)
                    .font(.largeTitle)
                HStack {
                    Label("\(viewModel.recipe.cookTimeMinutes) min", systemImage: "clock")
                    Label(viewModel.recipe.difficulty.rawValue.capitalized, systemImage: "bolt.fill")
                }
                .font(.kiwiCaption)
                .foregroundStyle(.secondary)

                Text("Ingredients")
                    .font(.kiwiHeadline)
                ForEach(viewModel.recipe.ingredients) { ingredient in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ingredient.name)
                            .font(.kiwiBody)
                        Text(ingredient.isDetected ? "Available" : "Missing")
                            .font(.kiwiCaption)
                            .foregroundStyle(ingredient.isDetected ? .green : .red)
                        if let substitution = ingredient.substitution, !ingredient.isDetected {
                            Text("Substitution: \(substitution)")
                                .font(.kiwiCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                }

                Text("Steps")
                    .font(.kiwiHeadline)
                ForEach(viewModel.recipe.steps.indices, id: \.self) { index in
                    Text("\(index + 1). \(viewModel.recipe.steps[index])")
                        .font(.kiwiBody)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                }

                if let tip = viewModel.recipe.makeItFasterTip {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Make it faster")
                            .font(.kiwiHeadline)
                        Text(tip)
                            .font(.kiwiBody)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.kiwiAccent.opacity(0.2)))
                }
            }
            .padding()
        }
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
    }
}
