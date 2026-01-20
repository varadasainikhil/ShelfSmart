//
//  FindByIngredientsRecipe.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/18/25.
//

import Foundation

// Simplified model for recipe search by ingredients - only contains essential info
struct FindByIngredientsRecipe: Codable {
    var id: Int
    var title: String
    var image: String?
    var imageType: String?
    var usedIngredientCount: Int
    var missedIngredientCount: Int
    var likes: Int
}
