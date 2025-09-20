//
//  Recipe.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import Foundation

struct Recipe : Codable, Identifiable {
    var id : Int
    var image : String?
    var title : String
    var readyInMinutes : Int?
    var servings : Int?
    var sourceUrl : String
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
    var extendedIngredients : [Ingredients]?
    var summary : String?
    var cuisines : [String]?
    var dishTypes : [String]?
    var diets : [String]?
    var occasions : [String]?
    var instructions : String?
    var analyzedInstructions : [AnalyzedInstructions]?
    var spoonacularScore : Double?
    var spoonacularSourceUrl : String
}
