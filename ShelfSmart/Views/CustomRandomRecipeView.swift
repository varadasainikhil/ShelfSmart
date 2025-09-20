//
//  CustomRandomRecipeView.swift
//  ShelfSmart
//
//  Created by AI Assistant on 9/18/25.
//

import SwiftUI
import SwiftData

struct CustomRandomRecipeView: View {
    @Environment(\.modelContext) var modelContext
    @State var viewModel: RandomRecipeViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                } else if let recipe = viewModel.currentRecipe {
                    recipeContentView(recipe)
                } else if viewModel.hasAnySelections {
                    // User has made selections but no recipe yet - show loading or try to get one
                    loadingOrRetryView
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Your Recipe")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            Text("Finding your perfect recipe...")
                .font(.headline)
            Text("Based on your preferences")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ errorMessage: String) -> some View {
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
                    await viewModel.customRandomRecipe()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var loadingOrRetryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chef.hat")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Let's find your recipe!")
                .font(.headline)
            
            Text("Based on your selected preferences, we'll find the perfect recipe for you")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button("Get My Recipe") {
                Task {
                    await viewModel.customRandomRecipe()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No preferences selected")
                .font(.headline)
            
            Text("Go back and select your meal preferences to find recipes")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func recipeContentView(_ recipe: Recipe) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Selected Filters Summary
                if viewModel.hasAnySelections {
                    filtersSummaryView
                }
                
                // Recipe Image
                if let imageUrl = recipe.image {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .overlay {
                                ProgressView()
                            }
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    
                    // Ingredients Section
                    ingredientsView(recipe)
                    
                    // Directions Section
                    directionsView(recipe)
                    
                    // Action Buttons
                    actionButtonsView
                    
                    // Credits Section
                    creditsView(recipe)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Recipe Detail Components
    
    private var filtersSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.selectedMealTypes, id: \.self) { mealType in
                        FilterBadge(text: mealType.capitalized, color: .blue)
                    }
                    ForEach(viewModel.selectedCuisines, id: \.self) { cuisine in
                        FilterBadge(text: cuisine.capitalized, color: .green)
                    }
                    ForEach(viewModel.selectedDiets, id: \.self) { diet in
                        FilterBadge(text: diet.replacingOccurrences(of: "_", with: " ").capitalized, color: .purple)
                    }
                    ForEach(viewModel.selectedIntolerances, id: \.self) { intolerance in
                        FilterBadge(text: "No \(intolerance.capitalized)", color: .red)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
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
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            Button(action: {
                let success = viewModel.saveCurrentRecipe(to: modelContext)
                if success {
                    // Show success feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }) {
                HStack {
                    Image(systemName: "heart.fill")
                    Text("Save Recipe")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green)
                )
                .shadow(radius: 5)
            }
            
            Button(action: {
                Task {
                    await viewModel.customRandomRecipe()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Find Another Recipe")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.green, lineWidth: 2)
                )
            }
        }
        .padding(.top, 24)
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
}

// MARK: - Filter Badge Component
struct FilterBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

#Preview {
    return CustomRandomRecipeView(viewModel: RandomRecipeViewModel())
}
