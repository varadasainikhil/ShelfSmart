//
//  RecipeProtocol.swift
//  ShelfSmart
//
//  Created by Architecture Refactoring on 1/19/26.
//

import Foundation

/// Shared protocol for SDRecipe and SDOFFARecipe to eliminate code duplication
protocol RecipeProtocol: AnyObject {
    // MARK: - Required Properties
    var id: String { get }
    var spoonacularId: Int { get }
    var title: String { get set }
    var recipeDescription: String? { get set }
    var imageURL: String? { get set }
    var servings: Int? { get set }
    var readyInMinutes: Int? { get set }
    var sourceUrl: String? { get set }
    var sourceName: String? { get set }
    var isLiked: Bool { get set }
    var likedByUserId: String? { get set }
    var likedDate: Date? { get set }
    
    // MARK: - Dietary Properties
    var vegetarian: Bool? { get set }
    var vegan: Bool? { get set }
    var glutenFree: Bool? { get set }
    var dairyFree: Bool? { get set }
    var veryHealthy: Bool? { get set }
    var cheap: Bool? { get set }
    var veryPopular: Bool? { get set }
    
    // MARK: - Nutrition
    var healthScore: Double? { get set }
    var pricePerServing: Double? { get set }
}

// MARK: - Default Implementations
extension RecipeProtocol {
    
    /// Toggle the liked status of the recipe
    /// - Parameter userId: The ID of the user liking/unliking the recipe
    func likeRecipe(userId: String) {
        isLiked.toggle()
        
        if isLiked {
            likedByUserId = userId
            likedDate = Date()
        } else {
            likedByUserId = nil
            likedDate = nil
        }
    }
    
    /// Array of dietary labels for display
    var dietaryLabels: [String] {
        var labels: [String] = []
        
        if vegetarian == true { labels.append("Vegetarian") }
        if vegan == true { labels.append("Vegan") }
        if glutenFree == true { labels.append("Gluten-Free") }
        if dairyFree == true { labels.append("Dairy-Free") }
        
        return labels
    }
    
    /// Formatted cooking time string
    var formattedCookingTime: String? {
        guard let minutes = readyInMinutes else { return nil }
        
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
    
    /// Formatted servings string
    var formattedServings: String? {
        guard let servings = servings else { return nil }
        return "\(servings) serving\(servings == 1 ? "" : "s")"
    }
}
