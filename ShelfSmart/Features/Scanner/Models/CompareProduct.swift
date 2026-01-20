//
//  CompareProduct.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 1/19/26.
//

import Foundation
import SwiftUI

/// Lightweight struct for product comparison (not persisted to SwiftData)
/// Used for Compare feature - temporary in-memory storage
struct CompareProduct: Identifiable, Equatable {
    let id: String
    let barcode: String
    let title: String
    let brand: String?
    let quantity: String?
    let servingSize: String?
    let ingredientsText: String?
    
    // Nested Hierarchical Data
    let images: ProductImages
    let nutrition: ProductNutriments
    let scores: ProductScores
    let metadata: ProductMetadata
    
    // MARK: - Nested Structs
    
    struct ProductImages: Equatable {
        let front: String?
        let ingredients: String?
        let nutrition: String?
    }
    
    struct ProductNutriments: Equatable {
        let calories: Double?
        let caloriesUnit: String?
        let sugar: Double?
        let sugarUnit: String?
        let protein: Double?
        let proteinUnit: String?
        let fat: Double?
        let fatUnit: String?
        let saturatedFat: Double?
        let saturatedFatUnit: String?
        let fiber: Double?
        let salt: Double?
        let saltUnit: String?
        let sodium: Double?
        let sodiumUnit: String?
        let carbohydrates: Double?
        let carbohydratesUnit: String?
    }
    
    struct ProductScores: Equatable {
        let nutriscoreGrade: String?
        let nutriscoreScore: Int?
        let ecoscoreGrade: String?
        let ecoscoreScore: Int?
        let novaGroup: Int?
    }
    
    struct ProductMetadata: Equatable {
        let allergens: String?
        let allergensTags: [String]?
        let labelsTags: [String]?
        let positives: [String]?
        let negatives: [String]?
    }
    
    // MARK: - Computed Properties
    
    /// Nutri-Score grade display (uppercase, or "N/A")
    var nutriscoreGradeDisplay: String {
        guard let grade = scores.nutriscoreGrade,
              !grade.isEmpty,
              grade.lowercased() != "unknown",
              grade.lowercased() != "not-applicable" else {
            return "N/A"
        }
        return grade.uppercased()
    }
    
    /// Eco-Score grade display (uppercase, or "N/A")
    var ecoscoreGradeDisplay: String {
        guard let grade = scores.ecoscoreGrade,
              !grade.isEmpty,
              grade.lowercased() != "unknown",
              grade.lowercased() != "not-applicable" else {
            return "N/A"
        }
        return grade.uppercased()
            .replacingOccurrences(of: "-PLUS", with: "+")
            .replacingOccurrences(of: " PLUS", with: "+")
            .replacingOccurrences(of: "-MINUS", with: "-")
            .replacingOccurrences(of: " MINUS", with: "-")
    }
    
    /// Processing level grade (A-D based on NOVA group)
    var processingLevelGrade: String {
        guard let nova = scores.novaGroup else { return "N/A" }
        switch nova {
        case 1: return "A"
        case 2: return "B"
        case 3: return "C"
        case 4: return "D"
        default: return "N/A"
        }
    }
    
    /// Color for nutriscore grade
    var nutriscoreColor: Color {
        Self.gradeColor(for: scores.nutriscoreGrade)
    }
    
    /// Color for ecoscore grade
    var ecoscoreColor: Color {
        Self.gradeColor(for: scores.ecoscoreGrade)
    }
    
