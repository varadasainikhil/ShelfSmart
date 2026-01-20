//
//  LS-Ingredient.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/7/25.
//

import Foundation
import SwiftData

/// SwiftData model for individual ingredient information
@Model
final class LSIngredient {
    /// Unique identifier for the ingredient
    /// Note: CloudKit doesn't support unique constraints, so this is just a regular attribute
    var ingredientId: String = ""

    /// Ingredient name or description
    var text: String = ""

    /// Estimated percentage of this ingredient in the product
    var percentEstimate: Double?

    /// Vegan status (e.g., "yes", "no", "maybe")
    var vegan: String?

    /// Vegetarian status (e.g., "yes", "no", "maybe")
    var vegetarian: String?

    /// Inverse relationship to the product that contains this ingredient
    var product: LSProduct?

    init(
        ingredientId: String = "",
        text: String = "",
        percentEstimate: Double? = nil,
        vegan: String? = nil,
        vegetarian: String? = nil
    ) {
        self.ingredientId = ingredientId
        self.text = text
        self.percentEstimate = percentEstimate
        self.vegan = vegan
        self.vegetarian = vegetarian
    }

    /// Convenience initializer from OFFA API model
    convenience init(from offa: OFFAIngredient) {
        self.init(
            ingredientId: offa.id,
            text: offa.text,
            percentEstimate: offa.percentEstimate,
            vegan: offa.vegan,
            vegetarian: offa.vegetarian
        )
    }
}

