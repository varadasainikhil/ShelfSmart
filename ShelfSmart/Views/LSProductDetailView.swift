//
//  LSProductDetailView.swift
//  ShelfSmart
//
//  Created by Claude Code on 11/15/25.
//

import SwiftUI
import SwiftData

struct LSProductDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var product: LSProduct

    @State private var selectedTab: ProductTab = .nutrition
    @State private var recipeToShow: SDOFFARecipe?

    enum ProductTab: String, CaseIterable {
        case nutrition = "Nutrition"
        case ingredients = "Ingredients"
        case allergens = "Allergens"
        case details = "Details"
    }

    // Filter out any invalid or deleted recipes
    private var validRecipes: [SDOFFARecipe] {
        guard let recipes = product.recipes else { return [] }
        return recipes.filter { recipe in
            recipe.id != nil
        }
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Product Image
                productImageView
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Product Info
                productInfoSection
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                // Quick Stats (Calories & Serving Size)
                quickStatsSection
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Summary Scores
                summaryScoresSection
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Positives & Negatives
                positivesNegativesSection
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Tabs
                tabsSection
                    .padding(.top, 16)

                // Tab Content
                tabContentView
                    .padding(.horizontal, 16)

                // Recipe Suggestions
                if !validRecipes.isEmpty {
                    recipeSuggestionsSection
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }

                Spacer(minLength: 20)
            }
        }
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: product.isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(product.isLiked ? .red : .primary)
                }
            }
        }
        .sheet(item: $recipeToShow) { sdRecipe in
            NavigationStack {
                OFFARecipeDetailView(userId: product.userId, sdRecipe: sdRecipe)
            }
        }
    }

    // MARK: - Product Image View
    private var productImageView: some View {
        ZStack {
            if let imageLink = product.imageLink, !imageLink.isEmpty {
                RobustAsyncImage(url: imageLink) { image in
                    image
                        .resizable()
                        .scaledToFill()
                }
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Product Info Section
    private var productInfoSection: some View {
        VStack(spacing: 8) {
            Text(product.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if let brand = product.brand, !brand.isEmpty {
                Text("by \(brand)")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            // Tags/Badges
            tagsView
                .padding(.top, 4)
        }
    }

    // MARK: - Tags View
    private var tagsView: some View {
        HStack(spacing: 8) {
            // Organic tag (if applicable)
            if let nutriscoreData = product.nutriscoreData,
               let components = nutriscoreData.components,
               let positive = components.positive,
               positive.contains(where: { $0.nutrientId.contains("fruit") || $0.nutrientId.contains("vegetable") }) {
                TagBadge(icon: "leaf.fill", text: "Organic", color: .green)
            }

            // Vegetarian tag (based on ingredients)
            if let ingredients = product.ingredients,
               !ingredients.contains(where: { $0.text.lowercased().contains("meat") }) {
                TagBadge(icon: "leaf.circle.fill", text: "Vegetarian", color: .green)
            }

            // Gluten-Free tag (based on allergens)
            if let allergensTags = product.allergensTags,
               !allergensTags.contains(where: { $0.contains("gluten") }) {
                TagBadge(icon: "checkmark.seal.fill", text: "Gluten-Free", color: .green)
            }
        }
    }

    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        HStack(spacing: 0) {
            // Calories
            VStack(spacing: 4) {
                Text("Calories")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(caloriesText)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 44)

            // Serving Size
            VStack(spacing: 4) {
                Text("Serving Size")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(servingSizeText)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var caloriesText: String {
        if let energyKcal = product.nutriments?.energyKcal {
            return "\(Int(energyKcal))"
        }
        return "N/A"
    }

    private var servingSizeText: String {
        if let servingSize = product.servingSize, !servingSize.isEmpty {
            return servingSize
        }
        return "N/A"
    }

    // MARK: - Summary Scores Section
    private var summaryScoresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary Scores")
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            HStack(spacing: 16) {
                // Nutri-Score
                ScoreBadge(
                    grade: product.nutriscoreGrade?.uppercased() ?? "N/A",
                    title: "Nutri-Score",
                    color: nutriscoreColor
                )

                // Eco-Score
                ScoreBadge(
                    grade: product.ecoScoreGrade?.uppercased() ?? "N/A",
                    title: "Eco-Score",
                    color: ecoscoreColor
                )

                // NOVA Group
                ScoreBadge(
                    grade: product.novaGroup != nil ? "\(product.novaGroup!)" : "N/A",
                    title: "NOVA Group",
                    color: novaGroupColor
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var nutriscoreColor: Color {
        guard let grade = product.nutriscoreGrade?.lowercased() else { return .gray }
        switch grade {
        case "a": return .green
        case "b": return Color(red: 0.6, green: 0.8, blue: 0.2)
        case "c": return .yellow
        case "d": return .orange
        case "e": return .red
        default: return .gray
        }
    }

    private var ecoscoreColor: Color {
        guard let grade = product.ecoScoreGrade?.lowercased() else { return .gray }
        switch grade {
        case "a": return .green
        case "b": return Color(red: 0.6, green: 0.8, blue: 0.2)
        case "c": return .yellow
        case "d": return .orange
        case "e": return .red
        default: return .gray
        }
    }

    private var novaGroupColor: Color {
        guard let group = product.novaGroup else { return .gray }
        switch group {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }

    // MARK: - Positives & Negatives Section
    private var positivesNegativesSection: some View {
        HStack(alignment: .top, spacing: 12) {
            // Positives
            VStack(alignment: .leading, spacing: 12) {
                Text("Positives")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)

                if let positives = getNormalizedPositives(), !positives.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(positives, id: \.id) { component in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)

                                Text(component.displayText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text("No data available")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )

            // Negatives
            VStack(alignment: .leading, spacing: 12) {
                Text("Negatives")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.red)

                if let negatives = getNormalizedNegatives(), !negatives.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(negatives, id: \.id) { component in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)

                                Text(component.displayText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text("No data available")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    // MARK: - Tabs Section
    private var tabsSection: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(ProductTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Tab Content View
    @ViewBuilder
    private var tabContentView: some View {
        switch selectedTab {
        case .nutrition:
            nutritionTabView
        case .ingredients:
            ingredientsTabView
        case .allergens:
            allergensTabView
        case .details:
            detailsTabView
        }
    }

    // MARK: - Nutrition Tab
    private var nutritionTabView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let nutriments = product.nutriments {
                VStack(spacing: 8) {
                    NutritionRow(label: "Energy", value: nutriments.energyKcal, unit: nutriments.energyKcalUnit ?? "kcal")
                    NutritionRow(label: "Fat", value: nutriments.fat, unit: nutriments.fatUnit ?? "g")
                    NutritionRow(label: "Saturated Fat", value: nutriments.saturatedFat, unit: nutriments.saturatedFatUnit ?? "g")
                    NutritionRow(label: "Carbohydrates", value: nutriments.carbohydrates, unit: nutriments.carbohydratesUnit ?? "g")
                    NutritionRow(label: "Sugars", value: nutriments.sugars, unit: nutriments.sugarsUnit ?? "g")
                    NutritionRow(label: "Fiber", value: nutriments.fiber, unit: "g")
                    NutritionRow(label: "Proteins", value: nutriments.proteins, unit: nutriments.proteinsUnit ?? "g")
                    NutritionRow(label: "Salt", value: nutriments.salt, unit: nutriments.saltUnit ?? "g")
                    NutritionRow(label: "Sodium", value: nutriments.sodium, unit: nutriments.sodiumUnit ?? "g")
                }
            } else {
                Text("No nutrition information available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.top, 12)
    }

    // MARK: - Ingredients Tab
    private var ingredientsTabView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients List")
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            if let ingredientsText = product.ingredientsText, !ingredientsText.isEmpty {
                Text(ingredientsText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            } else if let ingredients = product.ingredients, !ingredients.isEmpty {
                Text(ingredients.compactMap { $0.text }.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            } else {
                Text("No ingredients information available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.top, 12)
    }

    // MARK: - Allergens Tab
    private var allergensTabView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Allergens")
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            if let allergens = product.allergens, !allergens.isEmpty {
                Text(allergens)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            } else if let allergensTags = product.allergensTags, !allergensTags.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(allergensTags, id: \.self) { allergen in
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(allergen.replacingOccurrences(of: "en:", with: "").capitalized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text("No allergen information available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.top, 12)
    }

    // MARK: - Details Tab
    private var detailsTabView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !product.barcode.isEmpty {
                DetailRow(label: "Barcode", value: product.barcode)
            }

            if let quantity = product.quantity, !quantity.isEmpty {
                DetailRow(label: "Quantity", value: quantity)
            }

            if let brand = product.brand, !brand.isEmpty {
                DetailRow(label: "Brand", value: brand)
            }

            DetailRow(label: "Date Added", value: product.dateAdded.formatted(date: .abbreviated, time: .omitted))
            DetailRow(label: "Expiration Date", value: product.expirationDate.formatted(date: .abbreviated, time: .omitted))

            if let description = product.productDescription, !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.top, 12)
    }

    // MARK: - Recipe Suggestions Section
    private var recipeSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipe Suggestions")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(validRecipes.prefix(4), id: \.id) { recipe in
                    RecipeCard(recipe: recipe) {
                        recipeToShow = recipe
                    }
                }
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Helper Functions

    private func toggleFavorite() {
        product.LikeProduct()
    }

    private func getNormalizedPositives() -> [NormalizedComponent]? {
        guard let nutriscoreData = product.nutriscoreData,
              let components = nutriscoreData.components,
              let positive = components.positive else {
            return nil
        }

        return positive.compactMap { component in
            guard let points = component.points,
                  let pointsMax = component.pointsMax,
                  pointsMax > 0,
                  let value = component.value else {
                return nil
            }

            let normalizedPoints = (Double(points) / Double(pointsMax)) * 10.0
            let displayName = formatNutrientName(component.nutrientId)

            return NormalizedComponent(
                id: component.nutrientId,
                displayText: "\(displayName): \(String(format: "%.1f", normalizedPoints))/10",
                value: value,
                normalizedPoints: normalizedPoints,
                unit: component.unit ?? ""
            )
        }
    }

    private func getNormalizedNegatives() -> [NormalizedComponent]? {
        guard let nutriscoreData = product.nutriscoreData,
              let components = nutriscoreData.components,
              let negative = components.negative else {
            return nil
        }

        return negative.compactMap { component in
            guard let points = component.points,
                  let pointsMax = component.pointsMax,
                  pointsMax > 0,
                  let value = component.value else {
                return nil
            }

            let normalizedPoints = (Double(points) / Double(pointsMax)) * 10.0
            let displayName = formatNutrientName(component.nutrientId)

            return NormalizedComponent(
                id: component.nutrientId,
                displayText: "\(displayName): \(String(format: "%.1f", normalizedPoints))/10",
                value: value,
                normalizedPoints: normalizedPoints,
                unit: component.unit ?? ""
            )
        }
    }

    private func formatNutrientName(_ nutrientId: String) -> String {
        // Convert snake_case to Title Case
        let components = nutrientId.split(separator: "_")
        return components.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }
}

// MARK: - Supporting Views

struct TagBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(color.opacity(0.15))
        )
        .foregroundStyle(color)
    }
}

struct ScoreBadge: View {
    let grade: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 64, height: 64)

                Text(grade)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct NutritionRow: View {
    let label: String
    let value: Double?
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            if let value = value {
                Text("\(String(format: "%.1f", value))\(unit)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } else {
                Text("N/A")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

struct RecipeCard: View {
    let recipe: SDOFFARecipe
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Recipe Image
                ZStack {
                    if let imageUrl = recipe.image, !imageUrl.isEmpty {
                        RobustAsyncImage(url: imageUrl) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        }
                    } else {
                        Color(.systemGray4)
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Recipe Title
                Text(recipe.title ?? "Unknown Recipe")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                // Cook Time
                if let readyInMinutes = recipe.readyInMinutes {
                    Text("\(readyInMinutes) mins")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct NormalizedComponent: Identifiable {
    let id: String
    let displayText: String
    let value: Double
    let normalizedPoints: Double
    let unit: String
}

// MARK: - Preview
#Preview {
    NavigationStack {
        if let product = createPreviewLSProduct() {
            LSProductDetailView(product: product)
        } else {
            Text("Failed to create preview product")
        }
    }
}

func createPreviewLSProduct() -> LSProduct? {
    let product = LSProduct(
        barcode: "8410128750145",
        title: "Organic Whole Milk",
        brand: "Horizon Organic",
        quantity: "1L",
        productDescription: "Fresh organic whole milk from grass-fed cows.",
        imageLink: "https://lh3.googleusercontent.com/aida-public/AB6AXuDpLAOBTI_1UsE3RYIa1v9Zmr4xjuxJ06Oq9Xpbv8BdGv-4VM0H9FcNx5vj3DTNF6ivsgulOXart8HXvJczDDQegAaSO4d_X5tEksPQRDZjB23byeim1VCjN0X6VczHwJ8bIoFr99NLk_SE-T4Y7brhY-0PqtpaecwIVdPRIsJ2xIInfEOyulGW04mM0hlXmj1v6t3H3mn6d8jh2SXMUc84BtLaNE26zNlbh1I-w3MSG_3QqFaoT2swRApgRhL6ap67YErFzWFKi9sv",
        expirationDate: Date().addingTimeInterval(86400 * 7),
        userId: "preview_user"
    )

    // Add nutriments
    let nutriments = LSNutriments(
        energyKcal: 150,
        energyKcalUnit: "kcal",
        fat: 8.0,
        fatUnit: "g",
        saturatedFat: 5.0,
        saturatedFatUnit: "g",
        carbohydrates: 12.0,
        carbohydratesUnit: "g",
        sugars: 12.0,
        sugarsUnit: "g",
        fiber: 0,
        proteins: 8.0,
        proteinsUnit: "g",
        salt: 0.13,
        saltUnit: "g"
    )
    product.nutriments = nutriments

    // Add scores
    product.nutriscoreGrade = "a"
    product.nutriscoreScore = 1
    product.ecoScoreGrade = "c"
    product.ecoScoreScore = 50
    product.novaGroup = 4
    product.servingSize = "240ml"

    return product
}