    /// Color for processing level
    var processingLevelColor: Color {
        guard let nova = scores.novaGroup else { return .gray }
        switch nova {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }
    
    /// Formatted allergens list
    var formattedAllergens: [String] {
        let allTags: [String]
        
        if let tags = metadata.allergensTags, !tags.isEmpty {
            allTags = tags
        } else if let allergenString = metadata.allergens, !allergenString.isEmpty {
            allTags = allergenString.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
        } else {
            return []
        }
        
        let formatted = allTags.map { Self.formatAllergenName($0) }
        return Array(Set(formatted)).sorted()
    }
    
    /// Formatted labels for display
    var formattedLabels: [(text: String, icon: String, color: Color)] {
        guard let labels = metadata.labelsTags, !labels.isEmpty else { return [] }
        
        let priorityLabels: [String: (text: String, icon: String, color: Color)] = [
            "organic": ("Organic", "leaf.fill", .green),
            "vegan": ("Vegan", "leaf.circle.fill", .green),
            "vegetarian": ("Vegetarian", "leaf.circle", .green),
            "no-gluten": ("Gluten-Free", "checkmark.seal.fill", .blue),
            "gluten-free": ("Gluten-Free", "checkmark.seal.fill", .blue),
            "palm-oil-free": ("Palm Oil Free", "hand.raised.fill", .orange),
            "fair-trade": ("Fair Trade", "globe.americas.fill", .blue),
            "halal": ("Halal", "moon.stars.fill", .purple),
            "kosher": ("Kosher", "star.fill", .blue)
        ]
        
        var result: [(text: String, icon: String, color: Color)] = []
        
        for label in labels {
            let cleanLabel = label.components(separatedBy: ":").last ?? label
            if let info = priorityLabels[cleanLabel] {
                result.append(info)
            }
        }
        
        return Array(result.prefix(3))
    }
    
    // MARK: - Static Helper Methods
    
    /// Returns color for grade (A-E scale)
    static func gradeColor(for grade: String?) -> Color {
        guard let grade = grade?.lowercased() else { return .gray }
        // Normalize inputs similar to display logic
        let normalized = grade
            .replacingOccurrences(of: "-plus", with: "+")
            .replacingOccurrences(of: " plus", with: "+")
        
        if normalized == "a+" {
            return Color(red: 0.1, green: 0.6, blue: 0.1) // Darker/Richer green for A+
        }
        
        // Handle standard grades (ignoring minus or other suffixes for now)
        switch normalized.prefix(1) {
        case "a": return .green
        case "b": return Color(red: 0.6, green: 0.8, blue: 0.2)
        case "c": return .yellow
        case "d": return .orange
        case "e": return .red
        default: return .gray
        }
    }
    
    /// Formats allergen names by removing language prefixes
    static func formatAllergenName(_ allergen: String) -> String {
        var cleaned = allergen
        if let colonIndex = allergen.firstIndex(of: ":") {
            cleaned = String(allergen[allergen.index(after: colonIndex)...])
        }
        cleaned = cleaned.replacingOccurrences(of: "-", with: " ")
                        .replacingOccurrences(of: "_", with: " ")
        
        let words = cleaned.split(separator: " ")
        return words.map { word -> String in
            let lowercased = word.lowercased()
            return lowercased.prefix(1).uppercased() + lowercased.dropFirst()
        }.joined(separator: " ")
    }
    
    // MARK: - Equatable
    
    static func == (lhs: CompareProduct, rhs: CompareProduct) -> Bool {
        lhs.barcode == rhs.barcode
    }
}

// MARK: - Factory Methods

extension CompareProduct {
    /// Creates a CompareProduct from an OFFAProduct (OpenFoodFacts API response)
    static func from(_ offaProduct: OFFAProduct) -> CompareProduct {
        // Extract positives and negatives from nutriscore data
        var positives: [String] = []
        var negatives: [String] = []
        
        if let nutriscoreData = offaProduct.nutriscoreData,
           let components = nutriscoreData.components {
            if let positiveComponents = components.positive {
                positives = positiveComponents.compactMap { component in
                    guard let points = component.points, points > 0 else { return nil }
                    return formatNutrientName(component.nutrientId)
                }
            }
            if let negativeComponents = components.negative {
                negatives = negativeComponents.compactMap { component in
                    guard let points = component.points, points > 0 else { return nil }
                    return formatNutrientName(component.nutrientId)
                }
            }
        }
        
        return CompareProduct(
            id: UUID().uuidString,
            barcode: offaProduct.code,
            title: offaProduct.productName ?? "Unknown Product",
            brand: offaProduct.brands,
            quantity: offaProduct.quantity,
            servingSize: offaProduct.servingSize,
            ingredientsText: offaProduct.ingredientsText,
            
            images: CompareProduct.ProductImages(
                front: offaProduct.imageFrontURL ?? offaProduct.imageURL,
                ingredients: offaProduct.imageIngredientsURL,
                nutrition: offaProduct.imageNutritionURL
            ),
            
            nutrition: CompareProduct.ProductNutriments(
                calories: offaProduct.nutriments?.energyKcal,
                caloriesUnit: offaProduct.nutriments?.energyKcalUnit,
                sugar: offaProduct.nutriments?.sugars,
                sugarUnit: offaProduct.nutriments?.sugarsUnit,
                protein: offaProduct.nutriments?.proteins,
                proteinUnit: offaProduct.nutriments?.proteinsUnit,
                fat: offaProduct.nutriments?.fat,
                fatUnit: offaProduct.nutriments?.fatUnit,
                saturatedFat: offaProduct.nutriments?.saturatedFat,
                saturatedFatUnit: offaProduct.nutriments?.saturatedFatUnit,
                fiber: offaProduct.nutriments?.fiber,
                salt: offaProduct.nutriments?.salt,
                saltUnit: offaProduct.nutriments?.saltUnit,
                sodium: offaProduct.nutriments?.sodium,
                sodiumUnit: offaProduct.nutriments?.sodiumUnit,
                carbohydrates: offaProduct.nutriments?.carbohydrates,
                carbohydratesUnit: offaProduct.nutriments?.carbohydratesUnit
            ),
            
            scores: CompareProduct.ProductScores(
                nutriscoreGrade: offaProduct.nutriscoreGrade,
                nutriscoreScore: offaProduct.nutriscoreScore,
                ecoscoreGrade: offaProduct.ecoScoreGrade,
                ecoscoreScore: offaProduct.ecoScoreScore,
                novaGroup: offaProduct.novaGroup
            ),
            
            metadata: CompareProduct.ProductMetadata(
                allergens: offaProduct.allergens,
                allergensTags: offaProduct.allergensTags,
                labelsTags: offaProduct.labelsTags,
                positives: positives.isEmpty ? nil : positives,
                negatives: negatives.isEmpty ? nil : negatives
            )
        )
    }
    
