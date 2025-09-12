//
//  GroceryProduct.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/11/25.
//

import Foundation

struct GroceryProduct : Codable{
    var id : Int
    var title : String
    var badges : [String]?
    var importantBadges : [String]?
    var spoonacularScore : Double?
    var imageLink : String?
    var moreImageLinks : [String]?
    var generatedText : String?
    var description : String?
    var upc : String
    var brand : String?
    var ingredientCount : Int?
    var credits : SpoonacularCredit
}
