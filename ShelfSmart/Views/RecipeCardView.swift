//
//  RecipeCard.swift
//  ShelfSmart
//
//  Created by AI Assistant on 9/18/25.
//

import SwiftUI

struct RecipeCardView: View {
    let sdRecipe: SDRecipe
    let onTap: () -> Void

    private var isLiked: Bool { sdRecipe.isLiked }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Recipe Image with Heart Indicator
                ZStack {
                    RobustAsyncImage(url: sdRecipe.image) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }
                    .frame(height: 120)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Heart indicator overlay (visual only, when liked)
                    if isLiked {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .background(
                                        Circle()
                                            .fill(.red)
                                            .frame(width: 22, height: 22)
                                    )
                            }
                            .padding(.trailing, 8)
                            .padding(.top, 8)
                            Spacer()
                        }
                    }
                }
                
                // Recipe Info - Fixed height container
                VStack(alignment: .leading, spacing: 8) {
                    // Recipe Title - Fixed height
                    Text(sdRecipe.title ?? "Unknown Recipe")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                        .frame(height: 44, alignment: .top) // Fixed height for 2 lines
                    
                    // Recipe Meta Info
                    HStack(spacing: 12) {
                        // Ready Time
                        if let readyInMinutes = sdRecipe.readyInMinutes {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(readyInMinutes)m")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Servings
                        if let servings = sdRecipe.servings {
                            HStack(spacing: 4) {
                                Image(systemName: "fork.knife")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(servings)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Health badges
                        HStack(spacing: 4) {
                            if sdRecipe.vegetarian == true {
                                Text("V")
                                    .font(.caption2.bold())
                                    .foregroundColor(.green)
                                    .frame(width: 16, height: 16)
                                    .background(.green.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            
                            if sdRecipe.glutenFree == true {
                                Text("GF")
                                    .font(.caption2.bold())
                                    .foregroundColor(.blue)
                                    .frame(width: 16, height: 16)
                                    .background(.blue.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            
                            if sdRecipe.dairyFree == true {
                                Text("DF")
                                    .font(.caption2.bold())
                                    .foregroundColor(.purple)
                                    .frame(width: 16, height: 16)
                                    .background(.purple.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .padding(12)
                .frame(height: 100) // Fixed height for the info section
            }
        }
        .buttonStyle(RecipeCardButtonStyle())
        .frame(height: 220) // Fixed total height for all cards
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// Custom button style for the recipe card
struct RecipeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    let sampleSDRecipe = SDRecipe(
        id: 12345,
        title: "Delicious Pasta with Fresh Tomatoes",
        sourceUrl: "https://example.com/recipe",
        spoonacularSourceUrl: "https://spoonacular.com/recipe/12345"
    )

    // Set additional properties
    sampleSDRecipe.image = "https://spoonacular.com/recipeImages/12345-312x231.jpg"
    sampleSDRecipe.readyInMinutes = 30
    sampleSDRecipe.servings = 4
    sampleSDRecipe.vegetarian = true
    sampleSDRecipe.glutenFree = false
    sampleSDRecipe.dairyFree = true
    sampleSDRecipe.isLiked = true

    return RecipeCardView(sdRecipe: sampleSDRecipe) {
        print("Recipe tapped")
    }
    .padding()
}
