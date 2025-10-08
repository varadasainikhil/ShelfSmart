//
//  RecipeDetailView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/18/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct RecipeDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    let sdRecipe: SDRecipe
    @State private var isDeleting = false
    @State private var shareURL: IdentifiableURL?

    private var isLiked: Bool {
        sdRecipe.isLiked
    }

    var body: some View {
        if isDeleting {
            // Show loading state during deletion to prevent accessing deleted object
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Removing recipe...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero Image Section
                    heroImageSection

                    VStack(spacing: 24) {
                        // Combined Recipe Info Card
                        combinedRecipeInfoCard

                        // Dietary Badges
                        dietaryBadges

                        // Description Section
                        descriptionSection

                        // Ingredients Section
                        ingredientsSection

                        // Instructions Section
                        instructionsSection

                        // Credits Section
                        creditsSection

                        Spacer(minLength: 40)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        toggleLikeRecipe()
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isLiked ? .red : .primary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        if let sourceUrl = sdRecipe.sourceUrl,
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
            .sheet(item: $shareURL) { identifiableURL in
                ShareSheet(items: [identifiableURL.url])
            }
        }
    }

    // MARK: - Modern Recipe Detail Sections

    // Hero Image Section
    private var heroImageSection: some View {
        Group {
            if let imageUrl = sdRecipe.image {
                RobustAsyncImage(url: imageUrl) { image in
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
    private var combinedRecipeInfoCard: some View {
        ModernCardContainer {
            VStack(spacing: 20) {
                // Recipe Title
                Text(sdRecipe.title ?? "Unknown Recipe")
                    .font(.title)
                    .fontWeight(.bold)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Recipe Metrics Row
                HStack {
                    // Time
                    if let readyInMinutes = sdRecipe.readyInMinutes {
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
                    if let servings = sdRecipe.servings {
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
                    if let healthScore = sdRecipe.healthScore {
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
    private var dietaryBadges: some View {
        let badges = getDietaryBadges()

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
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Description
            if let summary = sdRecipe.summary {
                let cleanSummary = summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                Text(String(cleanSummary.prefix(200)) + (cleanSummary.count > 200 ? "..." : ""))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
            }

            // Recipe Source Link
            if let sourceUrl = sdRecipe.sourceUrl,
               !sourceUrl.isEmpty &&
               sourceUrl != "https://spoonacular.com/recipe/\(sdRecipe.id ?? 0)",
               let url = URL(string: sourceUrl) {
                Link(destination: url) {
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
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.title2)
                .fontWeight(.bold)

            ModernCardContainer {
                if let ingredients = sdRecipe.extendedIngredients, !ingredients.isEmpty {
                    let _ = print("🥕 Found \(ingredients.count) ingredients for recipe: \(sdRecipe.title ?? "Unknown")")
                    VStack(spacing: 16) {
                        ForEach(Array(ingredients.enumerated()), id: \.offset) { index, sdIngredient in
                            let _ = print("🥕 Ingredient \(index): name='\(sdIngredient.name ?? "")', original='\(sdIngredient.original ?? "")'")
                            ModernIngredientRow(sdIngredient: sdIngredient)
                        }
                    }
                } else {
                    let _ = print("❌ No ingredients found for recipe: \(sdRecipe.title ?? "Unknown")")
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
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions")
                .font(.title2)
                .fontWeight(.bold)

            ModernCardContainer {
                VStack(spacing: 20) {
                    if let analyzedInstructions = sdRecipe.analyzedInstructions,
                       !analyzedInstructions.isEmpty,
                       let steps = analyzedInstructions.first?.steps {
                        let sortedSteps = steps.sorted { ($0.number ?? 0) < ($1.number ?? 0) }
                        ForEach(Array(sortedSteps.enumerated()), id: \.offset) { index, step in
                            InstructionStepView(step: step)
                        }
                    } else if let instructions = sdRecipe.instructions, !instructions.isEmpty {
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
    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if sdRecipe.creditsText != nil || sdRecipe.sourceName != nil {
                Text("Recipe Information")
                    .font(.title2)
                    .fontWeight(.bold)

                ModernCardContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        if let creditsText = sdRecipe.creditsText {
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

                        if let sourceName = sdRecipe.sourceName {
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

    // MARK: - Helper Methods

    private func toggleLikeRecipe() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Check if this will cause deletion
        let willBeDeleted = sdRecipe.isLiked && sdRecipe.product == nil

        if willBeDeleted {
            // Set state to remove UI that references the object
            isDeleting = true

            // Perform deletion on the next run loop to allow UI to update
            Task {
                ProductHelpers.unlikeRecipe(sdRecipe, userId: userId, modelContext: modelContext) { deleted in
                    if deleted {
                        dismiss()
                    } else {
                        // Revert state if deletion fails
                        isDeleting = false
                    }
                }
            }
        } else {
            // Just a simple state update, no deletion
            ProductHelpers.unlikeRecipe(sdRecipe, userId: userId, modelContext: modelContext)
        }
    }

    private func getDietaryBadges() -> [(text: String, color: Color)] {
        var badges: [(text: String, color: Color)] = []

        if sdRecipe.vegetarian == true {
            badges.append(("Vegetarian", .green))
        }
        if sdRecipe.glutenFree == true {
            badges.append(("Gluten Free", .blue))
        }
        if sdRecipe.dairyFree == true {
            badges.append(("Dairy Free", .purple))
        }
        if sdRecipe.veryHealthy == true {
            badges.append(("Very Healthy", .orange))
        }

        return badges
    }
}

// MARK: - Supporting Components

struct RecipeMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 32)
    }
}

struct DietaryBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, spacing: spacing, containerWidth: proposal.width ?? 0).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, spacing: spacing, containerWidth: bounds.width).offsets

        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func layout(sizes: [CGSize], spacing: CGFloat, containerWidth: CGFloat) -> (offsets: [CGPoint], size: CGSize) {
        var result: [CGPoint] = []
        var currentRowY: CGFloat = 0
        var currentRowX: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for size in sizes {
            if currentRowX + size.width > containerWidth && !result.isEmpty {
                // Move to next row
                currentRowX = 0
                currentRowY += currentRowHeight + spacing
                currentRowHeight = 0
            }

            result.append(CGPoint(x: currentRowX, y: currentRowY))
            currentRowX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }

        return (
            offsets: result,
            size: CGSize(width: containerWidth, height: currentRowY + currentRowHeight)
        )
    }
}

struct ModernCardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: Color(.label).opacity(0.05), radius: 8, x: 0, y: 2)
            )
    }
}

struct ModernIngredientRow: View {
    let sdIngredient: SDIngredients

    var body: some View {
        HStack(spacing: 12) {
            // Ingredient Image
            Group {
                if let imageFilename = sdIngredient.image {
                    RobustAsyncImage(url: "https://spoonacular.com/cdn/ingredients_100x100/\(imageFilename)") { image in
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
                if let name = sdIngredient.name, !name.isEmpty {
                    Text(name.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                Text(sdIngredient.original ?? "")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct InstructionStepView: View {
    let step: SDSteps

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step Number
            Text("\(step.number ?? 0)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color(.systemBackground))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.green)
                )

            // Step Description
            Text(step.step ?? "No instruction available")
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
    }
}

#Preview {
    let sampleSDRecipe = SDRecipe(
        id: 12345,
        title: "Delicious Pasta with Fresh Tomatoes",
        sourceUrl: "https://example.com/recipe",
        spoonacularSourceUrl: "https://spoonacular.com/recipe/12345"
    )
    sampleSDRecipe.image = "https://spoonacular.com/recipeImages/12345-312x231.jpg"
    sampleSDRecipe.readyInMinutes = 30
    sampleSDRecipe.servings = 4
    sampleSDRecipe.vegetarian = true
    sampleSDRecipe.glutenFree = false
    sampleSDRecipe.dairyFree = true
    sampleSDRecipe.creditsText = "Recipe by Chef John"
    sampleSDRecipe.sourceName = "Food Network"
    sampleSDRecipe.summary = "A delicious pasta recipe with fresh tomatoes and herbs."
    sampleSDRecipe.instructions = "Cook pasta according to package directions..."

    return RecipeDetailView(sdRecipe: sampleSDRecipe)
}