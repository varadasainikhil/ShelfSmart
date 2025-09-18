//
//  SDCustomRandomRecipe.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/18/25.
//

import Foundation

struct ComplexSearchRecipeResponse : Codable {
    var results : [ComplexSearchRecipe]
    var offset : Int
    var number : Int
    var totalResults : Int
}
