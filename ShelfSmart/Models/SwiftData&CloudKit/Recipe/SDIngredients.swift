//
//  SDIngredients.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/16/25.
//

import Foundation
import SwiftData

@Model
class SDIngredients {
    var id: Int?
    var image: String?
    var consistency: String?
    var name: String?
    var original : String?
    var originalName: String?
    var amount: Double?
    var unit: String?
    
    @Relationship(deleteRule: .cascade, inverse: \SDMeasures.SDIngredients)
    var measures: SDMeasures?

    // Relationship back to recipe
    var recipe: SDRecipe?
    
    init(from ingredients: Ingredients) {
        self.id = ingredients.id
        self.image = ingredients.image
        self.consistency = ingredients.consistency
        self.name = ingredients.name
        self.original = ingredients.original
        self.originalName = ingredients.originalName
        self.amount = ingredients.amount
        self.unit = ingredients.unit
        self.measures = SDMeasures(from: ingredients.measures)
    }
    
    // Required for SwiftData
    init(id: Int, image: String?, consistency: String, name: String, original : String, originalName: String, amount: Double, unit: String, measures: SDMeasures) {
        self.id = id
        self.image = image
        self.consistency = consistency
        self.name = name
        self.original = original
        self.originalName = originalName
        self.amount = amount
        self.unit = unit
        self.measures = measures
    }

}
