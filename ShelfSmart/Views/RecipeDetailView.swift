//
//  RecipeDetailView.swift
//  ShelfSmart
//
//  Created by AI Assistant on 9/18/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct RecipeDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    let recipe: Recipe

    // Query to find if this recipe is already saved and liked
    @Query private var savedRecipes: [SDRecipe]

    private var existingRecipe: SDRecipe? {
        savedRecipes.first { $0.id == recipe.id }
    }

    private var isLiked: Bool {
        existingRecipe?.isLiked ?? false
    }
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Recipe Image with Heart Overlay
                    if let imageUrl = recipe.image, !imageUrl.isEmpty {
                        ZStack {
                            SimpleAsyncImage(url: imageUrl) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Heart Overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        toggleLikeRecipe()
                                        // Show success feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                    }) {
                                        Image(systemName: isLiked ? "heart.fill" : "heart")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundStyle(isLiked ? .red : .white)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                Circle()
                                                    .fill(.black.opacity(0.3))
                                                    .blur(radius: 1)
                                            )
                                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.trailing, 12)
                                    .padding(.bottom, 12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Recipe Title
                        Text(recipe.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // Recipe Info
                        recipeInfoView(recipe)
                        
                        // Diet badges
                        dietBadgesView(recipe)
                        
                        // Description
                        if let summary = recipe.summary {
                            let cleanSummary = summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                            Text(String(cleanSummary.prefix(200)) + (cleanSummary.count > 200 ? "..." : ""))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(4)
                        }
                        
                        // Recipe Source Link
                        if !recipe.sourceUrl.isEmpty && recipe.sourceUrl != "https://spoonacular.com/recipe/\(recipe.id)" {
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
                        
                        // Ingredients Section
                        ingredientsView(recipe)
                        
                        // Directions Section
                        directionsView(recipe)

                        // Credits Section
                        creditsView(recipe)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Recipe Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Recipe Detail Components
    
    private func recipeInfoView(_ recipe: Recipe) -> some View {
        HStack {
            if let readyInMinutes = recipe.readyInMinutes {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(readyInMinutes) mins")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let pricePerServing = recipe.pricePerServing {
                HStack(spacing: 4) {
                    Image(systemName: "flame")
                        .font(.caption)
                    Text("\(Int(pricePerServing)) calories")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let servings = recipe.servings {
                HStack(spacing: 4) {
                    Image(systemName: "fork.knife")
                        .font(.caption)
                    Text("\(servings) servings")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }
        }
    }
    
    private func dietBadgesView(_ recipe: Recipe) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if recipe.vegetarian == true {
                    Text("Vegetarian")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.2))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
                if recipe.glutenFree == true {
                    Text("Gluten Free")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                if recipe.dairyFree == true {
                    Text("Dairy Free")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .clipShape(Capsule())
                }
                if recipe.veryHealthy == true {
                    Text("Very Healthy")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private func ingredientsView(_ recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(Array((recipe.extendedIngredients ?? []).enumerated()), id: \.offset) { index, ingredient in
                    HStack(alignment: .center, spacing: 12) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 4, height: 4)
                        
                        if let imageFilename = ingredient.image {
                            AsyncImage(url: URL(string: "https://spoonacular.com/cdn/ingredients_100x100/\(imageFilename)")) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        
                        Text(ingredient.original)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.leading, 8)
                }
            }
        }
        .padding(.top)
    }
    
    private func directionsView(_ recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Directions")
                .font(.title2)
                .fontWeight(.bold)
            
            if let analyzedInstructions = recipe.analyzedInstructions, !analyzedInstructions.isEmpty {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(Array((analyzedInstructions[0].steps ?? []).enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(step.number).")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .frame(minWidth: 20, alignment: .leading)
                            
                            Text(step.step)
                                .font(.body)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                }
            } else if let instructions = recipe.instructions {
                Text(instructions.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil))
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .padding(.top)
    }
    
    private func creditsView(_ recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .padding(.vertical, 16)
            
            VStack(alignment: .leading, spacing: 12) {
                if let creditsText = recipe.creditsText {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recipe Credits")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(creditsText)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                }
                
                if let sourceName = recipe.sourceName {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Source")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(sourceName)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "network")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Powered by Spoonacular API")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            
            Spacer(minLength: 20)
        }
        .padding(.top, 24)
    }
    
    // MARK: - Helper Methods

    private func toggleLikeRecipe() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }

        do {
            if let existing = existingRecipe {
                // Recipe already exists, toggle like status
                existing.likeRecipe(userId: userId)
                if !existing.isLiked {
                    // If unliked and not associated with a product, remove it
                    if existing.product == nil {
                        modelContext.delete(existing)
                    }
                }
            } else {
                // Recipe doesn't exist, create and like it
                let sdRecipe = SDRecipe(from: recipe)
                sdRecipe.likeRecipe(userId: userId)
                modelContext.insert(sdRecipe)
            }

            try modelContext.save()
            print("✅ Recipe like status updated successfully")
        } catch {
            print("❌ Failed to update recipe like status: \(error)")
        }
    }
}

#Preview {
    let sampleRecipe = Recipe(
        id: 12345,
        image: "https://spoonacular.com/recipeImages/12345-312x231.jpg",
        title: "Delicious Pasta with Fresh Tomatoes",
        readyInMinutes: 30,
        servings: 4,
        sourceUrl: "https://example.com/recipe",
        vegetarian: true,
        glutenFree: false,
        dairyFree: true,
        veryHealthy: nil,
        cheap: nil,
        veryPopular: nil,
        sustainable: nil,
        lowFodmap: nil,
        weightWatcherSmartPoints: nil,
        gaps: nil,
        prepationMinutes: nil,
        cookingMinute: nil,
        healthScore: nil,
        creditsText: "Recipe by Chef John",
        license: nil,
        sourceName: "Food Network",
        pricePerServing: nil,
        extendedIngredients: nil,
        summary: "A delicious pasta recipe with fresh tomatoes and herbs.",
        cuisines: nil,
        dishTypes: nil,
        diets: nil,
        occasions: nil,
        instructions: "Cook pasta according to package directions...",
        analyzedInstructions: nil,
        spoonacularScore: nil,
        spoonacularSourceUrl: "https://spoonacular.com/recipe/12345"
    )
    
    RecipeDetailView(recipe: sampleRecipe)
}
