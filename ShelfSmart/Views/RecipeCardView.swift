//
//  RecipeCard.swift
//  ShelfSmart
//
//  Created by AI Assistant on 9/18/25.
//

import SwiftUI

struct RecipeCardView: View {
    @Environment(\.colorScheme) var colorScheme
    let sdRecipe: SDRecipe
    let onTap: () -> Void

    // Safe property accessors with defaults to prevent crashes on deleted objects
    private var isLiked: Bool { sdRecipe.isLiked }
    private var recipeTitle: String { sdRecipe.title ?? "Unknown Recipe" }
    private var recipeImage: String? { sdRecipe.image }
    private var readyInMinutes: Int? { sdRecipe.readyInMinutes }
    private var servings: Int? { sdRecipe.servings }
    private var isVegetarian: Bool { sdRecipe.vegetarian ?? false }
    private var isGlutenFree: Bool { sdRecipe.glutenFree ?? false }
    private var isDairyFree: Bool { sdRecipe.dairyFree ?? false }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Recipe Image with Heart Indicator
                ZStack {
                    RobustAsyncImage(url: recipeImage) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }
                    .frame(height: 120)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
                    )

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
                    Text(recipeTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                        .frame(height: 44, alignment: .top) // Fixed height for 2 lines

                    // Recipe Meta Info
                    HStack(spacing: 12) {
                        // Ready Time
                        if let minutes = readyInMinutes {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(minutes)m")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Servings
                        if let servingCount = servings {
                            HStack(spacing: 4) {
                                Image(systemName: "fork.knife")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(servingCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // Health badges
                        HStack(spacing: 4) {
                            if isVegetarian {
                                Text("V")
                                    .font(.caption2.bold())
                                    .foregroundColor(.green)
                                    .frame(width: 16, height: 16)
                                    .background(.green.opacity(0.2))
                                    .clipShape(Circle())
                            }

                            if isGlutenFree {
                                Text("GF")
                                    .font(.caption2.bold())
                                    .foregroundColor(.blue)
                                    .frame(width: 16, height: 16)
                                    .background(.blue.opacity(0.2))
                                    .clipShape(Circle())
                            }

                            if isDairyFree {
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
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear,
                    lineWidth: 0.5
                )
        )
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.5), radius: 2, x: 0, y: -1)
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
