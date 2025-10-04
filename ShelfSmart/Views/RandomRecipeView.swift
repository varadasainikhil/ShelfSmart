//
//  RandomRecipeView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct RandomRecipeView: View {
    @Environment(\.modelContext) var modelContext
    @State var viewModel: RandomRecipeViewModel

    // Query all saved recipes to check if current recipe is liked
    @Query private var allRecipes: [SDRecipe]

    // Track the saved version of the current recipe
    @State private var currentSavedRecipe: SDRecipe?

    // Share sheet state
    @State private var shareURL: IdentifiableURL?

    init(viewModel: RandomRecipeViewModel = RandomRecipeViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        Text("Getting your random recipe...")
                            .font(.headline)
                        Text("This may take a moment")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Oops! Something went wrong")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        
                        Button("Try Again") {
                            Task {
                                await viewModel.completelyRandomRecipe()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else if let recipe = viewModel.currentRecipe {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Hero Image Section
                            heroImageSection(for: recipe)

                            VStack(spacing: 24) {
                                // Combined Recipe Info Card
                                combinedRecipeInfoCard(for: recipe)

                                // Dietary Badges
                                dietaryBadges(for: recipe)

                                // Description Section
                                descriptionSection(for: recipe)

                                // Ingredients Section
                                ingredientsSection(for: recipe)

                                // Instructions Section
                                instructionsSection(for: recipe)

                                // Credits Section
                                creditsSection(for: recipe)

                                Spacer(minLength: 40)
                            }
                        }
                        .padding()
                    }
                    
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No recipe loaded")
                            .font(.headline)
                        
                        Text("Something went wrong while loading your recipe")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .toolbar {
                if viewModel.currentRecipe != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            toggleLikeRecipe()
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }) {
                            Image(systemName: currentSavedRecipe?.isLiked == true ? "heart.fill" : "heart")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(currentSavedRecipe?.isLiked == true ? .red : .black)
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            if let sourceUrl = viewModel.currentRecipe?.sourceUrl,
                               let url = URL(string: sourceUrl) {
                                shareURL = IdentifiableURL(url: url)
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .onChange(of: viewModel.currentRecipe?.id) { oldValue, newValue in
                // Update saved recipe state when current recipe changes
                findSavedRecipe()
            }
            .sheet(item: $shareURL) { identifiableURL in
                ShareSheet(items: [identifiableURL.url])
            }
        }
    }

    // MARK: - Helper Functions

    /// Finds if the current recipe is already saved in SwiftData
    private func findSavedRecipe() {
        guard let currentRecipe = viewModel.currentRecipe else {
            currentSavedRecipe = nil
            return
        }

        // Find the recipe by ID
        currentSavedRecipe = allRecipes.first(where: { $0.id == currentRecipe.id })
    }

    /// Toggles the like status of the current recipe
    private func toggleLikeRecipe() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user ID found")
            return
        }

        guard let currentRecipe = viewModel.currentRecipe else {
            print("❌ No current recipe")
            return
        }

        if let savedRecipe = currentSavedRecipe {
            // Recipe already exists in SwiftData, toggle its like status
            savedRecipe.likeRecipe(userId: userId)

            do {
                try modelContext.save()
                print("✅ Recipe like status toggled")
            } catch {
                print("❌ Failed to save recipe like status: \(error)")
            }
        } else {
            // Recipe doesn't exist yet, create new SDRecipe and mark as liked
            let newRecipe = SDRecipe(from: currentRecipe)
            newRecipe.isLiked = true
            newRecipe.userId = userId

            modelContext.insert(newRecipe)

            do {
                try modelContext.save()
                currentSavedRecipe = newRecipe
                print("✅ Recipe saved and liked")
            } catch {
                print("❌ Failed to save new recipe: \(error)")
            }
        }
    }

    // MARK: - View Sections

    // Hero Image Section
    private func heroImageSection(for recipe: Recipe) -> some View {
        Group {
            if let imageUrl = recipe.image {
                SimpleAsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // Combined Recipe Info Card
    private func combinedRecipeInfoCard(for recipe: Recipe) -> some View {
        ModernCardContainer {
            VStack(spacing: 20) {
                // Recipe Title
                Text(recipe.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Recipe Metrics Row
                HStack {
                    // Time
                    if let readyInMinutes = recipe.readyInMinutes {
                        RecipeMetric(
                            icon: "clock.fill",
                            value: "\(readyInMinutes)",
                            label: "mins",
                            color: .blue
                        )
                    }

                    Spacer()

                    Divider()
                        .frame(height: 30)

                    Spacer()

                    // Servings
                    if let servings = recipe.servings {
                        RecipeMetric(
                            icon: "fork.knife",
                            value: "\(servings)",
                            label: "servings",
                            color: .green
                        )
                    }

                    Spacer()

                    Divider()
                        .frame(height: 30)

                    Spacer()

                    // Health Score
                    if let healthScore = recipe.healthScore {
                        RecipeMetric(
                            icon: "heart.fill",
                            value: "\(Int(healthScore))",
                            label: "health",
                            color: .red
                        )
                    }
                }
            }
        }
    }

    // Dietary Badges
    private func dietaryBadges(for recipe: Recipe) -> some View {
        let badges = getDietaryBadges(for: recipe)

        return Group {
            if !badges.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dietary Information")
                        .font(.headline)
                        .fontWeight(.semibold)

                    FlowLayout(spacing: 8) {
                        ForEach(badges, id: \.text) { badge in
                            DietaryBadge(text: badge.text, color: badge.color)
                        }
                    }
                }
            }
        }
    }

    // Description Section
    private func descriptionSection(for recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Description
            if let summary = recipe.summary {
                let cleanSummary = summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                Text(String(cleanSummary.prefix(200)) + (cleanSummary.count > 200 ? "..." : ""))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
            }

            // Recipe Source Link
            if !recipe.sourceUrl.isEmpty {
                Link(destination: URL(string: recipe.sourceUrl)!) {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.caption)
                        Text("View Original Recipe")
                            .font(.subheadline)
                            .underline()
                    }
                    .foregroundColor(.blue)
                }
                .padding(.top, 8)
            }
        }
    }

    // Ingredients Section
    private func ingredientsSection(for recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.title2)
                .fontWeight(.bold)

            ModernCardContainer {
                if let ingredients = recipe.extendedIngredients, !ingredients.isEmpty {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                            RecipeIngredientRow(ingredient: ingredient)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .foregroundStyle(.gray)
                        Text("No ingredients available")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("This recipe doesn't have detailed ingredient information")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
    }

    // Instructions Section
    private func instructionsSection(for recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions")
                .font(.title2)
                .fontWeight(.bold)

            ModernCardContainer {
                VStack(spacing: 20) {
                    if let analyzedInstructions = recipe.analyzedInstructions,
                       !analyzedInstructions.isEmpty,
                       let steps = analyzedInstructions.first?.steps {
                        let sortedSteps = steps.sorted { $0.number < $1.number }
                        ForEach(Array(sortedSteps.enumerated()), id: \.offset) { index, step in
                            RecipeInstructionStepView(step: step)
                        }
                    } else if let instructions = recipe.instructions, !instructions.isEmpty {
                        let cleanInstructions = instructions.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                        Text(cleanInstructions)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("No instructions available")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
    }

    // Credits Section
    private func creditsSection(for recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if recipe.creditsText != nil || recipe.sourceName != nil {
                Text("Recipe Information")
                    .font(.title2)
                    .fontWeight(.bold)

                ModernCardContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        if let creditsText = recipe.creditsText {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Credits")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Text(creditsText)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let sourceName = recipe.sourceName {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Source")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Text(sourceName)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // API Attribution
            HStack(spacing: 6) {
                Image(systemName: "network")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("Powered by Spoonacular API")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 8)
        }
    }

    private func getDietaryBadges(for recipe: Recipe) -> [(text: String, color: Color)] {
        var badges: [(text: String, color: Color)] = []

        if recipe.vegetarian == true {
            badges.append(("Vegetarian", .green))
        }
        if recipe.glutenFree == true {
            badges.append(("Gluten Free", .blue))
        }
        if recipe.dairyFree == true {
            badges.append(("Dairy Free", .purple))
        }
        if recipe.veryHealthy == true {
            badges.append(("Very Healthy", .orange))
        }

        return badges
    }
}

// MARK: - Supporting Types

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Supporting Components (for API models)

struct RecipeIngredientRow: View {
    let ingredient: Ingredients

    var body: some View {
        HStack(spacing: 12) {
            // Ingredient Image
            Group {
                if let imageFilename = ingredient.image {
                    SimpleAsyncImage(url: "https://spoonacular.com/cdn/ingredients_100x100/\(imageFilename)") { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(.gray)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.1))
            )

            // Ingredient Text
            VStack(alignment: .leading, spacing: 2) {
                if !ingredient.name.isEmpty {
                    Text(ingredient.name.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                Text(ingredient.original)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct RecipeInstructionStepView: View {
    let step: Steps

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step Number
            Text("\(step.number)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color(.systemBackground))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.green)
                )

            // Step Description
            Text(step.step)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
    }
}

#Preview {
    RandomRecipeView()
}
