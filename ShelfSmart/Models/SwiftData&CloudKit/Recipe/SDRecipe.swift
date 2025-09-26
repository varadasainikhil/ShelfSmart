//
//  Recipe.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/16/25.
//

import Foundation
import SwiftData

@Model
class SDRecipe {
    var id : Int?
    var image : String?
    var title : String?
    var readyInMinutes : Int?
    var servings : Int?
    var sourceUrl : String?
    var vegetarian : Bool?
    var glutenFree : Bool?
    var dairyFree : Bool?
    var veryHealthy: Bool?
    var cheap : Bool?
    var veryPopular : Bool?
    var sustainable : Bool?
    var lowFodmap : Bool?
    var weightWatcherSmartPoints : Int?
    var gaps : String?
    var prepationMinutes : Int?
    var cookingMinute : Int?
    var healthScore : Double?
    var creditsText : String?
    var license : String?
    var sourceName : String?
    var pricePerServing : Double?
    
    // One-to-many relationship with SDIngredients
    @Relationship(deleteRule: .cascade, inverse: \SDIngredients.recipe)
    var extendedIngredients : [SDIngredients]? = [SDIngredients]()
    
    var summary : String?
    var cuisines : [String] = [String]()
    var dishTypes : [String] = [String]()
    var diets : [String] = [String]()
    var occasions : [String] = [String]()
    var instructions : String?
    
    // One-to-many relationship with SDAnalyzedInstructions
    @Relationship(deleteRule: .cascade, inverse: \SDAnalyzedInstructions.recipe)
    var analyzedInstructions : [SDAnalyzedInstructions]? = [SDAnalyzedInstructions]()
    
    var spoonacularScore : Double?
    var spoonacularSourceUrl : String?

    // Like functionality
    var isLiked : Bool = false
    var userId : String? // To track which user liked this recipe

    // Relationship back to product
    var product: Product?

    
    init(from recipe : Recipe) {
        self.id = recipe.id
        self.image = recipe.image
        self.title = recipe.title
        self.readyInMinutes = recipe.readyInMinutes
        self.servings = recipe.servings
        self.sourceUrl = recipe.sourceUrl
        self.vegetarian = recipe.vegetarian
        self.glutenFree = recipe.glutenFree
        self.dairyFree = recipe.dairyFree
        self.veryHealthy = recipe.veryHealthy
        self.cheap = recipe.cheap
        self.veryPopular = recipe.veryPopular
        self.sustainable = recipe.sustainable
        self.lowFodmap = recipe.lowFodmap
        self.weightWatcherSmartPoints = recipe.weightWatcherSmartPoints
        self.gaps = recipe.gaps
        self.prepationMinutes = recipe.prepationMinutes
        self.cookingMinute = recipe.cookingMinute
        self.healthScore = recipe.healthScore
        self.creditsText = recipe.creditsText
        self.license = recipe.license
        self.sourceName = recipe.sourceName
        self.pricePerServing = recipe.pricePerServing
        self.instructions = recipe.instructions
        self.summary = recipe.summary
        self.spoonacularScore = recipe.spoonacularScore
        self.spoonacularSourceUrl = recipe.spoonacularSourceUrl
        
        // Convert arrays to primitive types
        self.cuisines = recipe.cuisines ?? []
        self.dishTypes = recipe.dishTypes ?? []
        self.diets = recipe.diets ?? []
        self.occasions = recipe.occasions ?? []
        
        // Convert arrays of complex structs to arrays of models
        self.extendedIngredients = recipe.extendedIngredients?.map { SDIngredients(from: $0) } ?? []
        self.analyzedInstructions = recipe.analyzedInstructions?.map { SDAnalyzedInstructions(from: $0) }

        // Initialize like properties
        self.isLiked = false
        self.userId = nil
    }
    
    // Required for SwiftData - simplified initializer with required fields only
    init(id: Int, title: String, sourceUrl: String, spoonacularSourceUrl: String, extendedIngredients: [SDIngredients] = []) {
        self.id = id
        self.title = title
        self.sourceUrl = sourceUrl
        self.spoonacularSourceUrl = spoonacularSourceUrl
        self.extendedIngredients = extendedIngredients
        
        // Set optional values to nil or defaults
        self.image = nil
        self.readyInMinutes = nil
        self.servings = nil
        self.vegetarian = nil
        self.glutenFree = nil
        self.dairyFree = nil
        self.veryHealthy = nil
        self.cheap = nil
        self.veryPopular = nil
        self.sustainable = nil
        self.lowFodmap = nil
        self.weightWatcherSmartPoints = nil
        self.gaps = nil
        self.prepationMinutes = nil
        self.cookingMinute = nil
        self.healthScore = nil
        self.creditsText = nil
        self.license = nil
        self.sourceName = nil
        self.pricePerServing = nil
        self.summary = nil
        self.cuisines = []
        self.dishTypes = []
        self.diets = []
        self.occasions = []
        self.instructions = nil
        self.analyzedInstructions = nil
        self.spoonacularScore = nil
        self.isLiked = false
        self.userId = nil
    }

    // Method to toggle like status
    func likeRecipe(userId: String) {
        self.isLiked.toggle()
        self.userId = self.isLiked ? userId : nil
    }

}
