//
//  LSProductDetailViewModel.swift
//  ShelfSmart
//
//  Created by Claude Code on 11/15/25.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Supporting Models

struct NormalizedComponent: Identifiable {
    let id: String
    let displayText: String
    let value: Double
    let normalizedPoints: Double
    let unit: String
}

@Observable
class LSProductDetailViewModel {
    // MARK: - Properties
    let product: LSProduct
    var userIntolerances: [String] = []

    // MARK: - Initialization
    init(product: LSProduct) {
        self.product = product
        Task {
            await fetchUserIntolerances()
        }
    }

    // MARK: - Fetch User Intolerances
    @MainActor
    private func fetchUserIntolerances() async {
        // Guard: Check if user is still authenticated
        guard Auth.auth().currentUser != nil else {
            print("ℹ️ [Product Detail] User not authenticated - skipping allergy fetch")
            userIntolerances = []
            return
        }

        do {
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(product.userId).getDocument()

            if let data = userDoc.data(),
               let allergies = data["allergies"] as? [String] {
                print("✅ [Product Detail] User allergies fetched: \(allergies)")
                userIntolerances = allergies
            } else {
                print("ℹ️ [Product Detail] No allergies found for user")
                userIntolerances = []
            }
        } catch {
            print("❌ [Product Detail] Error fetching user allergies: \(error.localizedDescription)")
            userIntolerances = []
        }
    }

    // MARK: - Processing Level Enum
    enum ProcessingLevel: Int {
        case minimal = 1
        case processed = 2
        case highlyProcessed = 3
        case ultraProcessed = 4

        var grade: String {
            switch self {
            case .minimal: return "A"
            case .processed: return "B"
            case .highlyProcessed: return "C"
            case .ultraProcessed: return "D"
            }
        }

        var color: Color {
            switch self {
            case .minimal: return .green
            case .processed: return .yellow
            case .highlyProcessed: return .orange
            case .ultraProcessed: return .red
            }
        }
    }

    // MARK: - Computed Properties

    /// Valid recipes filtered from the product
    var validRecipes: [SDOFFARecipe] {
        guard let recipes = product.recipes else { return [] }
        return recipes.filter { recipe in
            recipe.id != nil
        }
    }

    /// Message to display when no recipes are found
    var noRecipesMessage: String? {
        // If we have recipes, don't show a message
        guard validRecipes.isEmpty else { return nil }

        // If user has allergies/intolerances, show specific message
        if !userIntolerances.isEmpty {
            return "No recipes found for this product that match your dietary restrictions"
        }

        // If no allergies, show generic message
        return "Recipes using this product cannot be found"
    }

    /// Formatted calories string
    var caloriesString: String {
        if let energyKcal = product.nutriments?.energyKcal {
            return "\(Int(energyKcal))"
        }
        return "N/A"
    }

    /// Color for calories based on whether it appears in positives or negatives
    var caloriesColor: Color {
        // Check if energy exists in positives
        if let positives = normalizedPositives,
           positives.contains(where: { $0.id.lowercased() == "energy" }) {
            return .green
        }

        // Check if energy exists in negatives
        if let negatives = normalizedNegatives,
           negatives.contains(where: { $0.id.lowercased() == "energy" }) {
            return .red
        }

        // Default to primary (black/white based on appearance)
        return .primary
    }

    /// Formatted nutriscore grade display
    var nutriscoreGradeDisplay: String {
        guard let grade = product.nutriscoreGrade,
              !grade.isEmpty,
              grade.lowercased() != "unknown",
              grade.lowercased() != "not-applicable",
              grade.lowercased() != "not applicable" else {
            return "N/A"
        }
        return grade.uppercased()
    }

    /// Formatted ecoscore grade display
    var ecoscoreGradeDisplay: String {
        guard let grade = product.ecoScoreGrade,
              !grade.isEmpty,
              grade.lowercased() != "unknown",
              grade.lowercased() != "not-applicable",
              grade.lowercased() != "not applicable" else {
            return "N/A"
        }
        return grade.uppercased()
    }

    /// Color for nutriscore grade
    var nutriscoreColor: Color {
        Self.gradeColor(for: product.nutriscoreGrade)
    }

    /// Color for ecoscore grade
    var ecoscoreColor: Color {
        Self.gradeColor(for: product.ecoScoreGrade)
    }

    /// Processing level from NOVA group
    var processingLevel: ProcessingLevel? {
        guard let novaGroup = product.novaGroup else { return nil }
        return ProcessingLevel(rawValue: novaGroup)
    }

    /// Processing level grade string
    var processingLevelGrade: String {
        processingLevel?.grade ?? "N/A"
    }

    /// Processing level color
    var processingLevelColor: Color {
        processingLevel?.color ?? .gray
    }

