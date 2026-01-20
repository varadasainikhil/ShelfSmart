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
    let userId: String  // Passed from ProfileView

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
                        // Recipe Title
                        recipeTitle

                        // Dietary & Lifestyle Badges
                        dietaryBadges

                        // Cooking Details Metrics Grid
                        cookingDetailsMetricsGrid

                        // Recipe Scores
                        recipeScoresSection

                        // Recipe Categories
                        recipeCategoriesSection

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
                .clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
        }
    }

    // Recipe Title
    private var recipeTitle: some View {
        Text(sdRecipe.title ?? "Recipe")
            .font(.largeTitle)
            .fontWeight(.bold)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
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

    // Cooking Details Metrics Grid
    private var cookingDetailsMetricsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            if sdRecipe.readyInMinutes != nil || sdRecipe.servings != nil ||
               sdRecipe.pricePerServing != nil {

                Text("Recipe Overview")
                    .font(.title2)
                    .fontWeight(.bold)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    if let readyMinutes = sdRecipe.readyInMinutes {
                        RecipeMetricCard(
                            icon: "clock.fill",
                            title: "Total Time",
                            value: "\(readyMinutes) min",
                            color: .blue
                        )
                    }

                    if let servings = sdRecipe.servings {
                        RecipeMetricCard(
                            icon: "fork.knife",
                            title: "Servings",
                            value: "\(servings)",
                            color: .green
                        )
                    }

                    if let pricePerServing = sdRecipe.pricePerServing {
                        RecipeMetricCard(
                            icon: "dollarsign.circle.fill",
                            title: "Cost Per Serving",
                            value: "$\(String(format: "%.2f", pricePerServing / 100))",
                            color: .orange
                        )
                    }

                    if let pricePerServing = sdRecipe.pricePerServing,
                       let servings = sdRecipe.servings {
                        RecipeMetricCard(
                            icon: "chart.bar.fill",
                            title: "Total Cost",
                            value: "$\(String(format: "%.2f", (pricePerServing * Double(servings)) / 100))",
                            color: .purple
                        )
                    }
                }
            }
        }
    }

    // Recipe Scores Section
    private var recipeScoresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if sdRecipe.healthScore != nil || sdRecipe.spoonacularScore != nil {

                Text("Recipe Scores")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    if let healthScore = sdRecipe.healthScore {
                        RecipeScoreBar(
                            title: "Health Score",
                            score: healthScore,
                            maxScore: 100,
                            color: .green,
                            icon: "heart.fill"
                        )
                    }

                    if let spoonacularScore = sdRecipe.spoonacularScore {
                        RecipeScoreBar(
                            title: "Spoonacular Score",
                            score: spoonacularScore,
                            maxScore: 100,
                            color: .blue,
                            icon: "star.fill"
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

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(badges, id: \.text) { badge in
                                DietaryBadge(text: badge.text, color: badge.color)
                            }
                        }
                    }
                }
            }
        }
    }

    // Recipe Categories Section
    private var recipeCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !sdRecipe.cuisines.isEmpty || !sdRecipe.diets.isEmpty {

                Text("Categories")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    if !sdRecipe.cuisines.isEmpty {
                        RecipeClassificationRow(
                            icon: "globe",
                            title: "Cuisines",
                            items: sdRecipe.cuisines,
                            color: .blue
                        )
                    }

                    if !sdRecipe.diets.isEmpty {
                        RecipeClassificationRow(
                            icon: "leaf.fill",
                            title: "Diets",
                            items: sdRecipe.diets,
                            color: .green
                        )
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
            if sdRecipe.creditsText != nil || sdRecipe.sourceName != nil ||
               sdRecipe.license != nil || sdRecipe.gaps != nil ||
               sdRecipe.sourceUrl != nil || sdRecipe.spoonacularSourceUrl != nil {
                Text("Source & Credits")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 12) {
                    if let creditsText = sdRecipe.creditsText {
                        RecipeInfoRow(icon: "person.fill", title: "Credits", value: creditsText)
                    }

                    if let sourceName = sdRecipe.sourceName {
                        RecipeInfoRow(icon: "book.closed.fill", title: "Source", value: sourceName)
                    }

                    if let license = sdRecipe.license {
                        RecipeInfoRow(icon: "doc.text.fill", title: "License", value: license)
                    }

                    if let gaps = sdRecipe.gaps {
                        RecipeInfoRow(icon: "info.circle.fill", title: "GAPS", value: gaps)
                    }

                    // Links
                    VStack(spacing: 8) {
                        if let sourceUrl = sdRecipe.sourceUrl,
                           let url = URL(string: sourceUrl) {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "link.circle.fill")
                                    Text("View Original Recipe")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue.opacity(0.1))
                                )
                            }
                        }

                        if let spoonacularUrl = sdRecipe.spoonacularSourceUrl,
                           let url = URL(string: spoonacularUrl) {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "network")
                                    Text("View on Spoonacular")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.orange.opacity(0.1))
                                )
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemBackground))
                )
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
        if sdRecipe.cheap == true {
            badges.append(("Budget Friendly", .orange))
        }
        if sdRecipe.veryPopular == true {
            badges.append(("Very Popular", .yellow))
        }
        if sdRecipe.sustainable == true {
            badges.append(("Sustainable", .teal))
        }
        if sdRecipe.lowFodmap == true {
            badges.append(("Low FODMAP", .indigo))
        }

        return badges
    }
}