    /// Formats nutrient name from snake_case to Title Case
    private static func formatNutrientName(_ nutrientId: String) -> String {
        if nutrientId.lowercased() == "energy" {
            return "Calories"
        }
        let components = nutrientId.split(separator: "_")
        return components.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }
}

// MARK: - Mock Data

extension CompareProduct {
    static var mockProduct1: CompareProduct {
        CompareProduct(
            id: UUID().uuidString,
            barcode: "0009800800049",
            title: "Nutella & Go!",
            brand: "Nutella",
            quantity: "52g",
            servingSize: "1 UNIT(52g)",
            ingredientsText: "Sugar, Palm Oil, Hazelnuts (13%), Skimmed Milk Powder (8.7%), Fat-Reduced Cocoa (7.4%), Emulsifier: Lecithins (Soya), Vanillin",
            
            images: ProductImages(
                front: "https://images.openfoodfacts.net/images/products/000/980/080/0049/front_en.5.400.jpg",
                ingredients: nil,
                nutrition: nil
            ),
            
            nutrition: ProductNutriments(
                calories: 519.23,
                caloriesUnit: "kcal",
                sugar: 63.46,
                sugarUnit: "g",
                protein: 5.77,
                proteinUnit: "g",
                fat: 25.0,
                fatUnit: "g",
                saturatedFat: 9.62,
                saturatedFatUnit: "g",
                fiber: 2.0,
                salt: 0.4,
                saltUnit: "g",
                sodium: 0.16,
                sodiumUnit: "g",
                carbohydrates: 57.69,
                carbohydratesUnit: "g"
            ),
            
            scores: ProductScores(
                nutriscoreGrade: "e",
                nutriscoreScore: 29,
                ecoscoreGrade: "unknown",
                ecoscoreScore: nil,
                novaGroup: 4
            ),
            
            metadata: ProductMetadata(
                allergens: "en:gluten",
                allergensTags: ["en:gluten", "en:milk"],
                labelsTags: nil,
                positives: ["Fiber", "Proteins"],
                negatives: ["Saturated Fat", "Sugars", "Energy"]
            )
        )
    }
    
    static var mockProduct2: CompareProduct {
        CompareProduct(
            id: UUID().uuidString,
            barcode: "0076840100064",
            title: "Greek Yogurt",
            brand: "Chobani",
            quantity: "150g",
            servingSize: "150g",
            ingredientsText: "Cultured pasteurized nonfat milk, live and active cultures: S. Thermophilus, L. Bulgaricus, L. Acidophilus, Bifidus and L. Casei.",
            
            images: ProductImages(
                front: nil,
                ingredients: nil,
                nutrition: nil
            ),
            
            nutrition: ProductNutriments(
                calories: 97.0,
                caloriesUnit: "kcal",
                sugar: 4.0,
                sugarUnit: "g",
                protein: 17.0,
                proteinUnit: "g",
                fat: 0.7,
                fatUnit: "g",
                saturatedFat: 0.0,
                saturatedFatUnit: "g",
                fiber: 0.0,
                salt: 0.1,
                saltUnit: "g",
                sodium: 0.04,
                sodiumUnit: "g",
                carbohydrates: 6.0,
                carbohydratesUnit: "g"
            ),
            
            scores: ProductScores(
                nutriscoreGrade: "a",
                nutriscoreScore: -2,
                ecoscoreGrade: "b",
                ecoscoreScore: 65,
                novaGroup: 1
            ),
            
            metadata: ProductMetadata(
                allergens: nil,
                allergensTags: ["en:milk"],
                labelsTags: ["en:organic", "en:no-gluten"],
                positives: ["Proteins", "Fiber"],
                negatives: nil
            )
        )
    }
}
