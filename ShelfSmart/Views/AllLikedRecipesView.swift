//
//  AllLikedRecipesView.swift
//  ShelfSmart
//
//  Created by Claude on 9/23/25.
//

import FirebaseAuth
import SwiftData
import SwiftUI

struct AllLikedRecipesView: View {
    @Environment(\.modelContext) var modelContext
    @Query private var allRecipes: [SDRecipe]

    // Computed property for liked recipes by current user
    var likedRecipes: [SDRecipe] {
        let currentUserId = FirebaseAuth.Auth.auth().currentUser?.uid ?? ""
        return allRecipes.filter { recipe in
            recipe.isLiked && recipe.userId == currentUserId
        }
    }

    var body: some View {
        NavigationStack {
            if likedRecipes.isEmpty {
                // Empty State
                VStack(spacing: 24) {
                    Spacer()

                    VStack(spacing: 16) {
                        Circle()
                            .fill(.orange.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "heart.slash")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.orange.opacity(0.7))
                            }

                        VStack(spacing: 8) {
                            Text("No Liked Recipes")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            Text("Recipes you like will appear here")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(likedRecipes, id: \.self) { recipe in
                            NavigationLink(destination: RecipeDetailView(sdRecipe: recipe)) {
                                LikedRecipeCardView(recipe: recipe)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 100) // Extra space for navigation
                }
            }
        }
        .navigationTitle("Liked Recipes")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Liked Recipe Card Component (Home View Style)
struct LikedRecipeCardView: View {
    let recipe: SDRecipe

    var body: some View {
        HStack(spacing: 16) {
            // Recipe Image
            Group {
                if let imageLink = recipe.image, !imageLink.isEmpty {
                    // Convert HTTP to HTTPS if needed for App Transport Security
                    let secureImageLink = imageLink.hasPrefix("http://") ? imageLink.replacingOccurrences(of: "http://", with: "https://") : imageLink
                    AsyncImage(url: URL(string: secureImageLink)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else if phase.error != nil {
                            Image("placeholder")
                                .resizable()
                                .scaledToFill()
                        } else {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                } else {
                    Image("placeholder")
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
            )

            // Recipe Info
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.title ?? "Unknown Recipe")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let summary = recipe.summary, !summary.isEmpty {
                    let cleanSummary = summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                    Text(cleanSummary)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: 16) {
                    if let readyInMinutes = recipe.readyInMinutes {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text("\(readyInMinutes) mins")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let servings = recipe.servings {
                        HStack(spacing: 4) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text("\(servings) servings")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 70, alignment: .top) // Ensure consistent height and top alignment
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    AllLikedRecipesView()
}