    /// Normalized positive components
    var normalizedPositives: [NormalizedComponent]? {
        guard let nutriscoreData = product.nutriscoreData,
              let components = nutriscoreData.components,
              let positive = components.positive else {
            return nil
        }

        let filtered: [NormalizedComponent] = positive.compactMap { component in
            guard let points = component.points,
                  let pointsMax = component.pointsMax,
                  pointsMax > 0,
                  let value = component.value else {
                return nil
            }

            // Only include if value > 0 and points > 0
            guard value > 0 && points > 0 else { return nil }

            let normalizedPoints = (Double(points) / Double(pointsMax)) * 10.0
            let displayName = Self.formatNutrientName(component.nutrientId)

            return NormalizedComponent(
                id: component.nutrientId,
                displayText: displayName, // Don't show the score
                value: value,
                normalizedPoints: normalizedPoints,
                unit: component.unit ?? ""
            )
        }

        return filtered.isEmpty ? nil : filtered
    }

    /// Normalized negative components
    var normalizedNegatives: [NormalizedComponent]? {
        guard let nutriscoreData = product.nutriscoreData,
              let components = nutriscoreData.components,
              let negative = components.negative else {
            return nil
        }

        let filtered: [NormalizedComponent] = negative.compactMap { component in
            guard let points = component.points,
                  let pointsMax = component.pointsMax,
                  pointsMax > 0,
                  let value = component.value else {
                return nil
            }

            // Only include if value > 0 and points > 0
            guard value > 0 && points > 0 else { return nil }

            let normalizedPoints = (Double(points) / Double(pointsMax)) * 10.0
            let displayName = Self.formatNutrientName(component.nutrientId)

            return NormalizedComponent(
                id: component.nutrientId,
                displayText: displayName, // Don't show the score
                value: value,
                normalizedPoints: normalizedPoints,
                unit: component.unit ?? ""
            )
        }

        return filtered.isEmpty ? nil : filtered
    }

    /// Formatted ingredients list from product data
    var formattedIngredientsList: [String]? {
        if let ingredientsText = product.ingredientsText, !ingredientsText.isEmpty {
            // Split by comma and trim whitespace
            return ingredientsText.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        } else if let ingredients = product.ingredients, !ingredients.isEmpty {
            return ingredients.compactMap { $0.text }
        }
        return nil
    }

    /// Formatted allergens list from product data
    var formattedAllergensList: [String]? {
        var allergensList: [String]?

        if let allergens = product.allergens, !allergens.isEmpty {
            // Split by comma and format each allergen
            allergensList = allergens.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .map { Self.formatAllergenName($0) }
        } else if let allergensTags = product.allergensTags, !allergensTags.isEmpty {
            allergensList = allergensTags.map { Self.formatAllergenName($0) }
        }

        // Sort alphabetically so allergens appear in consistent order
        return allergensList?.sorted()
    }

    // MARK: - Static Helper Methods (Pure Functions)

    /// Formats allergen names by removing language prefixes and applying proper title case
    /// Example: "en:nuts" -> "Nuts", "en:tree-nuts" -> "Tree Nuts"
    static func formatAllergenName(_ allergen: String) -> String {
        // Remove language prefix (e.g., "en:", "fr:", etc.)
        var cleaned = allergen
        if let colonIndex = allergen.firstIndex(of: ":") {
            cleaned = String(allergen[allergen.index(after: colonIndex)...])
        }

        // Replace hyphens and underscores with spaces
        cleaned = cleaned.replacingOccurrences(of: "-", with: " ")
                        .replacingOccurrences(of: "_", with: " ")

        // Capitalize each word (Title Case)
        let words = cleaned.split(separator: " ")
        let titleCased = words.map { word -> String in
            let lowercased = word.lowercased()
            return lowercased.prefix(1).uppercased() + lowercased.dropFirst()
        }.joined(separator: " ")

        return titleCased
    }

    /// Formats nutrient name from snake_case to Title Case
    /// Example: "saturated_fat" -> "Saturated Fat", "energy" -> "Calories"
    static func formatNutrientName(_ nutrientId: String) -> String {
        // Special case for energy -> Calories
        if nutrientId.lowercased() == "energy" {
            return "Calories"
        }

        // Convert snake_case to Title Case
        let components = nutrientId.split(separator: "_")
        return components.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }

    /// Capitalizes the first letter of a string
    /// Example: "hello world" -> "Hello world"
    static func capitalizeFirstLetter(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    /// Returns color for grade (both nutriscore and ecoscore use same color scheme)
    private static func gradeColor(for grade: String?) -> Color {
        guard let grade = grade?.lowercased() else { return .gray }
        switch grade {
        case "a": return .green
        case "b": return Color(red: 0.6, green: 0.8, blue: 0.2)
        case "c": return .yellow
        case "d": return .orange
        case "e": return .red
        default: return .gray
        }
    }
}
