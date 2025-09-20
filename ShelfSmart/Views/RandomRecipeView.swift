//
//  RandomRecipeView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import SwiftUI
import SwiftData

struct RandomRecipeView: View {
    @Environment(\.modelContext) var modelContext
    @State var viewModel = RandomRecipeViewModel()
    
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
                        VStack(alignment: .leading, spacing: 16) {
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
                            }
                            
                            // Recipe Title
                            Text(recipe.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            // Recipe Info with SF Symbols
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
                                        Text("\(Int(pricePerServing)) calories per serving")
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
                            
                            // Diet badges
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
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ingredients")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                LazyVStack(alignment: .leading, spacing: 12) {
                                    ForEach(Array((recipe.extendedIngredients ?? []).enumerated()), id: \.offset) { index, ingredient in
                                        HStack(alignment: .center, spacing: 12) {
                                            // Bullet point
                                            Circle()
                                                .fill(Color.black)
                                                .frame(width: 4, height: 4)
                                            
                                            // Ingredient image
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
                                                // Default placeholder for missing images
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                                    .frame(width: 32, height: 32)
                                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                            }
                                            
                                            // Ingredient text with quantity
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
                            
                            // Directions Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Directions")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if let analyzedInstructions = recipe.analyzedInstructions, !analyzedInstructions.isEmpty {
                                    LazyVStack(alignment: .leading, spacing: 16) {
                                        ForEach(Array((analyzedInstructions[0].steps ?? []).enumerated()), id: \.offset) { index, step in
                                            HStack(alignment: .top, spacing: 12) {
                                                // Step number
                                                Text("\(step.number).")
                                                    .font(.body)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                    .frame(minWidth: 20, alignment: .leading)
                                                
                                                // Step description
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
                            
                            // Credits Section
                            VStack(alignment: .leading, spacing: 16) {
                                Divider()
                                    .padding(.vertical, 16)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    // Credits heading and content
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
                                    
                                    // Source information
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
                                    
                                    // API Attribution
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
                                
                                // Bottom spacing
                                Spacer(minLength: 20)
                            }
                            .padding(.top, 24)
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
            .navigationTitle("Random Recipe")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    RandomRecipeView()
}
