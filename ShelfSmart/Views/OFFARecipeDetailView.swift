//
//  OFFARecipeDetailView.swift
//  ShelfSmart
//
//  Created by Claude Code on 11/15/25.
//

import SwiftUI
import SwiftData

struct OFFARecipeDetailView: View {
    let userId: String
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    let sdRecipe: SDOFFARecipe

    private var isLiked: Bool {
        sdRecipe.isLiked
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero Image Section
                heroImageSection

                VStack(spacing: 24) {
                    // Recipe Info
                    recipeInfoSection

                    // Dietary Badges
                    dietaryBadges

                    // Summary/Description
                    if let summary = sdRecipe.summary, !summary.isEmpty {
                        descriptionSection(summary)
                    }

                    // Ingredients
                    if let ingredients = sdRecipe.extendedIngredients, !ingredients.isEmpty {
                        ingredientsSection(ingredients)
                    }

                    // Instructions
                    if let instructions = sdRecipe.instructions, !instructions.isEmpty {
                        instructionsSection(instructions)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(sdRecipe.title ?? "Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    toggleLike()
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(isLiked ? .red : .primary)
                }
            }
        }
    }

    // MARK: - Hero Image Section
    private var heroImageSection: some View {
        ZStack {
            if let imageUrl = sdRecipe.image, !imageUrl.isEmpty {
                RobustAsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                }
            } else {
                Color(.systemGray4)
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    // MARK: - Recipe Info Section
    private var recipeInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(sdRecipe.title ?? "Recipe")
                .font(.title)
                .fontWeight(.bold)

            HStack(spacing: 20) {
                if let readyInMinutes = sdRecipe.readyInMinutes {
                    InfoBadge(icon: "clock", text: "\(readyInMinutes) min")
                }

                if let servings = sdRecipe.servings {
                    InfoBadge(icon: "person.2", text: "\(servings) servings")
                }

                if let healthScore = sdRecipe.healthScore {
                    InfoBadge(icon: "heart.fill", text: "\(Int(healthScore))% healthy")
                }
            }
        }
    }

    // MARK: - Dietary Badges
    @ViewBuilder
    private var dietaryBadges: some View {
        let badges = getDietaryBadges()
        if !badges.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(badges, id: \.self) { badge in
                        DietaryBadge(text: badge, color: .green)
                    }
                }
            }
        }
    }

    private func getDietaryBadges() -> [String] {
        var badges: [String] = []

        if sdRecipe.vegetarian == true {
            badges.append("Vegetarian")
        }
        if sdRecipe.glutenFree == true {
            badges.append("Gluten-Free")
        }
        if sdRecipe.dairyFree == true {
            badges.append("Dairy-Free")
        }
        if sdRecipe.veryHealthy == true {
            badges.append("Very Healthy")
        }
        if sdRecipe.sustainable == true {
            badges.append("Sustainable")
        }

        return badges
    }

    // MARK: - Description Section
    private func descriptionSection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.title2)
                .fontWeight(.bold)

            Text(summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Ingredients Section
    private func ingredientsSection(_ ingredients: [SDOFFAIngredients]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(ingredients, id: \.id) { ingredient in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)

                        Text(ingredient.original ?? "Unknown ingredient")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Instructions Section
    private func instructionsSection(_ instructions: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.title2)
                .fontWeight(.bold)

            Text(instructions.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Helper Functions
    private func toggleLike() {
        sdRecipe.likeRecipe(userId: userId)
    }
}

// MARK: - Supporting Views
struct InfoBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
        )
        .foregroundStyle(.secondary)
    }
}

