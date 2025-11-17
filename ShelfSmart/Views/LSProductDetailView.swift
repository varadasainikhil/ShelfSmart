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
    @Environment(NotificationManager.self) var notificationManager

    var product: LSProduct

    @State private var viewModel: LSProductDetailViewModel
    @State private var selectedTab: ProductTab = .nutrition
    @State private var recipeToShow: SDOFFARecipe?
    @State private var showDeleteConfirmation = false
    @State private var isMarkedAsUsed = false
    @State private var isDeleting = false

    enum ProductTab: String, CaseIterable {
        case nutrition = "Nutrition"
        case ingredients = "Ingredients"
        case allergens = "Allergens"
        case details = "Details"
    }

    // MARK: - Initialization
    init(product: LSProduct) {
        self.product = product
        self._viewModel = State(initialValue: LSProductDetailViewModel(product: product))
    }

    // MARK: - Body
    var body: some View {
        Group {
            if isDeleting {
                deletingStateView
            } else {
                mainContentView
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Favorite button
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: product.isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(product.isLiked ? .red : .primary)
                    }

                    // Mark as used button
                    Button {
                        handleMarkAsUsed()
                    } label: {
                        Image(systemName: (isMarkedAsUsed || product.isUsed) ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundStyle((isMarkedAsUsed || product.isUsed) ? .green : .primary)
                    }

                    // Delete button
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete Product",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteProduct()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if product.isLiked {
                Text("This is a liked item! Are you sure you want to delete '\(product.title)'? This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete '\(product.title)'? This action cannot be undone.")
            }
        }
        .sheet(item: $recipeToShow) { sdRecipe in
            NavigationStack {
                OFFARecipeDetailView(userId: product.userId, sdRecipe: sdRecipe)
            }
        }
    }

    // MARK: - Deleting State View
    private var deletingStateView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Deleting product...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Main Content View
    private var mainContentView: some View {
        GeometryReader { geometry in
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
                    recipeSuggestionsSection
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    Spacer(minLength: 20)
                }
                .frame(width: geometry.size.width)
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
                        .scaledToFit()
                }
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .clipped()
    }

    // MARK: - Product Info Section
    private var productInfoSection: some View {
        VStack(spacing: 8) {
            Text(product.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)

            if let brand = product.brand, !brand.isEmpty {
                Text("by \(brand)")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }

            // Tags/Badges
            tagsView
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tags View
    private var tagsView: some View {
        HStack(spacing: 8) {
            // Display tags directly from Open Food Facts API via ViewModel
            ForEach(viewModel.formattedLabels, id: \.text) { labelInfo in
                TagBadge(icon: labelInfo.icon, text: labelInfo.text, color: labelInfo.color)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(spacing: 4) {
            Text("Calories")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(viewModel.caloriesString)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(viewModel.caloriesColor)

                Text("kcal per 100g")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                    grade: viewModel.nutriscoreGradeDisplay,
                    title: "Nutri-Score",
                    color: viewModel.nutriscoreColor
                )

                // Eco-Score
                ScoreBadge(
                    grade: viewModel.ecoscoreGradeDisplay,
                    title: "Eco-Score",
                    color: viewModel.ecoscoreColor
                )

                // Processing Level
                ScoreBadge(
                    grade: viewModel.processingLevelGrade,
                    title: "Processing Level",
                    color: viewModel.processingLevelColor
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

    // MARK: - Positives & Negatives Section
    private var positivesNegativesSection: some View {
        HStack(alignment: .top, spacing: 12) {
            // Positives
            VStack(alignment: .leading, spacing: 12) {
                Text("Positives")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)

                if let positives = viewModel.normalizedPositives, !positives.isEmpty {
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
                    Text("N/A")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

                if let negatives = viewModel.normalizedNegatives, !negatives.isEmpty {
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
                    Text("N/A")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .fixedSize(horizontal: false, vertical: true)
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

            if let ingredientsList = viewModel.formattedIngredientsList, !ingredientsList.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(ingredientsList.enumerated()), id: \.offset) { index, ingredient in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 24, alignment: .trailing)

                            Text(LSProductDetailViewModel.capitalizeFirstLetter(ingredient))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
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

            if let allergensList = viewModel.formattedAllergensList, !allergensList.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(allergensList.enumerated()), id: \.offset) { index, allergen in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 24, alignment: .trailing)

                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)

                                Text(allergen)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
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

            if let message = viewModel.noRecipesMessage {
                // Show informational message when no recipes are found
                noRecipesMessageView(message: message)
            } else {
                // Show recipe grid when recipes are available
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.validRecipes.prefix(4), id: \.id) { recipe in
                        RecipeCard(recipe: recipe) {
                            recipeToShow = recipe
                        }
                    }
                }
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - No Recipes Message View
    private func noRecipesMessageView(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Helper Functions

    private func toggleFavorite() {
        product.LikeProduct()
    }

    private func handleMarkAsUsed() {
        // Immediate haptic feedback for tactile response
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Immediate visual feedback using state variable (no SwiftData access)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isMarkedAsUsed = true
        }

        // Mark product as used
        Task { @MainActor in
            // Small delay for animation
            try? await Task.sleep(for: .milliseconds(300))
            dismiss()

            // Cleanup in detached task (no view updates)
            Task.detached {
                await MainActor.run {
                    // Mark product as used
                    product.isUsed = true

                    // Cancel notifications for this product
                    notificationManager.deleteScheduledNotifications(for: product)

                    // Save to model context
                    do {
                        try modelContext.save()
                    } catch {
                        print("❌ Failed to save product as used: \(error)")
                    }
                }
            }
        }
    }
    
    private func deleteProduct() {
        // Haptic feedback for tactile response
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Set deletion state immediately to prevent view from accessing deleted objects
        isDeleting = true

        // Perform deletion on the next run loop to allow UI to update
        Task {
            do {
                // Cancel notifications for this product
                notificationManager.deleteScheduledNotifications(for: product)

                // Delete the product
                modelContext.delete(product)
                try modelContext.save()

                // Dismiss after successful deletion
                dismiss()
            } catch {
                print("❌ Failed to delete product: \(error)")
                // Revert deletion state if it fails
                isDeleting = false
            }
        }
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
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
        }
    }
}

struct RecipeCard: View {
    @Environment(\.colorScheme) var colorScheme
    let recipe: SDOFFARecipe
    let onTap: () -> Void

    // Safe property accessors with defaults to prevent crashes on deleted objects
    private var isLiked: Bool { recipe.isLiked }
    private var recipeTitle: String { recipe.title ?? "Unknown Recipe" }
    private var recipeImage: String? { recipe.image }
    private var readyInMinutes: Int? { recipe.readyInMinutes }
    private var servings: Int? { recipe.servings }
    private var isVegetarian: Bool { recipe.vegetarian ?? false }
    private var isGlutenFree: Bool { recipe.glutenFree ?? false }
    private var isDairyFree: Bool { recipe.dairyFree ?? false }

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