// MARK: - Supporting Components

struct RecipeMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

struct RecipeScoreBar: View {
    let title: String
    let score: Double
    let maxScore: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(score))/\(Int(maxScore))")
                    .font(.headline)
                    .foregroundStyle(color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * (score / maxScore), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

struct RecipeClassificationRow: View {
    let icon: String
    let title: String
    let items: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            FlowLayout(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(color.opacity(0.15))
                        )
                        .foregroundStyle(color)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

struct RecipeInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
    }
}

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
        title: "Delicious Pasta Primavera with Fresh Vegetables",
        sourceUrl: "https://example.com/recipe",
        spoonacularSourceUrl: "https://spoonacular.com/recipe/12345"
    )

    // Basic info
    sampleSDRecipe.image = "https://spoonacular.com/recipeImages/12345-312x231.jpg"
    sampleSDRecipe.summary = "A delicious and healthy pasta primavera recipe packed with fresh spring vegetables, herbs, and a light olive oil dressing. Perfect for a quick weeknight dinner or special occasion."

    // Timing
    sampleSDRecipe.readyInMinutes = 45
    sampleSDRecipe.servings = 4

    // Scores
    sampleSDRecipe.healthScore = 87
    sampleSDRecipe.spoonacularScore = 92

    // Dietary flags
    sampleSDRecipe.vegetarian = true
    sampleSDRecipe.glutenFree = false
    sampleSDRecipe.dairyFree = true
    sampleSDRecipe.veryHealthy = true
    sampleSDRecipe.cheap = true
    sampleSDRecipe.veryPopular = true
    sampleSDRecipe.sustainable = true

    // Categories
    sampleSDRecipe.cuisines = ["Italian", "Mediterranean"]
    sampleSDRecipe.diets = ["vegetarian", "dairy free", "vegan"]

    // Pricing
    sampleSDRecipe.pricePerServing = 325

    // Credits
    sampleSDRecipe.creditsText = "Recipe by Chef John Doe"
    sampleSDRecipe.sourceName = "Food Network"
    sampleSDRecipe.license = "CC BY-SA 3.0"

    sampleSDRecipe.instructions = "1. Bring a large pot of salted water to a boil. 2. Cook pasta according to package directions. 3. In a large skillet, heat olive oil over medium heat. 4. Add vegetables and sauté until tender-crisp. 5. Toss pasta with vegetables and serve."

    return NavigationStack {
        RecipeDetailView(userId: "preview_user_id", sdRecipe: sampleSDRecipe)
    }
}